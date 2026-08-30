"""
ForestGuard AI Camera - YOLO11n Wildlife Detection Service
Real-time inference with fine-tuned YOLO11n for Tiger, Elephant, Lion, Leopard, Bear.
Supports model fallback chain, verification status, and model versioning.
"""

import logging
import threading
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Optional, Tuple

import cv2
import numpy as np

from config import (
    ANIMAL_TYPES,
    CAMERA_ID,
    CAMERA_LATITUDE,
    CAMERA_LONGITUDE,
    COCO_ANIMAL_CLASSES,
    COCO_TO_WILDLIFE,
    DEFAULT_CONFIDENCE_THRESHOLD,
    DEVICE,
    INFERENCE_IMGSZ,
    MODEL_PATH,
    STRICT_EXCLUDE_CLASSES,
    TARGET_CLASSES,
    VERIFICATION_THRESHOLD,
)

logger = logging.getLogger("forestguard.yolo")

# Tactical HUD styling per wildlife species
HUD_ANIMAL_COLORS = {
    "tiger": (0, 140, 255),     # Vibrant Amber-Orange
    "elephant": (255, 180, 0),  # Cyan-Teal
    "lion": (40, 50, 240),      # Crimson Red
    "leopard": (0, 215, 255),   # Gold Yellow
    "bear": (180, 130, 70),     # Steel Blue-Gray
}

HUD_ANIMAL_EMOJIS = {
    "tiger": "T",
    "elephant": "E",
    "lion": "L",
    "leopard": "P",
    "bear": "B",
}

VERIFICATION_COLORS = {
    "VERIFIED": (0, 200, 0),          # Green
    "NEEDS_VERIFICATION": (0, 180, 255),  # Amber
}


class Detection:
    """Represents a wildlife detection event with verification status."""

    def __init__(
        self,
        animal_type: str,
        confidence: float,
        bbox: tuple,
        verification_status: str,
        model_name: str = "unknown",
        model_version: str = "unknown",
        latitude: float = CAMERA_LATITUDE,
        longitude: float = CAMERA_LONGITUDE,
    ):
        self.id = str(uuid.uuid4())[:8]
        self.animal_type = str(animal_type).lower()
        self.confidence = float(confidence)
        self.bbox = tuple(float(v) for v in bbox)  # (x_min, y_min, x_max, y_max)
        self.verification_status = verification_status
        self.model_name = model_name
        self.model_version = model_version
        self.latitude = float(latitude)
        self.longitude = float(longitude)
        self.timestamp = datetime.now(timezone.utc).isoformat()
        self.time_str = datetime.now().strftime("%H:%M:%S")
        self.camera_id = str(CAMERA_ID)

    def to_payload(self) -> dict:
        """Convert to ForestGuard Backend API detection payload."""
        return {
            "animal_type": self.animal_type,
            "confidence": round(self.confidence, 4),
            "camera_id": self.camera_id,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "timestamp": self.timestamp,
            "bounding_box": {
                "x_min": int(self.bbox[0]),
                "y_min": int(self.bbox[1]),
                "x_max": int(self.bbox[2]),
                "y_max": int(self.bbox[3]),
            },
            "verification_status": self.verification_status,
            "model_version": self.model_version,
            "is_simulation": False,
        }

    def to_dict(self) -> dict:
        """Convert to UI incident feed entry."""
        return {
            "id": self.id,
            "animal_type": self.animal_type,
            "emoji": HUD_ANIMAL_EMOJIS.get(self.animal_type, "?"),
            "confidence": round(self.confidence, 4),
            "confidence_percent": round(self.confidence * 100, 1),
            "verification_status": self.verification_status,
            "model_name": self.model_name,
            "model_version": self.model_version,
            "camera_id": self.camera_id,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "timestamp": self.timestamp,
            "time_str": self.time_str,
            "bbox": [int(v) for v in self.bbox],
            "dispatched": True,
        }


