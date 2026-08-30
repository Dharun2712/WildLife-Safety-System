"""
ForestGuard - Cameras Router
Camera status monitoring endpoints.
"""

from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database
from app.websocket.manager import ws_manager

router = APIRouter(prefix="/api/cameras", tags=["Cameras"])


class CameraResponse(BaseModel):
    id: str
    camera_id: str
    name: str
    latitude: float
    longitude: float
    status: str
    type: Optional[str] = None
    description: Optional[str] = None
    last_heartbeat: Optional[str] = None
    forest_id: Optional[str] = None
    is_active: bool = True


def _format_camera(c: dict) -> CameraResponse:
    return CameraResponse(
        id=str(c["_id"]),
        camera_id=c["camera_id"],
        name=c.get("name", ""),
        latitude=c.get("latitude", 0),
        longitude=c.get("longitude", 0),
        status=c.get("status", "unknown"),
        type=c.get("type"),
        description=c.get("description"),
        last_heartbeat=c.get("last_heartbeat", "").isoformat() if c.get("last_heartbeat") else None,
        forest_id=str(c.get("forest_id")) if c.get("forest_id") else None,
        is_active=c.get("is_active", True),
    )


@router.get("", response_model=list[CameraResponse])
async def list_cameras(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List all cameras."""
    cursor = db.cameras.find({"is_active": True})
    cameras = await cursor.to_list(length=50)
    return [_format_camera(c) for c in cameras]


@router.get("/{camera_id}", response_model=CameraResponse)
async def get_camera(
    camera_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get camera details by camera_id."""
    camera = await db.cameras.find_one({"camera_id": camera_id})
    if not camera:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found")
    return _format_camera(camera)


@router.get("/{camera_id}/status")
async def get_camera_status(
    camera_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Get detailed camera status (Ranger/Admin only)."""
    camera = await db.cameras.find_one({"camera_id": camera_id})
    if not camera:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found")
    
    # Get recent detections from this camera
    recent = await db.wildlife_detections.find(
        {"camera_id": camera_id}
    ).sort("created_at", -1).limit(10).to_list(length=10)
    
    return {
        "camera": _format_camera(camera),
        "recent_detections": [
            {
                "id": str(d["_id"]),
                "animal_type": d["animal_type"],
                "confidence": d["confidence"],
                "timestamp": d.get("timestamp"),
                "is_simulation": d.get("is_simulation", False),
            }
            for d in recent
        ],
        "total_detections": await db.wildlife_detections.count_documents({"camera_id": camera_id}),
    }


@router.post("/{camera_id}/heartbeat")
async def camera_heartbeat(
    camera_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Camera sends heartbeat to indicate it's online."""
    now = datetime.now(timezone.utc)
    result = await db.cameras.update_one(
        {"camera_id": camera_id},
        {"$set": {"status": "online", "last_heartbeat": now, "updated_at": now}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Camera not found")
    
    # Broadcast camera status to rangers
    await ws_manager.broadcast_to_rangers("camera_status_changed", {
        "camera_id": camera_id,
        "status": "online",
        "last_heartbeat": now.isoformat(),
    })
    
    return {"status": "ok", "timestamp": now.isoformat()}
