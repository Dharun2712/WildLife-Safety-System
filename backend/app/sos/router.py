"""
ForestGuard - SOS Router
Tourist SOS requests sent to rangers as modal popups.
Status flow: unverified → verified → acknowledged (solved)
"""

from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database
from app.websocket.manager import ws_manager

router = APIRouter(prefix="/api/sos", tags=["SOS"])


class SOSCreateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    message: Optional[str] = None


class SOSResponse(BaseModel):
    id: str
    tourist_id: str
    tourist_name: str
    latitude: float
    longitude: float
    message: Optional[str] = None
    status: str
    verified_by: Optional[str] = None
    acknowledged_by: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


def _format_sos(s: dict) -> SOSResponse:
    return SOSResponse(
        id=str(s["_id"]),
        tourist_id=str(s.get("tourist_id", "")),
        tourist_name=s.get("tourist_name", "Tourist"),
        latitude=s["latitude"],
        longitude=s["longitude"],
        message=s.get("message"),
        status=s["status"],
        verified_by=s.get("verified_by"),
        acknowledged_by=s.get("acknowledged_by"),
        created_at=s.get("created_at", "").isoformat() if s.get("created_at") else None,
        updated_at=s.get("updated_at", "").isoformat() if s.get("updated_at") else None,
    )


@router.post("", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
async def create_sos(
    request: SOSCreateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Tourist creates an SOS request — broadcasted to all rangers as a modal popup."""
    now = datetime.now(timezone.utc)

    sos_doc = {
        "tourist_id": ObjectId(current_user["user_id"]),
        "tourist_name": current_user.get("full_name", current_user.get("username", "Tourist")),
        "latitude": request.latitude,
        "longitude": request.longitude,
        "message": request.message,
        "status": "unverified",
        "created_at": now,
        "updated_at": now,
    }

    result = await db.sos_requests.insert_one(sos_doc)
    sos_doc["_id"] = result.inserted_id

    # Broadcast SOS request to all rangers as modal popup
    await ws_manager.broadcast_to_rangers("sos_request", {
        "sos_id": str(result.inserted_id),
        "tourist_id": str(current_user["user_id"]),
        "tourist_name": sos_doc["tourist_name"],
        "latitude": request.latitude,
        "longitude": request.longitude,
        "message": request.message,
        "status": "unverified",
    })

    return _format_sos(sos_doc)


@router.get("", response_model=list[SOSResponse])
async def list_sos(
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List SOS requests."""
    query = {}
    if status_filter:
        query["status"] = status_filter

    # Tourists only see their own SOS requests
    if current_user.get("role") == "tourist":
        query["tourist_id"] = ObjectId(current_user["user_id"])

    cursor = db.sos_requests.find(query).sort("created_at", -1).limit(limit)
    requests = await cursor.to_list(length=limit)
    return [_format_sos(s) for s in requests]


@router.patch("/{sos_id}/verify", response_model=SOSResponse)
async def verify_sos(
    sos_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger verifies an SOS request."""
    try:
        oid = ObjectId(sos_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid SOS ID")

    sos = await db.sos_requests.find_one({"_id": oid})
    if not sos:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS request not found")

    if sos["status"] != "unverified":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Cannot verify SOS with status '{sos['status']}'")

    now = datetime.now(timezone.utc)
    await db.sos_requests.update_one(
        {"_id": oid},
        {"$set": {
            "status": "verified",
            "verified_by": current_user["username"],
            "verified_at": now,
            "updated_at": now,
        }}
    )

    # Notify the tourist that their SOS has been verified
    payload = {
        "sos_id": sos_id,
        "tourist_name": sos.get("tourist_name", "Tourist"),
        "verified_by": current_user["username"],
        "status": "verified",
        "message": f"Ranger {current_user['username']} has verified your SOS request and is responding.",
    }
    await ws_manager.broadcast_to_tourists("sos_verified", payload)
    await ws_manager.broadcast_to_rangers("sos_verified", payload)

    updated = await db.sos_requests.find_one({"_id": oid})
    return _format_sos(updated)


@router.patch("/{sos_id}/acknowledge", response_model=SOSResponse)
async def acknowledge_sos(
    sos_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger acknowledges/resolves an SOS request — moves to Solved Cases."""
    try:
        oid = ObjectId(sos_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid SOS ID")

    sos = await db.sos_requests.find_one({"_id": oid})
    if not sos:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="SOS request not found")

    if sos["status"] not in ["unverified", "verified"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Cannot acknowledge SOS with status '{sos['status']}'")

    now = datetime.now(timezone.utc)
    await db.sos_requests.update_one(
        {"_id": oid},
        {"$set": {
            "status": "acknowledged",
            "acknowledged_by": current_user["username"],
            "acknowledged_at": now,
            "updated_at": now,
        }}
    )

    # Notify the tourist that their SOS has been resolved
    payload = {
        "sos_id": sos_id,
        "tourist_name": sos.get("tourist_name", "Tourist"),
        "acknowledged_by": current_user["username"],
        "status": "acknowledged",
        "message": f"Ranger {current_user['username']} has acknowledged and resolved your SOS request. You are safe.",
    }
    await ws_manager.broadcast_to_tourists("sos_acknowledged", payload)
    await ws_manager.broadcast_to_rangers("sos_acknowledged", payload)

    updated = await db.sos_requests.find_one({"_id": oid})
    return _format_sos(updated)
