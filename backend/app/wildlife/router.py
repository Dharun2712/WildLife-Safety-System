"""
ForestGuard - Wildlife Detection Router
Core detection pipeline: receive AI camera detections, create danger zones, trigger alerts.
"""

import math
from datetime import datetime, timezone
from typing import List, Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database
from app.websocket.manager import ws_manager

router = APIRouter(prefix="/api/wildlife", tags=["Wildlife"])


# --- Schemas ---

class BoundingBox(BaseModel):
    x_min: int = 0
    y_min: int = 0
    x_max: int = 0
    y_max: int = 0


class DetectionPayload(BaseModel):
    """Payload sent from AI camera service."""
    animal_type: str = Field(..., pattern=r"^(tiger|elephant|lion|leopard|bear)$")
    confidence: float = Field(..., ge=0.0, le=1.0)
    camera_id: str = Field(..., min_length=1)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    timestamp: Optional[str] = None
    bounding_box: Optional[BoundingBox] = None
    verification_status: Optional[str] = None  # "VERIFIED" or "NEEDS_VERIFICATION"
    model_version: Optional[str] = None
    is_simulation: bool = False


class DetectionResponse(BaseModel):
    id: str
    animal_type: str
    confidence: float
    camera_id: str
    latitude: float
    longitude: float
    status: str
    verification_status: Optional[str] = None
    model_version: Optional[str] = None
    forest_id: Optional[str] = None
    zone_code: Optional[str] = None
    danger_zone_id: Optional[str] = None
    alert_id: Optional[str] = None
    is_simulation: bool = False
    timestamp: Optional[str] = None
    created_at: Optional[str] = None


