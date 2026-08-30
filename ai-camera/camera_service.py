"""
ForestGuard AI Camera - Enterprise Camera Service
High-FPS DirectShow OpenCV webcam capture with hardware MJPG compression,
zero-latency frame buffering, and buttery smooth 30+ FPS streaming.
"""

import logging
import platform
import threading
import time
from typing import Optional

import cv2
import numpy as np

logger = logging.getLogger("forestguard.camera")


class CameraService:
    """Manages high-reliability webcam capture using OpenCV DirectShow."""

    def __init__(self, camera_index: int = 0):
        self.camera_index = camera_index
        self.cap: Optional[cv2.VideoCapture] = None
        self.is_running = False
        self.current_frame: Optional[np.ndarray] = None
        self.fps = 0.0
        self._lock = threading.Lock()
        self._frame_count = 0
        self._fps_start = time.time()
        self.status = "offline"
        self.error_message: Optional[str] = None
        self._capture_thread: Optional[threading.Thread] = None

    def _open_capture_device(self) -> Optional[cv2.VideoCapture]:
        """Open camera device using DirectShow on Windows with hardware MJPG compression."""
        is_windows = platform.system() == "Windows"
        backend = cv2.CAP_DSHOW if is_windows else cv2.CAP_ANY

        # Try camera indices 0, 1, 2
        for idx in [self.camera_index, 0, 1, 2]:
            try:
                cap = cv2.VideoCapture(idx, backend)
                if cap.isOpened():
                    # Set MJPG compression for high FPS and low USB bandwidth latency
                    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))
                    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                    cap.set(cv2.CAP_PROP_FPS, 30)
                    try:
                        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
                    except Exception:
                        pass

                    ret, test_frame = cap.read()
                    if ret and test_frame is not None:
                        logger.info(f"✅ Camera online at index {idx} ({test_frame.shape[1]}x{test_frame.shape[0]} @ 30 FPS)")
                        self.camera_index = idx
                        return cap
                    cap.release()
            except Exception as e:
                logger.debug(f"Failed to open index {idx}: {e}")

        return None

    def start(self) -> bool:
        """Initialize and start camera capture thread."""
        if self.is_running and self.cap is not None and self.cap.isOpened():
            return True

        self.stop()

        try:
            self.cap = self._open_capture_device()
            if self.cap is None or not self.cap.isOpened():
                self.status = "error"
                self.error_message = f"Webcam not accessible at index {self.camera_index}"
                logger.error(self.error_message)
                return False

            self.is_running = True
            self.status = "online"
            self.error_message = None
            self._fps_start = time.time()
            self._frame_count = 0

            # Dedicated high-speed frame capture loop
            self._capture_thread = threading.Thread(target=self._capture_loop, daemon=True)
            self._capture_thread.start()

            logger.info(f"🟢 High-FPS camera surveillance running on index {self.camera_index}")
            return True

        except Exception as e:
            self.status = "error"
            self.error_message = str(e)
            logger.error(f"Camera start exception: {e}")
            return False

    def _capture_loop(self):
        """High-throughput capture loop."""
        while self.is_running:
            try:
                if self.cap is None or not self.cap.isOpened():
                    break

                ret, frame = self.cap.read()
                if ret and frame is not None:
                    with self._lock:
                        self.current_frame = frame
                    self._frame_count += 1

                    elapsed = time.time() - self._fps_start
                    if elapsed >= 1.0:
                        self.fps = self._frame_count / elapsed
                        self._frame_count = 0
                        self._fps_start = time.time()
                else:
                    time.sleep(0.01)

            except Exception as e:
                logger.error(f"Frame grab error: {e}")
                time.sleep(0.01)

    def get_frame(self) -> Optional[np.ndarray]:
        """Get the latest camera frame (thread-safe copy)."""
        if not self.is_running:
            return None
        with self._lock:
            if self.current_frame is not None:
                return self.current_frame.copy()
            return None

    def get_jpeg_frame(self, quality: int = 85) -> bytes:
        """Get the latest frame as JPEG bytes."""
        frame = self.get_frame()
        if frame is None:
            placeholder = np.zeros((480, 640, 3), dtype=np.uint8)
            placeholder[:] = (18, 14, 12)
            cv2.putText(placeholder, "Camera Standby", (220, 240),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.8, (140, 150, 165), 2)
            _, buffer = cv2.imencode(".jpg", placeholder, [cv2.IMWRITE_JPEG_QUALITY, quality])
            return buffer.tobytes()

        _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, quality])
        return buffer.tobytes()

    def stop(self):
        """Stop camera capture and release webcam hardware."""
        self.is_running = False
        time.sleep(0.05)
        with self._lock:
            self.current_frame = None
        if self.cap:
            try:
                self.cap.release()
            except Exception as e:
                logger.warning(f"Error releasing camera: {e}")
            self.cap = None
        self.fps = 0.0
        self.status = "offline"
        logger.info("Camera stopped & hardware handle released")

    def get_status(self) -> dict:
        """Get camera hardware telemetry."""
        return {
            "status": self.status,
            "fps": round(self.fps, 1),
            "error": self.error_message,
            "camera_index": self.camera_index,
        }
