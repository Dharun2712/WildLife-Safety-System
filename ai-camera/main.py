"""
ForestGuard AI Camera - Enterprise Sentinel Main Service
High-throughput continuous wildlife detection with YOLO11n,
verification status workflow, and instant alert dispatching.
"""

import asyncio
import json
import logging
import os
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import cv2
import numpy as np
from fastapi import FastAPI, Query, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, StreamingResponse, JSONResponse, FileResponse
from pydantic import BaseModel

from api_client import APIClient
from camera_service import CameraService
from config import (
    ANIMAL_TYPES,
    CAMERA_ID,
    CAMERA_LATITUDE,
    CAMERA_LONGITUDE,
    CAMERA_NAME,
    DETECTION_INTERVAL,
    DEVICE,
    FOREST_ZONE,
    HEARTBEAT_INTERVAL,
    MONITOR_HOST,
    MONITOR_PORT,
    MODEL_PATH,
)
from yolo_service import YOLOService

# Configure high-visibility logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("forestguard.sentinel")

# Initialize services
camera = CameraService()
yolo = YOLOService()
api_client = APIClient()

# FastAPI application for Sentinel Command Center
app = FastAPI(title="ForestGuard AI Sentinel Command Center")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Web directory
WEB_DIR = Path(__file__).parent / "web"


# --- Schemas ---

class ThresholdRequest(BaseModel):
    threshold: float


# --- Web UI Routes ---

@app.get("/", response_class=HTMLResponse)
async def command_center_ui():
    """Serve the Command Center Web UI."""
    html_path = WEB_DIR / "index.html"
    if html_path.exists():
        return html_path.read_text(encoding="utf-8")
    return HTMLResponse("<h1>ForestGuard Sentinel Command Center</h1><p>Web UI assets not found.</p>")


@app.get("/style.css")
async def serve_css():
    css_path = WEB_DIR / "style.css"
    if css_path.exists():
        return Response(content=css_path.read_text(encoding="utf-8"), media_type="text/css")
    return Response(content="", media_type="text/css")


@app.get("/app.js")
async def serve_js():
    js_path = WEB_DIR / "app.js"
    if js_path.exists():
        return Response(content=js_path.read_text(encoding="utf-8"), media_type="application/javascript")
    return Response(content="", media_type="application/javascript")


# --- Video Streaming Deck ---

def generate_video_frames():
    """
    Decoupled ultra-smooth MJPEG video stream generator.
    Renders camera frames with real-time tactical HUD overlays at full hardware FPS.
    """
    while True:
        frame = camera.get_frame()
        if frame is not None:
            # Draw tactical HUD overlay with detections and AI disclaimer
            annotated = yolo.draw_detections(frame) if yolo.is_loaded else frame
            h, w = annotated.shape[:2]

            # Top HUD Telemetry Ribbon
            fps_val = camera.fps
            thresh_val = yolo.get_threshold()
            infer_ms = yolo.last_inference_time_ms
            threat = yolo.get_threat_level()

            hud_bar = (
                f"SENTINEL {CAMERA_ID} | {FOREST_ZONE} | FPS: {fps_val:.1f} | "
                f"INFER: {infer_ms:.0f}ms | THRESH: {thresh_val:.0%} | "
                f"MODEL: {yolo.model_name}"
            )
            cv2.putText(annotated, hud_bar, (14, 26), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 255, 0), 1)

            # Bottom Metadata Bar
            time_now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            meta_txt = (
                f"LAT: {CAMERA_LATITUDE:.4f} LNG: {CAMERA_LONGITUDE:.4f} | "
                f"{time_now} | DEV: {DEVICE.upper()} | STATUS: {threat['level']}"
            )
            cv2.putText(annotated, meta_txt, (14, h - 22), cv2.FONT_HERSHEY_SIMPLEX, 0.38, (200, 210, 220), 1)

            _, buffer = cv2.imencode(".jpg", annotated, [cv2.IMWRITE_JPEG_QUALITY, 85])
            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" + buffer.tobytes() + b"\r\n"
            )
            time.sleep(0.01)
        else:
            # Tactical Standby Screen when Camera is Offline
            placeholder = np.zeros((480, 640, 3), dtype=np.uint8)
            placeholder[:] = (18, 14, 12)

            # Tactical grid lines
            for y in range(40, 480, 60):
                cv2.line(placeholder, (0, y), (640, y), (28, 22, 20), 1)
            for x in range(40, 640, 60):
                cv2.line(placeholder, (x, 0), (x, 480), (28, 22, 20), 1)

            cv2.putText(placeholder, "CAMERA FEED OFFLINE", (170, 220),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.85, (140, 155, 175), 2)
            cv2.putText(placeholder, "Click 'START SURVEILLANCE' to initialize edge detection", (105, 260),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (85, 100, 120), 1)
            _, buffer = cv2.imencode(".jpg", placeholder, [cv2.IMWRITE_JPEG_QUALITY, 80])
            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" + buffer.tobytes() + b"\r\n"
            )
            time.sleep(0.05)