def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two GPS points in meters using Haversine formula."""
    R = 6371000  # Earth radius in meters
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def _find_nearby_tourists(db: AsyncIOMotorDatabase, lat: float, lng: float, radius_meters: float, multiplier: float = 1.5) -> dict:
    """Find tourists within approaching distance (radius * multiplier) of a point."""
    approaching_radius = radius_meters * multiplier
    
    # Get latest location for each tourist using aggregation
    pipeline = [
        {"$sort": {"timestamp": -1}},
        {"$group": {
            "_id": "$user_id",
            "latitude": {"$first": "$latitude"},
            "longitude": {"$first": "$longitude"},
            "timestamp": {"$first": "$timestamp"},
        }},
    ]
    
    tourists_inside = []
    tourists_approaching = []
    
    cursor = db.tourist_locations.aggregate(pipeline)
    async for doc in cursor:
        distance = _haversine_distance(lat, lng, doc["latitude"], doc["longitude"])
        tourist_id = str(doc["_id"])
        
        if distance <= radius_meters:
            tourists_inside.append(tourist_id)
        elif distance <= approaching_radius:
            tourists_approaching.append(tourist_id)
    
    return {
        "inside": tourists_inside,
        "approaching": tourists_approaching,
        "all_affected": tourists_inside + tourists_approaching,
    }


# --- Endpoints ---

@router.post("/detections", response_model=DetectionResponse, status_code=status.HTTP_201_CREATED)
async def create_detection(
    payload: DetectionPayload,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """
    Receive a wildlife detection from the AI camera.
    
    Pipeline:
    1. Validate payload
    2. Store detection in wildlife_detections
    3. Look up animal safety config (radius, threshold)
    4. Check confidence vs threshold
    5. If >= threshold: create danger zone + ACTIVE alert
    6. If < threshold: create NEEDS_VERIFICATION alert only
    7. Check for animal movement (update existing danger zone)
    8. Find nearby tourists and notify
    9. Broadcast WebSocket events
    """
    now = datetime.now(timezone.utc)
    
    # Look up camera to get forest association
    camera = await db.cameras.find_one({"camera_id": payload.camera_id})
    forest_id = camera.get("forest_id") if camera else None
    
    # Look up safety configuration for this animal with resilient fallback defaults
    DEFAULT_SAFETY_CONFIGS = {
        "tiger": {"confidence_threshold": 0.50, "danger_radius_meters": 2000, "approaching_multiplier": 1.5},
        "elephant": {"confidence_threshold": 0.50, "danger_radius_meters": 2500, "approaching_multiplier": 1.5},
        "lion": {"confidence_threshold": 0.50, "danger_radius_meters": 2000, "approaching_multiplier": 1.5},
        "leopard": {"confidence_threshold": 0.50, "danger_radius_meters": 1500, "approaching_multiplier": 1.5},
        "bear": {"confidence_threshold": 0.50, "danger_radius_meters": 1500, "approaching_multiplier": 1.5},
    }
    safety_config = await db.safety_configurations.find_one({"animal_type": payload.animal_type})
    if not safety_config:
        safety_config = DEFAULT_SAFETY_CONFIGS.get(payload.animal_type, {"confidence_threshold": 0.50, "danger_radius_meters": 2000, "approaching_multiplier": 1.5})
    
    confidence_threshold = safety_config.get("confidence_threshold", 0.50)
    danger_radius = safety_config.get("danger_radius_meters", 2000)
    approaching_multiplier = safety_config.get("approaching_multiplier", 1.5)
    
    # Determine zone code based on location
    zone_code = None
    if forest_id:
        zone = await db.forest_zones.find_one({
            "forest_id": forest_id,
            "boundary": {
                "$geoIntersects": {
                    "$geometry": {
                        "type": "Point",
                        "coordinates": [payload.longitude, payload.latitude]
                    }
                }
            }
        })
        if zone:
            zone_code = zone.get("code")
        else:
            # Fallback: find nearest zone
            zones = await db.forest_zones.find({"forest_id": forest_id}).to_list(length=10)
            if zones:
                min_dist = float('inf')
                for z in zones:
                    zc = z.get("center", {}).get("coordinates", [0, 0])
                    d = _haversine_distance(payload.latitude, payload.longitude, zc[1], zc[0])
                    if d < min_dist:
                        min_dist = d
                        zone_code = z.get("code")
    
    # Use AI camera's verification_status if provided, else compute from threshold
    if payload.verification_status == "VERIFIED":
        is_high_confidence = True
        detection_status = "active"
    elif payload.verification_status == "NEEDS_VERIFICATION":
        is_high_confidence = False
        detection_status = "needs_verification"
    else:
        is_high_confidence = payload.confidence >= confidence_threshold
        detection_status = "active" if is_high_confidence else "needs_verification"
    
    # Store detection
    detection_doc = {
        "animal_type": payload.animal_type,
        "confidence": payload.confidence,
        "camera_id": payload.camera_id,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "location": {"type": "Point", "coordinates": [payload.longitude, payload.latitude]},
        "bounding_box": payload.bounding_box.model_dump() if payload.bounding_box else None,
        "forest_id": forest_id,
        "zone_code": zone_code,
        "status": detection_status,
        "verification_status": payload.verification_status or detection_status,
        "model_version": payload.model_version,
        "is_simulation": payload.is_simulation,
        "timestamp": payload.timestamp or now.isoformat(),
        "created_at": now,
        "updated_at": now,
    }
    
    result = await db.wildlife_detections.insert_one(detection_doc)
    detection_id = result.inserted_id
    
    danger_zone_id = None
    alert_id = None
    
    # Check for existing active danger zone for same animal type
    existing_dz = await db.danger_zones.find_one({
        "animal_type": payload.animal_type,
        "status": "active",
        "forest_id": forest_id,
    })
    
    if existing_dz:
        # Animal movement — update existing danger zone center
        old_lat = existing_dz.get("center_latitude", 0)
        old_lng = existing_dz.get("center_longitude", 0)
        
        # Store movement history
        movement_doc = {
            "detection_id": detection_id,
            "animal_type": payload.animal_type,
            "from_latitude": old_lat,
            "from_longitude": old_lng,
            "to_latitude": payload.latitude,
            "to_longitude": payload.longitude,
            "location": {"type": "Point", "coordinates": [payload.longitude, payload.latitude]},
            "distance_meters": _haversine_distance(old_lat, old_lng, payload.latitude, payload.longitude),
            "forest_id": forest_id,
            "timestamp": now,
        }
        await db.wildlife_movements.insert_one(movement_doc)
        
        # Update danger zone center
        await db.danger_zones.update_one(
            {"_id": existing_dz["_id"]},
            {"$set": {
                "center_latitude": payload.latitude,
                "center_longitude": payload.longitude,
                "center": {"type": "Point", "coordinates": [payload.longitude, payload.latitude]},
                "latest_detection_id": detection_id,
                "updated_at": now,
            }}
        )
        danger_zone_id = existing_dz["_id"]
        
        # Broadcast danger zone update
        await ws_manager.broadcast_to_rangers("danger_zone_updated", {
            "danger_zone_id": str(danger_zone_id),
            "animal_type": payload.animal_type,
            "new_latitude": payload.latitude,
            "new_longitude": payload.longitude,
            "confidence": payload.confidence,
            "is_simulation": payload.is_simulation,
        })
        
        # Find and notify affected tourists
        nearby = await _find_nearby_tourists(db, payload.latitude, payload.longitude, danger_radius, approaching_multiplier)
        if nearby["all_affected"]:
            await ws_manager.broadcast_to_tourists("danger_zone_updated", {
                "danger_zone_id": str(danger_zone_id),
                "animal_type": payload.animal_type,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "radius_meters": danger_radius,
                "is_simulation": payload.is_simulation,
            }, tourist_ids=nearby["all_affected"])
    
    elif is_high_confidence:
        # Create new danger zone for high-confidence detection
        dz_doc = {
            "animal_type": payload.animal_type,
            "center_latitude": payload.latitude,
            "center_longitude": payload.longitude,
            "center": {"type": "Point", "coordinates": [payload.longitude, payload.latitude]},
            "radius_meters": danger_radius,
            "detection_id": detection_id,
            "latest_detection_id": detection_id,
            "forest_id": forest_id,
            "zone_code": zone_code,
            "status": "active",
            "is_simulation": payload.is_simulation,
            "ranger_acknowledged": False,
            "created_at": now,
            "updated_at": now,
        }
        dz_result = await db.danger_zones.insert_one(dz_doc)
        danger_zone_id = dz_result.inserted_id
        
        # Update detection with danger zone reference
        await db.wildlife_detections.update_one(
            {"_id": detection_id},
            {"$set": {"danger_zone_id": danger_zone_id}}
        )
        
        # Broadcast new danger zone to rangers
        await ws_manager.broadcast_to_rangers("danger_zone_created", {
            "danger_zone_id": str(danger_zone_id),
            "animal_type": payload.animal_type,
            "latitude": payload.latitude,
            "longitude": payload.longitude,
            "radius_meters": danger_radius,
            "confidence": payload.confidence,
            "zone_code": zone_code,
            "is_simulation": payload.is_simulation,
        })
    
    # Create alert
    alert_status = "active" if is_high_confidence else "needs_verification"
    alert_doc = {
        "detection_id": detection_id,
        "danger_zone_id": danger_zone_id,
        "animal_type": payload.animal_type,
        "confidence": payload.confidence,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "forest_id": forest_id,
        "zone_code": zone_code,
        "status": alert_status,
        "is_simulation": payload.is_simulation,
        "ranger_acknowledged": False,
        "created_at": now,
        "updated_at": now,
    }
    alert_result = await db.alerts.insert_one(alert_doc)
    alert_id = alert_result.inserted_id
    
    # Update detection with alert reference
    await db.wildlife_detections.update_one(
        {"_id": detection_id},
        {"$set": {"alert_id": alert_id, "danger_zone_id": danger_zone_id}}
    )
    
    # Notify rangers of new detection
    await ws_manager.broadcast_to_rangers("wildlife_detected", {
        "detection_id": str(detection_id),
        "alert_id": str(alert_id),
        "animal_type": payload.animal_type,
        "confidence": payload.confidence,
        "latitude": payload.latitude,
        "longitude": payload.longitude,
        "zone_code": zone_code,
        "status": alert_status,
        "is_simulation": payload.is_simulation,
        "requires_verification": not is_high_confidence,
    })
    
    # Notify affected tourists (only for high-confidence / active danger zones)
    if is_high_confidence and danger_zone_id:
        nearby = await _find_nearby_tourists(db, payload.latitude, payload.longitude, danger_radius, approaching_multiplier)
        
        # Create notifications for affected tourists
        for tourist_id in nearby["all_affected"]:
            tourist_status = "inside" if tourist_id in nearby["inside"] else "approaching"
            notif_doc = {
                "user_id": ObjectId(tourist_id),
                "type": "wildlife_warning",
                "title": "WILDLIFE SAFETY ALERT",
                "message": (
                    "A wildlife detection has been reported near your current area. "
                    "You are within or approaching an active wildlife safety zone. "
                    "Please remain at a safe location and follow official ranger instructions."
                ),
                "alert_id": alert_id,
                "danger_zone_id": danger_zone_id,
                "animal_type": payload.animal_type,
                "safety_status": tourist_status,
                "is_read": False,
                "is_simulation": payload.is_simulation,
                "created_at": now,
            }
            await db.notifications.insert_one(notif_doc)
        
        # Send WebSocket tourist warnings
        if nearby["all_affected"]:
            await ws_manager.broadcast_to_tourists("tourist_warning", {
                "alert_id": str(alert_id),
                "danger_zone_id": str(danger_zone_id),
                "animal_type": payload.animal_type,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "radius_meters": danger_radius,
                "zone_code": zone_code,
                "is_simulation": payload.is_simulation,
                "message": (
                    "A wildlife detection has been reported near your current area. "
                    "Please remain at a safe location and follow official ranger instructions."
                ),
            }, tourist_ids=nearby["all_affected"])
    
    return DetectionResponse(
        id=str(detection_id),
        animal_type=payload.animal_type,
        confidence=payload.confidence,
        camera_id=payload.camera_id,
        latitude=payload.latitude,
        longitude=payload.longitude,
        status=detection_status,
        verification_status=payload.verification_status or detection_status,
        model_version=payload.model_version,
        forest_id=str(forest_id) if forest_id else None,
        zone_code=zone_code,
        danger_zone_id=str(danger_zone_id) if danger_zone_id else None,
        alert_id=str(alert_id) if alert_id else None,
        is_simulation=payload.is_simulation,
        timestamp=detection_doc["timestamp"],
        created_at=now.isoformat(),
    )


@router.get("/detections", response_model=list[DetectionResponse])
async def list_detections(
    animal_type: Optional[str] = None,
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List wildlife detections with optional filters."""
    query = {}
    if animal_type:
        query["animal_type"] = animal_type
    if status_filter:
        query["status"] = status_filter
    
    cursor = db.wildlife_detections.find(query).sort("created_at", -1).limit(limit)
    detections = await cursor.to_list(length=limit)
    
    return [
        DetectionResponse(
            id=str(d["_id"]),
            animal_type=d["animal_type"],
            confidence=d["confidence"],
            camera_id=d["camera_id"],
            latitude=d["latitude"],
            longitude=d["longitude"],
            status=d["status"],
            forest_id=str(d.get("forest_id")) if d.get("forest_id") else None,
            zone_code=d.get("zone_code"),
            danger_zone_id=str(d.get("danger_zone_id")) if d.get("danger_zone_id") else None,
            alert_id=str(d.get("alert_id")) if d.get("alert_id") else None,
            is_simulation=d.get("is_simulation", False),
            timestamp=d.get("timestamp"),
            created_at=d.get("created_at", "").isoformat() if d.get("created_at") else None,
        )
        for d in detections
    ]


