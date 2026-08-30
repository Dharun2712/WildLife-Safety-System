"""
ForestGuard - WebSocket Connection Manager
Manages real-time WebSocket connections for tourists and rangers.
Supports broadcasting events by role and proximity.
"""

import json
import logging
from datetime import datetime, timezone
from typing import Dict, List, Optional, Set

from fastapi import WebSocket

logger = logging.getLogger("forestguard.websocket")


class ConnectionManager:
    """
    Manages WebSocket connections with role-based broadcasting.
    
    Events:
    - wildlife_detected: New detection → Rangers
    - danger_zone_created: New danger zone → Rangers + affected Tourists
    - danger_zone_updated: Animal movement → Rangers + affected Tourists
    - alert_acknowledged: Ranger acknowledges → Rangers + Tourists
    - tourist_warning: Tourists near zone → specific Tourist
    - alert_closed: Alert closed → Rangers + all affected Tourists
    - alert_closed_notification: Closure broadcast → Tourists
    - camera_status_changed: Camera status → Rangers
    """

    def __init__(self):
        # Connections organized by role
        self._ranger_connections: Dict[str, WebSocket] = {}  # user_id -> websocket
        self._tourist_connections: Dict[str, WebSocket] = {}  # user_id -> websocket
        # Track tourist locations for proximity-based notifications
        self._tourist_locations: Dict[str, dict] = {}  # user_id -> {lat, lng}

    @property
    def active_rangers(self) -> int:
        return len(self._ranger_connections)

    @property
    def active_tourists(self) -> int:
        return len(self._tourist_connections)

    async def connect(self, websocket: WebSocket, user_id: str, role: str):
        """Accept a new WebSocket connection and register by role."""
        await websocket.accept()
        if role == "ranger":
            self._ranger_connections[user_id] = websocket
            logger.info(f"Ranger {user_id} connected. Total rangers: {self.active_rangers}")
        else:
            self._tourist_connections[user_id] = websocket
            logger.info(f"Tourist {user_id} connected. Total tourists: {self.active_tourists}")

    def disconnect(self, user_id: str, role: str):
        """Remove a WebSocket connection."""
        if role == "ranger":
            self._ranger_connections.pop(user_id, None)
            logger.info(f"Ranger {user_id} disconnected. Total rangers: {self.active_rangers}")
        else:
            self._tourist_connections.pop(user_id, None)
            self._tourist_locations.pop(user_id, None)
            logger.info(f"Tourist {user_id} disconnected. Total tourists: {self.active_tourists}")

    def update_tourist_location(self, user_id: str, latitude: float, longitude: float):
        """Update cached tourist location for proximity calculations."""
        self._tourist_locations[user_id] = {
            "latitude": latitude,
            "longitude": longitude,
            "updated_at": datetime.now(timezone.utc).isoformat()
        }

    async def _send_personal(self, websocket: WebSocket, event: str, data: dict):
        """Send a message to a specific WebSocket connection."""
        try:
            message = {
                "event": event,
                "data": data,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }
            await websocket.send_json(message)
        except Exception as e:
            logger.error(f"Failed to send WebSocket message: {e}")

    async def broadcast_to_rangers(self, event: str, data: dict):
        """Broadcast an event to all connected rangers."""
        disconnected = []
        for user_id, ws in self._ranger_connections.items():
            try:
                await self._send_personal(ws, event, data)
            except Exception:
                disconnected.append(user_id)

        for uid in disconnected:
            self._ranger_connections.pop(uid, None)

    async def broadcast_to_tourists(self, event: str, data: dict, tourist_ids: Optional[List[str]] = None):
        """
        Broadcast an event to tourists.
        If tourist_ids is provided, only send to those specific tourists.
        If None, broadcast to all connected tourists.
        """
        target_connections = {}
        if tourist_ids:
            target_connections = {
                uid: ws for uid, ws in self._tourist_connections.items()
                if uid in tourist_ids
            }
        else:
            target_connections = self._tourist_connections.copy()

        disconnected = []
        for user_id, ws in target_connections.items():
            try:
                await self._send_personal(ws, event, data)
            except Exception:
                disconnected.append(user_id)

        for uid in disconnected:
            self._tourist_connections.pop(uid, None)

    async def send_to_user(self, user_id: str, event: str, data: dict):
        """Send an event to a specific user (tourist or ranger)."""
        ws = self._ranger_connections.get(user_id) or self._tourist_connections.get(user_id)
        if ws:
            await self._send_personal(ws, event, data)

    async def broadcast_all(self, event: str, data: dict):
        """Broadcast to all connected clients."""
        await self.broadcast_to_rangers(event, data)
        await self.broadcast_to_tourists(event, data)

    def get_connected_tourist_ids(self) -> List[str]:
        """Get all connected tourist user IDs."""
        return list(self._tourist_connections.keys())

    def get_tourist_locations(self) -> Dict[str, dict]:
        """Get cached tourist locations for proximity calculations."""
        return self._tourist_locations.copy()


# Singleton connection manager
ws_manager = ConnectionManager()