class YOLOService:
    """
    YOLO11n wildlife detection engine with model fallback chain.
    Supports fine-tuned 5-class model and pretrained COCO fallback.
    """

    def __init__(self):
        self.model = None
        self.is_loaded = False
        self.error_message = None
        self.confidence_threshold = DEFAULT_CONFIDENCE_THRESHOLD
        self.verification_threshold = VERIFICATION_THRESHOLD
        self.inference_imgsz = INFERENCE_IMGSZ
        self.device = DEVICE
        self.detection_history: List[Detection] = []
        self.recent_alerts: List[dict] = []
        self.max_history = 100
        self._lock = threading.Lock()
        self.latest_detections: List[Detection] = []
        self.last_inference_time_ms: float = 0.0
        self.total_detections_count: int = 0
        self.total_alerts_dispatched: int = 0
        self.last_detection_timestamp: float = 0.0

        # Model metadata
        self.model_path: str = MODEL_PATH
        self.model_name: str = "unknown"
        self.model_version: str = "1.0.0"
        self.is_fine_tuned: bool = False
        self.class_names: dict = {}

    def load_model(self) -> bool:
        """Load YOLO model with fallback chain: forestguard → yolo11n → yolov8n."""
        try:
            from ultralytics import YOLO

            # Resolve model path from config
            model_path = self.model_path
            logger.info(f"Loading model from: {model_path}")
            logger.info(f"Inference device: {self.device}")

            self.model = YOLO(model_path)

            # Detect if this is our fine-tuned model or a pretrained one
            model_names = self.model.names if hasattr(self.model, 'names') else {}
            num_classes = len(model_names) if model_names else 80

            if num_classes == 5:
                # Fine-tuned ForestGuard wildlife model
                self.is_fine_tuned = True
                self.model_name = "ForestGuard-YOLO11n"
                self.class_names = model_names
                logger.info(f"Fine-tuned wildlife model loaded ({num_classes} classes): {model_names}")
            else:
                # Pretrained COCO model (80 classes) — use fallback mapping
                self.is_fine_tuned = False
                self.class_names = model_names
                # Determine model identity from filename
                p = Path(model_path)
                if "yolo11" in p.stem.lower():
                    self.model_name = "YOLO11n-Pretrained"
                elif "yolov8" in p.stem.lower():
                    self.model_name = "YOLOv8n-Pretrained"
                else:
                    self.model_name = f"YOLO-Pretrained-{p.stem}"
                logger.info(
                    f"Pretrained model loaded ({num_classes} classes). "
                    f"Using COCO→Wildlife fallback mapping for animal detection."
                )

            # Determine model version from path
            self.model_version = self._resolve_model_version(model_path)

            # Warmup inference on CPU/CUDA
            logger.info(f"Warming up model on {self.device}...")
            dummy = np.zeros((self.inference_imgsz, self.inference_imgsz, 3), dtype=np.uint8)
            self.model(dummy, verbose=False, imgsz=self.inference_imgsz, device=self.device)

            self.is_loaded = True
            self.error_message = None
            logger.info(
                f"🤖 [YOLO MODEL READY] Initialized: {self.model_name} v{self.model_version} "
                f"(imgsz: {self.inference_imgsz}, threshold: {self.confidence_threshold:.0%}, "
                f"device: {self.device}, fine-tuned: {self.is_fine_tuned})"
            )
            return True

        except Exception as e:
            self.error_message = str(e)
            self.is_loaded = False
            logger.error(f"Failed to load model: {e}")
            return False

    def _resolve_model_version(self, model_path: str) -> str:
        """Determine model version from path and config."""
        p = Path(model_path)
        if "forestguard" in p.stem.lower():
            # Try to read version from model_config.yaml
            config_path = p.parent / "model_config.yaml"
            if config_path.exists():
                try:
                    import yaml
                    with open(config_path) as f:
                        cfg = yaml.safe_load(f)
                    return cfg.get("model_version", "1.0.0")
                except Exception:
                    pass
            return "1.0.0"
        elif "yolo11" in p.stem.lower():
            return "11.0-pretrained"
        elif "yolov8" in p.stem.lower():
            return "8.0-pretrained"
        return "unknown"

    def set_threshold(self, threshold: float) -> float:
        """Dynamically update detection confidence threshold (clamped 0.05 to 0.95)."""
        with self._lock:
            self.confidence_threshold = max(0.05, min(0.95, float(threshold)))
            logger.info(f"Detection threshold tuned to: {self.confidence_threshold:.0%}")
            return self.confidence_threshold

    def get_threshold(self) -> float:
        """Get current detection confidence threshold."""
        return self.confidence_threshold

    def clear_history(self):
        """Clear all previous detection history and incident logs."""
        with self._lock:
            self.detection_history.clear()
            self.recent_alerts.clear()
            self.latest_detections.clear()
            self.total_detections_count = 0
            self.total_alerts_dispatched = 0
            self.last_detection_timestamp = 0.0
            logger.info("Detection history cleared")

    def detect(self, frame: np.ndarray) -> List[Detection]:
        """
        Run wildlife inference on a live camera frame.
        For fine-tuned model: direct 5-class detection.
        For pretrained model: COCO class filtering + wildlife mapping.
        """
        if not self.is_loaded or self.model is None or frame is None:
            return []

        start_time = time.time()
        try:
            # Run YOLO inference
            results = self.model(
                frame,
                verbose=False,
                conf=max(0.15, self.confidence_threshold * 0.5),  # Low threshold for candidate retrieval
                iou=0.45,
                imgsz=self.inference_imgsz,
                device=self.device,
            )

            detections: List[Detection] = []
            h, w = frame.shape[:2]

            for result in results:
                if result.boxes is None or len(result.boxes) == 0:
                    continue

                for box in result.boxes:
                    cls_id = int(box.cls[0])
                    raw_conf = float(box.conf[0])

                    # Route through appropriate detection path
                    if self.is_fine_tuned:
                        animal_type, confidence = self._process_fine_tuned(cls_id, raw_conf)
                    else:
                        animal_type, confidence = self._process_pretrained(cls_id, raw_conf)

                    if animal_type is None:
                        continue

                    # Apply user confidence threshold filter
                    if confidence < self.confidence_threshold:
                        continue

                    # Determine verification status
                    if confidence >= self.verification_threshold:
                        verification_status = "VERIFIED"
                    else:
                        verification_status = "NEEDS_VERIFICATION"

                    # Extract bounding box
                    bbox_xyxy = box.xyxy[0].cpu().numpy()
                    x1 = max(0, int(bbox_xyxy[0]))
                    y1 = max(0, int(bbox_xyxy[1]))
                    x2 = min(w, int(bbox_xyxy[2]))
                    y2 = min(h, int(bbox_xyxy[3]))

                    det = Detection(
                        animal_type=animal_type,
                        confidence=confidence,
                        bbox=(x1, y1, x2, y2),
                        verification_status=verification_status,
                        model_name=self.model_name,
                        model_version=self.model_version,
                        latitude=CAMERA_LATITUDE,
                        longitude=CAMERA_LONGITUDE,
                    )
                    detections.append(det)

            elapsed_ms = (time.time() - start_time) * 1000.0
            self.last_inference_time_ms = round(elapsed_ms, 1)

            with self._lock:
                self.latest_detections = detections
                if detections:
                    self.last_detection_timestamp = time.time()
                    for det in detections:
                        self._add_to_history(det)
                        self.total_detections_count += 1

            return detections

        except Exception as e:
            logger.error(f"Inference error: {e}")
            return []

    def _process_fine_tuned(self, cls_id: int, confidence: float) -> Tuple[Optional[str], float]:
        """Process detection from fine-tuned 5-class wildlife model."""
        animal_type = TARGET_CLASSES.get(cls_id)
        if animal_type and animal_type in ANIMAL_TYPES:
            return animal_type, confidence
        return None, 0.0

    def _process_pretrained(self, cls_id: int, confidence: float) -> Tuple[Optional[str], float]:
        """Process detection from pretrained COCO model with wildlife mapping."""
        # Reject non-animal classes
        if cls_id in STRICT_EXCLUDE_CLASSES:
            return None, 0.0

        # Only process known animal classes from COCO
        if cls_id not in COCO_ANIMAL_CLASSES:
            return None, 0.0

        # Map COCO class to wildlife type
        animal_type = COCO_TO_WILDLIFE.get(cls_id)
        if animal_type and animal_type in ANIMAL_TYPES:
            return animal_type, confidence

        return None, 0.0

    def get_latest_detections(self) -> List[Detection]:
        """
        Get active detections for current frame.
        Expires after 0.6 seconds so bounding boxes never linger.
        """
        with self._lock:
            if time.time() - self.last_detection_timestamp <= 0.6:
                return list(self.latest_detections)
            return []

    def _add_to_history(self, detection: Detection):
        """Add detection to rolling incident stream."""
        det_dict = detection.to_dict()
        self.detection_history.insert(0, detection)
        if len(self.detection_history) > self.max_history:
            self.detection_history = self.detection_history[:self.max_history]

        self.recent_alerts.insert(0, det_dict)
        if len(self.recent_alerts) > 25:
            self.recent_alerts = self.recent_alerts[:25]

    def record_alert_dispatched(self):
        """Increment dispatched notification counter."""
        with self._lock:
            self.total_alerts_dispatched += 1

    def get_history(self) -> list:
        """Get serialized detection history."""
        with self._lock:
            return [d.to_dict() for d in self.detection_history]

    def get_recent_alerts(self) -> list:
        """Get recent live incident stream."""
        with self._lock:
            return list(self.recent_alerts)

    def get_threat_level(self) -> dict:
        """Calculate live threat level based on active detections."""
        with self._lock:
            now = time.time()
            time_since_detection = now - self.last_detection_timestamp

            if time_since_detection <= 1.0 and self.latest_detections:
                highest_conf = max(d.confidence for d in self.latest_detections)
                if highest_conf >= 0.70:
                    return {"level": "CRITICAL", "color": "#ef4444", "active": True}
                return {"level": "ELEVATED", "color": "#f59e0b", "active": True}
            elif time_since_detection <= 8.0 and self.recent_alerts:
                return {"level": "CAUTION", "color": "#eab308", "active": False}
            else:
                return {"level": "SECURE", "color": "#10b981", "active": False}

    def draw_detections(self, frame: np.ndarray, detections: Optional[List[Detection]] = None) -> np.ndarray:
        """
        Render tactical HUD overlay with verification status badges.
        Includes AI disclaimer text.
        """
        if frame is None:
            return frame

        annotated = frame.copy()
        h, w = annotated.shape[:2]

        if detections is None:
            detections = self.get_latest_detections()

        # Always render AI disclaimer at bottom-right
        disclaimer = "AI may be inaccurate. Ranger verification is authoritative."
        cv2.putText(annotated, disclaimer, (8, h - 6),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.32, (120, 140, 160), 1)

        if not detections:
            return annotated

        for det in detections:
            color = HUD_ANIMAL_COLORS.get(det.animal_type, (0, 255, 0))
            verify_color = VERIFICATION_COLORS.get(det.verification_status, (200, 200, 200))
            x1, y1, x2, y2 = [int(v) for v in det.bbox]
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w - 1, x2), min(h - 1, y2)
            box_w = x2 - x1
            box_h = y2 - y1

            # 1. Main tactical bounding box
            cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)

            # 2. Glowing corner brackets
            bracket_len = max(10, min(22, box_w // 4, box_h // 4))
            cv2.line(annotated, (x1, y1), (x1 + bracket_len, y1), (255, 255, 255), 3)
            cv2.line(annotated, (x1, y1), (x1, y1 + bracket_len), (255, 255, 255), 3)
            cv2.line(annotated, (x2, y1), (x2 - bracket_len, y1), (255, 255, 255), 3)
            cv2.line(annotated, (x2, y1), (x2, y1 + bracket_len), (255, 255, 255), 3)
            cv2.line(annotated, (x1, y2), (x1 + bracket_len, y2), (255, 255, 255), 3)
            cv2.line(annotated, (x1, y2), (x1, y2 - bracket_len), (255, 255, 255), 3)
            cv2.line(annotated, (x2, y2), (x2 - bracket_len, y2), (255, 255, 255), 3)
            cv2.line(annotated, (x2, y2), (x2, y2 - bracket_len), (255, 255, 255), 3)

            # 3. Center target reticle crosshair
            cx, cy = x1 + box_w // 2, y1 + box_h // 2
            cv2.circle(annotated, (cx, cy), 3, color, -1)
            cv2.line(annotated, (cx - 6, cy), (cx + 6, cy), (255, 255, 255), 1)
            cv2.line(annotated, (cx, cy - 6), (cx, cy + 6), (255, 255, 255), 1)

            # 4. Tactical label pill with animal name + confidence + verification badge
            letter = HUD_ANIMAL_EMOJIS.get(det.animal_type, "?")
            status_tag = "V" if det.verification_status == "VERIFIED" else "?"
            label = f"[{letter}] {det.animal_type.upper()} {det.confidence:.0%} [{status_tag}]"
            (text_w, text_h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.50, 2)

            label_y = y1 - 8 if y1 - 8 > text_h + 8 else y2 + text_h + 12
            cv2.rectangle(
                annotated,
                (x1, label_y - text_h - 6),
                (x1 + text_w + 12, label_y + baseline + 2),
                color,
                -1,
            )
            cv2.putText(
                annotated,
                label,
                (x1 + 6, label_y - 2),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.50,
                (0, 0, 0),
                2,
            )

            # 5. Verification status badge (small colored dot)
            badge_x = x1 + text_w + 16
            badge_y = label_y - text_h // 2
            cv2.circle(annotated, (badge_x, badge_y), 5, verify_color, -1)

        return annotated

    def get_model_info(self) -> dict:
        """Get model metadata for API endpoint."""
        return {
            "model_name": self.model_name,
            "model_version": self.model_version,
            "model_path": self.model_path,
            "is_fine_tuned": self.is_fine_tuned,
            "device": self.device,
            "num_classes": len(TARGET_CLASSES) if self.is_fine_tuned else len(COCO_ANIMAL_CLASSES),
            "class_map": TARGET_CLASSES if self.is_fine_tuned else COCO_TO_WILDLIFE,
            "target_species": ANIMAL_TYPES,
        }

    def get_status(self) -> dict:
        """Get YOLO service telemetry summary."""
        return {
            "model_loaded": self.is_loaded,
            "model_name": self.model_name,
            "model_version": self.model_version,
            "is_fine_tuned": self.is_fine_tuned,
            "device": self.device,
            "threshold": round(self.confidence_threshold, 2),
            "threshold_percent": round(self.confidence_threshold * 100, 1),
            "verification_threshold": round(self.verification_threshold, 2),
            "inference_imgsz": self.inference_imgsz,
            "last_inference_ms": self.last_inference_time_ms,
            "total_detections": self.total_detections_count,
            "total_alerts_dispatched": self.total_alerts_dispatched,
            "threat_level": self.get_threat_level(),
            "error": self.error_message,
        }
