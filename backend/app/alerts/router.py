"""
ForestGuard - Alerts Router
Alert state machine with ranger actions: acknowledge, verify, reject, close, update location.
"""

import math
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

router = APIRouter(prefix="/api/alerts", tags=["Alerts"])


class AlertResponse(BaseModel):
    id: str
    detection_id: Optional[str] = None
    danger_zone_id: Optional[str] = None
    animal_type: str
    confidence: float
    latitude: float
    longitude: float
    zone_code: Optional[str] = None
    forest_id: Optional[str] = None
    status: str
    is_simulation: bool = False
    ranger_acknowledged: bool = False
    acknowledged_by: Optional[str] = None
    verified_by: Optional[str] = None
    closed_by: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class LocationUpdateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)


def _format_alert(a: dict) -> AlertResponse:
    return AlertResponse(
        id=str(a["_id"]),
        detection_id=str(a.get("detection_id")) if a.get("detection_id") else None,
        danger_zone_id=str(a.get("danger_zone_id")) if a.get("danger_zone_id") else None,
        animal_type=a["animal_type"],
        confidence=a["confidence"],
        latitude=a["latitude"],
        longitude=a["longitude"],
        zone_code=a.get("zone_code"),
        forest_id=str(a.get("forest_id")) if a.get("forest_id") else None,
        status=a["status"],
        is_simulation=a.get("is_simulation", False),
        ranger_acknowledged=a.get("ranger_acknowledged", False),
        acknowledged_by=a.get("acknowledged_by"),
        verified_by=a.get("verified_by"),
        closed_by=a.get("closed_by"),
        created_at=a.get("created_at", "").isoformat() if a.get("created_at") else None,
        updated_at=a.get("updated_at", "").isoformat() if a.get("updated_at") else None,
    )


