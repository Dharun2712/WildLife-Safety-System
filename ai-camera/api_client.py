"""
ForestGuard AI Camera - Backend API Client
HTTP client for sending detections with verification status to the ForestGuard backend.
"""

import logging
import time
from typing import Optional

import httpx

from config import BACKEND_URL, DETECTION_ENDPOINT, HEARTBEAT_ENDPOINT

logger = logging.getLogger("forestguard.api_client")


class APIClient:
    """HTTP client for communicating with the ForestGuard backend."""

    def __init__(self):
        self.backend_url = BACKEND_URL
        self.is_connected = False
        self.last_error = None
        self.last_success_time = None
        self._client = httpx.Client(timeout=10.0, follow_redirects=True)
        self._retry_count = 0
        self._max_retries = 3

    def check_connection(self) -> bool:
        """Check if the backend is reachable."""
        try:
            response = self._client.get(f"{self.backend_url}/health")
            if response.status_code == 200:
                if not self.is_connected:
                    logger.info(f"✅ [BACKEND CONNECTED] Render FastAPI reachable at {self.backend_url}")
                self.is_connected = True
                self.last_error = None
                self._retry_count = 0
                return True
        except Exception as e:
            self.last_error = str(e)

        if self.is_connected:
            logger.warning(f"⚠️ [BACKEND UNAVAILABLE - RETRYING] Connection lost to {self.backend_url}: {self.last_error}")
        else:
            logger.warning(f"⚠️ [BACKEND UNAVAILABLE - RETRYING] Cannot reach {self.backend_url}")
        self.is_connected = False
        return False

    def send_detection(self, payload: dict) -> Optional[dict]:
        """
        Send a wildlife detection to the backend.
        Payload includes verification_status and model_version.
        Returns response data on success, None on failure.
        """
        try:
            response = self._client.post(
                DETECTION_ENDPOINT,
                json=payload,
                timeout=15.0,
            )

            if response.status_code == 201:
                self.is_connected = True
                self.last_error = None
                self.last_success_time = time.time()
                self._retry_count = 0
                data = response.json()
                v_status = payload.get('verification_status', 'unknown')
                model_ver = payload.get('model_version', 'unknown')
                logger.info(
                    f"✅ [DETECTION SENT TO BACKEND] {payload['animal_type'].upper()} "
                    f"(conf: {payload['confidence']:.0%}, status: {v_status}, model: {model_ver})"
                )
                return data
            else:
                self.last_error = f"HTTP {response.status_code}: {response.text[:200]}"
                logger.warning(f"⚠️ [DETECTION REJECTED] {self.last_error}")
                return None

        except httpx.TimeoutException:
            self.last_error = "Request timed out"
            self.is_connected = False
            logger.error("⚠️ [BACKEND UNAVAILABLE - RETRYING] Detection send timeout")
            return None

        except httpx.ConnectError:
            self.last_error = "Cannot connect to backend"
            self.is_connected = False
            logger.error("⚠️ [BACKEND UNAVAILABLE - RETRYING] Connection failed")
            return None

        except Exception as e:
            self.last_error = str(e)
            self.is_connected = False
            logger.error(f"⚠️ [BACKEND UNAVAILABLE - RETRYING] Error: {e}")
            return None

    def send_heartbeat(self) -> bool:
        """Send camera heartbeat to backend."""
        try:
            response = self._client.post(HEARTBEAT_ENDPOINT, timeout=5.0)
            if response.status_code == 200:
                if not self.is_connected:
                    logger.info(f"✅ [BACKEND CONNECTED] Heartbeat acknowledged by Render")
                self.is_connected = True
                logger.info("💓 [HEARTBEAT SENT] Camera C-01 online heartbeat acknowledged by Render backend")
                return True
            else:
                logger.warning(f"⚠️ [HEARTBEAT FAILED] HTTP {response.status_code}")
        except Exception as e:
            self.last_error = str(e)
            if self.is_connected:
                logger.warning(f"⚠️ [BACKEND UNAVAILABLE - RETRYING] Heartbeat failed: {e}")
            self.is_connected = False

        return False

    def get_status(self) -> dict:
        return {
            "connected": self.is_connected,
            "backend_url": self.backend_url,
            "last_error": self.last_error,
            "last_success": self.last_success_time,
        }

    def close(self):
        """Close the HTTP client."""
        self._client.close()