@app.get("/video_feed")
async def video_feed():
    """MJPEG streaming endpoint."""
    return StreamingResponse(
        generate_video_frames(),
        media_type="multipart/x-mixed-replace; boundary=frame",
    )


# --- REST API Endpoints ---

@app.get("/api/status")
async def get_status():
    """Get complete Sentinel system telemetry status."""
    return {
        "camera_id": CAMERA_ID,
        "camera_name": CAMERA_NAME,
        "forest_zone": FOREST_ZONE,
        "latitude": CAMERA_LATITUDE,
        "longitude": CAMERA_LONGITUDE,
        "camera": camera.get_status(),
        "yolo": yolo.get_status(),
        "backend": api_client.get_status(),
        "threat_level": yolo.get_threat_level(),
        "recent_alerts": yolo.get_recent_alerts()[:15],
    }


@app.get("/api/model/info")
async def get_model_info():
    """Get AI model metadata including name, version, device, and class map."""
    return yolo.get_model_info()


@app.get("/api/alerts/recent")
async def get_recent_alerts():
    """Get continuous stream of recent wildlife detection events."""
    return {
        "alerts": yolo.get_recent_alerts(),
        "threat_level": yolo.get_threat_level(),
        "total_dispatched": yolo.total_alerts_dispatched,
    }


@app.post("/api/alerts/clear_history")
async def clear_history():
    """Clear all previous detection logs."""
    yolo.clear_history()
    return {"success": True, "message": "Incident history cleared"}


@app.get("/api/config/threshold")
async def get_threshold():
    """Get active detection confidence threshold."""
    return {
        "threshold": yolo.get_threshold(),
        "percentage": round(yolo.get_threshold() * 100, 1),
    }


@app.post("/api/config/threshold")
async def update_threshold(req: ThresholdRequest):
    """Dynamically tune detection confidence threshold."""
    new_val = yolo.set_threshold(req.threshold)
    return {
        "success": True,
        "threshold": new_val,
        "percentage": round(new_val * 100, 1),
        "message": f"Threshold tuned to {new_val:.0%}",
    }


@app.post("/api/camera/start")
async def start_camera():
    """Start camera feed."""
    success = camera.start()
    return {
        "success": success,
        "status": camera.get_status(),
        "message": "Surveillance initialized" if success else f"Failed: {camera.error_message}",
    }


@app.post("/api/camera/stop")
async def stop_camera():
    """Stop camera feed and release hardware."""
    camera.stop()
    return {
        "success": True,
        "status": camera.get_status(),
        "message": "Surveillance paused & hardware released",
    }


@app.post("/api/camera/toggle")
async def toggle_camera():
    """Toggle camera streaming state."""
    if camera.is_running:
        camera.stop()
        return {
            "success": True,
            "running": False,
            "status": camera.get_status(),
            "message": "Camera stopped",
        }
    else:
        success = camera.start()
        return {
            "success": success,
            "running": success,
            "status": camera.get_status(),
            "message": "Camera streaming" if success else f"Failed: {camera.error_message}",
        }


