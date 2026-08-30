"""
ForestGuard - Danger Zones Router
Geospatial danger zone management with proximity queries.
"""

import math
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database

router = APIRouter(prefix="/api/danger-zones", tags=["Danger Zones"])


class DangerZoneResponse(BaseModel):
    id: str
    animal_type: str
    center_latitude: float
    center_longitude: float
    radius_meters: float
    status: str
    zone_code: Optional[str] = None
    forest_id: Optional[str] = None
    is_simulation: bool = False
    ranger_acknowledged: bool = False
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


def _format_dz(d: dict) -> DangerZoneResponse:
    return DangerZoneResponse(
        id=str(d["_id"]),
        animal_type=d["animal_type"],
        center_latitude=d["center_latitude"],
        center_longitude=d["center_longitude"],
        radius_meters=d["radius_meters"],
        status=d["status"],
        zone_code=d.get("zone_code"),
        forest_id=str(d.get("forest_id")) if d.get("forest_id") else None,
        is_simulation=d.get("is_simulation", False),
        ranger_acknowledged=d.get("ranger_acknowledged", False),
        created_at=d.get("created_at", "").isoformat() if d.get("created_at") else None,
        updated_at=d.get("updated_at", "").isoformat() if d.get("updated_at") else None,
    )


@router.get("", response_model=list[DangerZoneResponse])
async def list_danger_zones(
    status_filter: Optional[str] = Query(None, alias="status"),
    forest_id: Optional[str] = None,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List danger zones with optional filters."""
    query = {}
    if status_filter:
        query["status"] = status_filter
    if forest_id:
        try:
            query["forest_id"] = ObjectId(forest_id)
        except Exception:
            pass
    
    cursor = db.danger_zones.find(query).sort("created_at", -1)
    zones = await cursor.to_list(length=100)
    return [_format_dz(z) for z in zones]


@router.get("/near")
async def get_nearby_danger_zones(
    latitude: float = Query(..., ge=-90, le=90),
    longitude: float = Query(..., ge=-180, le=180),
    max_distance: float = Query(10000, ge=100, le=50000),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Find active danger zones near a GPS coordinate using geospatial query."""
    pipeline = [
        {
            "$geoNear": {
                "near": {"type": "Point", "coordinates": [longitude, latitude]},
                "distanceField": "distance_meters",
                "maxDistance": max_distance,
                "query": {"status": "active"},
                "spherical": True,
            }
        },
        {"$sort": {"distance_meters": 1}},
    ]
    
    cursor = db.danger_zones.aggregate(pipeline)
    results = await cursor.to_list(length=50)
    
    return [
        {
            **_format_dz(r).model_dump(),
            "distance_meters": round(r.get("distance_meters", 0), 1),
        }
        for r in results
    ]


@router.get("/{zone_id}", response_model=DangerZoneResponse)
async def get_danger_zone(
    zone_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get a specific danger zone."""
    try:
        zone = await db.danger_zones.find_one({"_id": ObjectId(zone_id)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid zone ID")
    
    if not zone:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Danger zone not found")
    return _format_dz(zone)


@router.patch("/{zone_id}")
async def update_danger_zone(
    zone_id: str,
    status_update: Optional[str] = None,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Update danger zone status (Ranger/Admin only)."""
    try:
        oid = ObjectId(zone_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid zone ID")
    
    update_data = {}
    if status_update:
        if status_update not in ["active", "closed", "expired"]:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status")
        update_data["status"] = status_update
    
    if not update_data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    
    from datetime import datetime, timezone
    update_data["updated_at"] = datetime.now(timezone.utc)
    
    result = await db.danger_zones.update_one({"_id": oid}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Danger zone not found")
    
    zone = await db.danger_zones.find_one({"_id": oid})
    return _format_dz(zone)
