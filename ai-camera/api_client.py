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
        self._client = httpx.Client(timeout=10.0)
        self._retry_count = 0
        self._max_retries = 3

    def check_connection(self) -> bool:
        """Check if the backend is reachable."""
        try:
            response = self._client.get(f"{self.backend_url}/health")
            if response.status_code == 200:
                self.is_connected = True
                self.last_error = None
                self._retry_count = 0
                return True
        except Exception as e:
            self.last_error = str(e)

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
                    f"Detection sent: {payload['animal_type']} "
                    f"(conf: {payload['confidence']:.0%}, "
                    f"status: {v_status}, model: {model_ver})"
                )
                return data
            else:
                self.last_error = f"HTTP {response.status_code}: {response.text[:200]}"
                logger.warning(f"Detection rejected: {self.last_error}")
                return None

        except httpx.TimeoutException:
            self.last_error = "Request timed out"
            self.is_connected = False
            logger.error("Detection send timeout")
            return None

        except httpx.ConnectError:
            self.last_error = "Cannot connect to backend"
            self.is_connected = False
            logger.error("Backend connection failed")
            return None

        except Exception as e:
            self.last_error = str(e)
            self.is_connected = False
            logger.error(f"Detection send error: {e}")
            return None

    def send_heartbeat(self) -> bool:
        """Send camera heartbeat to backend."""
        try:
            response = self._client.post(HEARTBEAT_ENDPOINT, timeout=5.0)
            if response.status_code == 200:
                self.is_connected = True
                return True
        except Exception as e:
            self.last_error = str(e)
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
