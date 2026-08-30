"""
ForestGuard - WebSocket Router
WebSocket endpoint with JWT authentication.
"""

import logging

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect

from app.auth.service import decode_token
from app.database.connection import get_database
from app.websocket.manager import ws_manager

logger = logging.getLogger("forestguard.websocket")

router = APIRouter(tags=["WebSocket"])


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, token: str = Query(...)):
    """
    WebSocket endpoint with JWT authentication.
    
    Connect: ws://host:port/ws?token=<jwt_token>
    
    Incoming messages from clients:
    - {"type": "location_update", "latitude": float, "longitude": float}
    - {"type": "ping"}
    
    Outgoing events:
    - wildlife_detected, danger_zone_created, danger_zone_updated
    - alert_acknowledged, tourist_warning, alert_closed
    - camera_status_changed
    """
    # Validate JWT token
    payload = decode_token(token)
    if payload is None or payload.get("type") != "access":
        await websocket.close(code=4001, reason="Invalid or expired token")
        return

    username = payload.get("sub")
    role = payload.get("role", "tourist")

    # Look up user
    db = await get_database()
    user = await db.users.find_one({"username": username})
    if not user:
        await websocket.close(code=4001, reason="User not found")
        return

    user_id = str(user["_id"])

    # Connect
    await ws_manager.connect(websocket, user_id, role)

    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type", "")

            if msg_type == "location_update":
                # Tourist sends location update
                lat = data.get("latitude")
                lng = data.get("longitude")
                if lat is not None and lng is not None:
                    ws_manager.update_tourist_location(user_id, lat, lng)

            elif msg_type == "ping":
                await websocket.send_json({"event": "pong", "timestamp": ""})

    except WebSocketDisconnect:
        ws_manager.disconnect(user_id, role)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        ws_manager.disconnect(user_id, role)
