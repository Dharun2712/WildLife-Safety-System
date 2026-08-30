"""
ForestGuard - Tourist Locations Router
Tourist GPS tracking and safety status calculation.
"""

import math
from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database
from app.websocket.manager import ws_manager

router = APIRouter(prefix="/api/tourists", tags=["Tourists"])


class LocationUpdateRequest(BaseModel):
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    accuracy: Optional[float] = None


class SafetyStatusResponse(BaseModel):
    status: str  # safe, approaching, inside
    message: str
    active_danger_zones: list = []
    nearest_zone_distance: Optional[float] = None
    nearest_zone_animal: Optional[str] = None


def _haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


SAFETY_MESSAGES = {
    "safe": "No active wildlife safety alert near your current location.",
    "approaching": "You are approaching an active wildlife safety zone.",
    "inside": (
        "Your current location is within an active wildlife safety zone. "
        "Remain at a safe location and follow official ranger instructions."
    ),
}


@router.post("/locations", status_code=status.HTTP_201_CREATED)
async def update_location(
    request: LocationUpdateRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Update tourist GPS location (with explicit consent)."""
    if current_user.get("role") != "tourist":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only tourists can update location")
    
    now = datetime.now(timezone.utc)
    location_doc = {
        "user_id": current_user["_id"],
        "latitude": request.latitude,
        "longitude": request.longitude,
        "location": {"type": "Point", "coordinates": [request.longitude, request.latitude]},
        "accuracy": request.accuracy,
        "timestamp": now,
    }
    
    await db.tourist_locations.insert_one(location_doc)
    
    # Update WebSocket manager cache
    ws_manager.update_tourist_location(current_user["id"], request.latitude, request.longitude)
    
    return {"message": "Location updated", "timestamp": now.isoformat()}


@router.get("/safety-status", response_model=SafetyStatusResponse)
async def get_safety_status(
    latitude: float = None,
    longitude: float = None,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """
    Calculate tourist's safety status relative to active danger zones.
    
    Status logic:
    - INSIDE: within danger zone radius
    - APPROACHING: within 1.5 × radius
    - SAFE: outside all zones
    """
    if current_user.get("role") != "tourist":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only tourists can check safety status")
    
    # If no coordinates provided, get latest from DB
    if latitude is None or longitude is None:
        latest = await db.tourist_locations.find_one(
            {"user_id": current_user["_id"]},
            sort=[("timestamp", -1)]
        )
        if not latest:
            return SafetyStatusResponse(
                status="safe",
                message=SAFETY_MESSAGES["safe"],
                active_danger_zones=[],
            )
        latitude = latest["latitude"]
        longitude = latest["longitude"]
    
    # Get all active danger zones
    active_zones = await db.danger_zones.find({"status": "active"}).to_list(length=100)
    
    overall_status = "safe"
    nearest_distance = float("inf")
    nearest_animal = None
    zone_details = []
    
    for zone in active_zones:
        distance = _haversine(
            latitude, longitude,
            zone["center_latitude"], zone["center_longitude"]
        )
        radius = zone["radius_meters"]
        
        # Get approaching multiplier from config
        config = await db.safety_configurations.find_one({"animal_type": zone["animal_type"]})
        multiplier = config.get("approaching_multiplier", 1.5) if config else 1.5
        approaching_radius = radius * multiplier
        
        if distance <= radius:
            zone_status = "inside"
            if overall_status != "inside":
                overall_status = "inside"
        elif distance <= approaching_radius:
            zone_status = "approaching"
            if overall_status == "safe":
                overall_status = "approaching"
        else:
            zone_status = "safe"
        
        if distance < nearest_distance:
            nearest_distance = distance
            nearest_animal = zone["animal_type"]
        
        zone_details.append({
            "danger_zone_id": str(zone["_id"]),
            "animal_type": zone["animal_type"],
            "distance_meters": round(distance, 1),
            "radius_meters": radius,
            "status": zone_status,
            "is_simulation": zone.get("is_simulation", False),
        })
    
    return SafetyStatusResponse(
        status=overall_status,
        message=SAFETY_MESSAGES.get(overall_status, SAFETY_MESSAGES["safe"]),
        active_danger_zones=zone_details,
        nearest_zone_distance=round(nearest_distance, 1) if nearest_distance < float("inf") else None,
        nearest_zone_animal=nearest_animal,
    )


@router.get("/locations/nearby")
async def get_nearby_tourists(
    alert_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """
    Get tourist locations near an active alert (Ranger only, during active incidents).
    Returns precise locations only for tourists within the danger zone area.
    Privacy: Only authorized during active incidents.
    """
    try:
        alert = await db.alerts.find_one({"_id": ObjectId(alert_id)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid alert ID")
    
    if not alert:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")
    
    if alert["status"] in ["closed", "rejected"]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot access tourist locations for closed/rejected alerts")
    
    # Get danger zone radius
    dz = None
    if alert.get("danger_zone_id"):
        dz = await db.danger_zones.find_one({"_id": alert["danger_zone_id"]})
    
    radius = dz["radius_meters"] if dz else 2000
    lat, lng = alert["latitude"], alert["longitude"]
    
    # Find tourists with recent locations near the zone
    pipeline = [
        {"$sort": {"timestamp": -1}},
        {"$group": {
            "_id": "$user_id",
            "latitude": {"$first": "$latitude"},
            "longitude": {"$first": "$longitude"},
            "timestamp": {"$first": "$timestamp"},
        }},
    ]
    
    cursor = db.tourist_locations.aggregate(pipeline)
    nearby = []
    
    async for doc in cursor:
        dist = _haversine(lat, lng, doc["latitude"], doc["longitude"])
        multiplier = 1.5
        if dist <= radius * multiplier:
            user = await db.users.find_one({"_id": doc["_id"]})
            nearby.append({
                "tourist_id": str(doc["_id"]),
                "latitude": doc["latitude"],
                "longitude": doc["longitude"],
                "distance_meters": round(dist, 1),
                "status": "inside" if dist <= radius else "approaching",
                "last_updated": doc["timestamp"].isoformat() if doc.get("timestamp") else None,
            })
    
    return {
        "alert_id": alert_id,
        "total_tourists_nearby": len(nearby),
        "tourists": nearby,
    }