@router.get("/detections/{detection_id}", response_model=DetectionResponse)
async def get_detection(
    detection_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get a specific detection by ID."""
    try:
        d = await db.wildlife_detections.find_one({"_id": ObjectId(detection_id)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid detection ID")
    
    if not d:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Detection not found")
    
    return DetectionResponse(
        id=str(d["_id"]),
        animal_type=d["animal_type"],
        confidence=d["confidence"],
        camera_id=d["camera_id"],
        latitude=d["latitude"],
        longitude=d["longitude"],
        status=d["status"],
        forest_id=str(d.get("forest_id")) if d.get("forest_id") else None,
        zone_code=d.get("zone_code"),
        danger_zone_id=str(d.get("danger_zone_id")) if d.get("danger_zone_id") else None,
        alert_id=str(d.get("alert_id")) if d.get("alert_id") else None,
        is_simulation=d.get("is_simulation", False),
        timestamp=d.get("timestamp"),
        created_at=d.get("created_at", "").isoformat() if d.get("created_at") else None,
    )


@router.get("/movements/{animal_type}")
async def get_movement_history(
    animal_type: str,
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Get movement history for an animal type (Ranger/Admin only)."""
    cursor = db.wildlife_movements.find(
        {"animal_type": animal_type}
    ).sort("timestamp", -1).limit(limit)
    
    movements = await cursor.to_list(length=limit)
    return [
        {
            "id": str(m["_id"]),
            "detection_id": str(m.get("detection_id", "")),
            "animal_type": m["animal_type"],
            "from_latitude": m.get("from_latitude"),
            "from_longitude": m.get("from_longitude"),
            "to_latitude": m.get("to_latitude"),
            "to_longitude": m.get("to_longitude"),
            "distance_meters": m.get("distance_meters"),
            "timestamp": m.get("timestamp", "").isoformat() if m.get("timestamp") else None,
        }
        for m in movements
    ]