@router.get("", response_model=list[AlertResponse])
async def list_alerts(
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List alerts with optional status filter."""
    query = {}
    if status_filter:
        query["status"] = status_filter
    
    # Tourists only see active alerts
    if current_user.get("role") == "tourist":
        query["status"] = {"$in": ["active", "acknowledged", "monitoring"]}
    
    cursor = db.alerts.find(query).sort("created_at", -1).limit(limit)
    alerts = await cursor.to_list(length=limit)
    return [_format_alert(a) for a in alerts]


@router.get("/{alert_id}", response_model=AlertResponse)
async def get_alert(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get alert details."""
    try:
        alert = await db.alerts.find_one({"_id": ObjectId(alert_id)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    return _format_alert(alert)


@router.patch("/{alert_id}/acknowledge", response_model=AlertResponse)
async def acknowledge_alert(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger acknowledges an alert."""
    try:
        oid = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    alert = await db.alerts.find_one({"_id": oid})
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] not in ["active", "needs_verification"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Cannot acknowledge alert with status '{alert['status']}'")
    
    now = datetime.now(timezone.utc)
    new_status = "acknowledged" if alert["status"] == "active" else alert["status"]
    
    await db.alerts.update_one(
        {"_id": oid},
        {"$set": {
            "status": new_status,
            "ranger_acknowledged": True,
            "acknowledged_by": current_user["username"],
            "acknowledged_at": now,
            "updated_at": now,
        }}
    )
    
    # Update danger zone
    if alert.get("danger_zone_id"):
        await db.danger_zones.update_one(
            {"_id": alert["danger_zone_id"]},
            {"$set": {"ranger_acknowledged": True, "updated_at": now}}
        )
    
    # Broadcast
    await ws_manager.broadcast_to_rangers("alert_acknowledged", {
        "alert_id": alert_id,
        "acknowledged_by": current_user["username"],
    })
    
    updated = await db.alerts.find_one({"_id": oid})
    return _format_alert(updated)


@router.patch("/{alert_id}/verify", response_model=AlertResponse)
async def verify_alert(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger verifies a low-confidence detection — activates danger zone."""
    try:
        oid = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    alert = await db.alerts.find_one({"_id": oid})
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] != "needs_verification":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Alert does not need verification")
    
    now = datetime.now(timezone.utc)
    
    # Get safety config for radius
    safety_config = await db.safety_configurations.find_one({"animal_type": alert["animal_type"]})
    danger_radius = safety_config.get("danger_radius_meters", 2000) if safety_config else 2000
    
    # Create danger zone now that ranger verified
    dz_doc = {
        "animal_type": alert["animal_type"],
        "center_latitude": alert["latitude"],
        "center_longitude": alert["longitude"],
        "center": {"type": "Point", "coordinates": [alert["longitude"], alert["latitude"]]},
        "radius_meters": danger_radius,
        "detection_id": alert.get("detection_id"),
        "latest_detection_id": alert.get("detection_id"),
        "forest_id": alert.get("forest_id"),
        "zone_code": alert.get("zone_code"),
        "status": "active",
        "is_simulation": alert.get("is_simulation", False),
        "ranger_acknowledged": True,
        "created_at": now,
        "updated_at": now,
    }
    dz_result = await db.danger_zones.insert_one(dz_doc)
    
    # Update alert
    await db.alerts.update_one(
        {"_id": oid},
        {"$set": {
            "status": "active",
            "danger_zone_id": dz_result.inserted_id,
            "verified_by": current_user["username"],
            "verified_at": now,
            "ranger_acknowledged": True,
            "updated_at": now,
        }}
    )
    
    # Broadcast new danger zone
    await ws_manager.broadcast_to_rangers("danger_zone_created", {
        "danger_zone_id": str(dz_result.inserted_id),
        "animal_type": alert["animal_type"],
        "latitude": alert["latitude"],
        "longitude": alert["longitude"],
        "radius_meters": danger_radius,
        "zone_code": alert.get("zone_code"),
        "verified_by": current_user["username"],
    })
    
    # Notify affected tourists
    await ws_manager.broadcast_to_tourists("tourist_warning", {
        "alert_id": alert_id,
        "danger_zone_id": str(dz_result.inserted_id),
        "animal_type": alert["animal_type"],
        "latitude": alert["latitude"],
        "longitude": alert["longitude"],
        "radius_meters": danger_radius,
        "message": (
            "A wildlife detection has been reported near your current area. "
            "Please remain at a safe location and follow official ranger instructions."
        ),
    })
    
    updated = await db.alerts.find_one({"_id": oid})
    return _format_alert(updated)


@router.patch("/{alert_id}/reject", response_model=AlertResponse)
async def reject_alert(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger rejects a low-confidence detection."""
    try:
        oid = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    alert = await db.alerts.find_one({"_id": oid})
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] != "needs_verification":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Alert does not need verification")
    
    now = datetime.now(timezone.utc)
    await db.alerts.update_one(
        {"_id": oid},
        {"$set": {
            "status": "rejected",
            "rejected_by": current_user["username"],
            "rejected_at": now,
            "updated_at": now,
        }}
    )
    
    # Update detection status
    if alert.get("detection_id"):
        await db.wildlife_detections.update_one(
            {"_id": alert["detection_id"]},
            {"$set": {"status": "rejected", "updated_at": now}}
        )
    
    updated = await db.alerts.find_one({"_id": oid})
    return _format_alert(updated)


@router.patch("/{alert_id}/close", response_model=AlertResponse)
async def close_alert(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger closes an alert — closes danger zone and notifies tourists."""
    try:
        oid = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    alert = await db.alerts.find_one({"_id": oid})
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] in ["closed", "rejected"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Alert already closed or rejected")
    
    now = datetime.now(timezone.utc)
    
    # Close alert
    await db.alerts.update_one(
        {"_id": oid},
        {"$set": {
            "status": "closed",
            "closed_by": current_user["username"],
            "closed_at": now,
            "updated_at": now,
        }}
    )
    
    # Close associated danger zone
    if alert.get("danger_zone_id"):
        await db.danger_zones.update_one(
            {"_id": alert["danger_zone_id"]},
            {"$set": {"status": "closed", "updated_at": now}}
        )
    
    # Create closure notifications for all tourists
    zone_code = alert.get("zone_code", "the area")
    closure_notif = {
        "type": "alert_closed",
        "title": "SAFETY ALERT CLOSED",
        "message": (
            f"The wildlife alert in Zone {zone_code} has been closed by the forest ranger. "
            "Please continue following official forest instructions."
        ),
        "alert_id": oid,
        "animal_type": alert["animal_type"],
        "is_read": False,
        "created_at": now,
    }
    
    # Get all connected tourist IDs and create individual notifications
    tourist_ids = ws_manager.get_connected_tourist_ids()
    for tid in tourist_ids:
        notif = {**closure_notif, "user_id": ObjectId(tid)}
        await db.notifications.insert_one(notif)
    
    # Broadcast closure to all
    await ws_manager.broadcast_to_rangers("alert_closed", {
        "alert_id": alert_id,
        "animal_type": alert["animal_type"],
        "closed_by": current_user["username"],
        "zone_code": zone_code,
    })
    
    await ws_manager.broadcast_to_tourists("alert_closed_notification", {
        "alert_id": alert_id,
        "animal_type": alert["animal_type"],
        "zone_code": zone_code,
        "message": (
            f"The wildlife alert in Zone {zone_code} has been closed by the forest ranger. "
            "Please continue following official forest instructions."
        ),
    })
    
    updated = await db.alerts.find_one({"_id": oid})
    return _format_alert(updated)


@router.patch("/{alert_id}/location", response_model=AlertResponse)
async def update_alert_location(
    alert_id: str,
    request: LocationUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Ranger updates animal location — moves danger zone center in real time."""
    try:
        oid = ObjectId(alert_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    alert = await db.alerts.find_one({"_id": oid})
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] in ["closed", "rejected"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot update closed/rejected alert")
    
    now = datetime.now(timezone.utc)
    
    # Store movement history
    movement_doc = {
        "detection_id": alert.get("detection_id"),
        "animal_type": alert["animal_type"],
        "from_latitude": alert["latitude"],
        "from_longitude": alert["longitude"],
        "to_latitude": request.latitude,
        "to_longitude": request.longitude,
        "location": {"type": "Point", "coordinates": [request.longitude, request.latitude]},
        "distance_meters": 0,  # Will calculate
        "forest_id": alert.get("forest_id"),
        "source": "ranger_update",
        "updated_by": current_user["username"],
        "timestamp": now,
    }
    
    R = 6371000
    import math
    lat1, lat2 = math.radians(alert["latitude"]), math.radians(request.latitude)
    dlat = math.radians(request.latitude - alert["latitude"])
    dlng = math.radians(request.longitude - alert["longitude"])
    a = math.sin(dlat/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dlng/2)**2
    movement_doc["distance_meters"] = R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    await db.wildlife_movements.insert_one(movement_doc)
    
    # Update alert location
    await db.alerts.update_one(
        {"_id": oid},
        {"$set": {
            "latitude": request.latitude,
            "longitude": request.longitude,
            "status": "monitoring",
            "updated_at": now,
        }}
    )
    
    # Update danger zone center
    if alert.get("danger_zone_id"):
        await db.danger_zones.update_one(
            {"_id": alert["danger_zone_id"]},
            {"$set": {
                "center_latitude": request.latitude,
                "center_longitude": request.longitude,
                "center": {"type": "Point", "coordinates": [request.longitude, request.latitude]},
                "updated_at": now,
            }}
        )
        
        # Broadcast danger zone movement
        await ws_manager.broadcast_to_rangers("danger_zone_updated", {
            "danger_zone_id": str(alert["danger_zone_id"]),
            "alert_id": alert_id,
            "animal_type": alert["animal_type"],
            "new_latitude": request.latitude,
            "new_longitude": request.longitude,
            "updated_by": current_user["username"],
        })
        
        await ws_manager.broadcast_to_tourists("danger_zone_updated", {
            "danger_zone_id": str(alert["danger_zone_id"]),
            "animal_type": alert["animal_type"],
            "latitude": request.latitude,
            "longitude": request.longitude,
        })
    
    updated = await db.alerts.find_one({"_id": oid})
    return _format_alert(updated)
