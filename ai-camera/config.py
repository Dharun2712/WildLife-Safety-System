"""
ForestGuard AI Camera - Enterprise Configuration
All settings from environment variables with production defaults.
Supports YOLO11n fine-tuned wildlife model with graceful fallback chain.
"""

import os
from pathlib import Path

import torch
from dotenv import load_dotenv

load_dotenv()

# ─── Camera Identity & Geolocation ──────────────────────────────────
CAMERA_ID = os.getenv("CAMERA_ID", "C-01")
CAMERA_NAME = os.getenv("CAMERA_NAME", "Zone A - Mudumalai Perimeter Sentinel")
CAMERA_INDEX = int(os.getenv("CAMERA_INDEX", "0"))
CAMERA_LATITUDE = float(os.getenv("CAMERA_LATITUDE", "11.5690"))
CAMERA_LONGITUDE = float(os.getenv("CAMERA_LONGITUDE", "76.6320"))
FOREST_ZONE = os.getenv("FOREST_ZONE", "Zone A")

# ─── Backend Service ────────────────────────────────────────────────
BACKEND_URL = os.getenv("CAMERA_BACKEND_URL", "https://wildlife-safety-system.onrender.com").rstrip("/")
DETECTION_ENDPOINT = f"{BACKEND_URL}/api/wildlife/detections"
HEARTBEAT_ENDPOINT = f"{BACKEND_URL}/api/cameras/{CAMERA_ID}/heartbeat"

# ─── Model Management ──────────────────────────────────────────────
# Model path fallback chain: custom fine-tuned → yolo11n → yolov8n
MODELS_DIR = Path(__file__).parent / "models"
MODELS_DIR.mkdir(exist_ok=True)

_MODEL_SEARCH_ORDER = [
    os.getenv("YOLO_MODEL_PATH", ""),           # User-specified override
    str(MODELS_DIR / "forestguard_wildlife.pt"), # Fine-tuned wildlife model
    str(MODELS_DIR / "yolo11n.pt"),              # YOLO11n pretrained
    "yolo11n.pt",                                # Auto-download YOLO11n
    str(Path(__file__).parent / "yolov8n.pt"),   # Local YOLOv8n fallback
    "yolov8n.pt",                                # Auto-download YOLOv8n
]

def resolve_model_path() -> str:
    """Find the first available model file from the fallback chain."""
    for candidate in _MODEL_SEARCH_ORDER:
        if not candidate:
            continue
        p = Path(candidate)
        if p.exists() and p.is_file():
            return str(p)
    # None found locally — return yolo11n.pt for auto-download attempt
    return "yolov8n.pt"

MODEL_PATH = os.getenv("YOLO_MODEL_PATH", "") or resolve_model_path()
MODEL_VERSION = os.getenv("MODEL_VERSION", "auto")  # Populated at runtime

# ─── Device Auto-Detection ──────────────────────────────────────────
def _detect_device() -> str:
    """Auto-detect CUDA or fall back to CPU."""
    override = os.getenv("YOLO_DEVICE", "").strip().lower()
    if override in ("cpu", "cuda", "cuda:0"):
        return override
    return "cuda" if torch.cuda.is_available() else "cpu"

DEVICE = _detect_device()

# ─── Detection & Inference ──────────────────────────────────────────
# Default confidence threshold raised to 0.55 to prevent false positives in webcam/indoor environments
DEFAULT_CONFIDENCE_THRESHOLD = float(os.getenv("CONFIDENCE_THRESHOLD", "0.55"))
VERIFICATION_THRESHOLD = float(os.getenv("VERIFICATION_THRESHOLD", "0.75"))
INFERENCE_IMGSZ = int(os.getenv("INFERENCE_IMGSZ", "640"))
DETECTION_INTERVAL = float(os.getenv("DETECTION_INTERVAL", "0.20"))

# ─── Target Wildlife Classes (Fine-Tuned Model) ────────────────────
# When using the fine-tuned forestguard_wildlife.pt, these are the direct class indices
TARGET_CLASSES = {
    0: "tiger",
    1: "elephant",
    2: "lion",
    3: "leopard",
    4: "bear",
}
ANIMAL_TYPES = ["tiger", "elephant", "lion", "leopard", "bear"]

# Strict species name normalization dictionary
NORMALIZE_ANIMAL_MAP = {
    "tiger": "tiger",
    "bengal tiger": "tiger",
    "elephant": "elephant",
    "asian elephant": "elephant",
    "lion": "lion",
    "african lion": "lion",
    "leopard": "leopard",
    "indian leopard": "leopard",
    "bear": "bear",
    "sloth bear": "bear",
    "sloth": "bear",
}

def normalize_animal_name(name: str) -> str:
    """Normalize any animal label to one of the 5 canonical names: tiger, elephant, lion, leopard, bear."""
    n = str(name).lower().strip()
    return NORMALIZE_ANIMAL_MAP.get(n, n)

# ─── COCO Fallback Mapping (Pretrained Model) ──────────────────────
# Used ONLY when running generic yolov8n.pt / yolo11n.pt pretrained on COCO.
# ONLY direct wild animal matches (elephant=20, bear=21) are mapped to avoid false alarms
COCO_ANIMAL_CLASSES = {
    20: "elephant", # → direct match
    21: "bear",     # → direct match
}

# COCO class → wildlife type mapping for pretrained fallback
COCO_TO_WILDLIFE = {
    20: "elephant",  # elephant → elephant
    21: "bear",      # bear → bear
}

# Strictly reject human (0), domestic pets, and non-wildlife COCO classes
STRICT_EXCLUDE_CLASSES = set(range(0, 20)) | set(range(22, 80))

# ─── Monitoring UI Server ──────────────────────────────────────────
MONITOR_HOST = os.getenv("MONITOR_HOST", "0.0.0.0")
MONITOR_PORT = int(os.getenv("MONITOR_PORT", "8501"))

# ─── Heartbeat ──────────────────────────────────────────────────────
HEARTBEAT_INTERVAL = 20

# ─── ONNX Export ────────────────────────────────────────────────────
ONNX_EXPORT_PATH = os.getenv("ONNX_EXPORT_PATH", str(MODELS_DIR / "forestguard_wildlife.onnx"))