@app.get("/api/camera/snapshot")
async def get_snapshot():
    """Capture a snapshot of the current view with tactical HUD overlay."""
    frame = camera.get_frame()
    if frame is None:
        return JSONResponse(status_code=400, content={"error": "Camera is offline"})

    annotated = yolo.draw_detections(frame)
    _, buffer = cv2.imencode(".jpg", annotated, [cv2.IMWRITE_JPEG_QUALITY, 95])
    return Response(content=buffer.tobytes(), media_type="image/jpeg")


@app.get("/api/detections/history")
async def get_detection_history():
    """Get full detection event log."""
    return {"detections": yolo.get_history()}


# --- Continuous Autonomous Detection Worker ---

def heartbeat_loop():
    """Periodic camera heartbeat dispatch."""
    while True:
        api_client.send_heartbeat()
        time.sleep(HEARTBEAT_INTERVAL)


def auto_detect_loop():
    """
    Continuous unblocked AI detection & dispatch worker.
    Processes live webcam frames, identifies wildlife threats,
    and immediately dispatches notifications to tourists and rangers
    without waiting for acknowledgment.

    VERIFIED detections → full danger zone + alert (rangers + tourists)
    NEEDS_VERIFICATION detections → alert rangers only for review
    """
    last_sent_timestamps = {}

    while True:
        try:
            if camera.is_running and yolo.is_loaded:
                frame = camera.get_frame()
                if frame is not None:
                    detections = yolo.detect(frame)

                    for det in detections:
                        now = time.time()
                        last_sent = last_sent_timestamps.get(det.animal_type, 0.0)

                        # Send notification immediately with 0.8s debounce per animal type
                        if now - last_sent >= 0.8:
                            last_sent_timestamps[det.animal_type] = now
                            payload = det.to_payload()

                            # Dispatch to backend
                            res = api_client.send_detection(payload)
                            if res:
                                yolo.record_alert_dispatched()
                                status_tag = det.verification_status
                                logger.info(
                                    f"[DETECTION] {det.animal_type.upper()} "
                                    f"({det.confidence:.1%} conf) [{status_tag}] "
                                    f"-> Dispatched to backend"
                                )
        except Exception as e:
            logger.error(f"Error in continuous detection loop: {e}")

        time.sleep(DETECTION_INTERVAL)


# --- Lifecycle Events ---

@app.on_event("startup")
async def startup():
    """Initialize Sentinel services on launch."""
    logger.info("=" * 60)
    logger.info(f"ForestGuard Sentinel Command Center - Camera {CAMERA_ID}")
    logger.info(f"  Name: {CAMERA_NAME} ({FOREST_ZONE})")
    logger.info(f"  Coordinates: ({CAMERA_LATITUDE}, {CAMERA_LONGITUDE})")
    logger.info(f"  Monitor Web Console: http://localhost:{MONITOR_PORT}")
    logger.info(f"  Model Path: {MODEL_PATH}")
    logger.info(f"  Inference Device: {DEVICE}")
    logger.info(f"  Inference Size: {yolo.inference_imgsz}x{yolo.inference_imgsz}")
    logger.info(f"  Confidence Threshold: {yolo.get_threshold():.0%}")
    logger.info(f"  Verification Threshold: {yolo.verification_threshold:.0%}")
    logger.info("=" * 60)

    # Load YOLO model
    logger.info("Initializing YOLO wildlife detection model...")
    yolo.load_model()

    # Clear previous history on fresh launch
    yolo.clear_history()

    # Check backend connectivity
    logger.info("Verifying ForestGuard backend connection...")
    if api_client.check_connection():
        logger.info("Backend connected and ready to receive real-time alerts")
    else:
        logger.warning("Backend not reachable - events will be logged locally")

    # Launch background continuous workers
    threading.Thread(target=heartbeat_loop, daemon=True).start()
    threading.Thread(target=auto_detect_loop, daemon=True).start()

    logger.info(f"Sentinel AI Node READY | Model: {yolo.model_name} v{yolo.model_version} | Device: {DEVICE}")


@app.on_event("shutdown")
async def shutdown():
    camera.stop()
    api_client.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host=MONITOR_HOST, port=MONITOR_PORT)
