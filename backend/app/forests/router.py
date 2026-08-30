"""
ForestGuard - Forests Router
Forest and zone management endpoints.
"""

from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel, Field

from app.auth.dependencies import get_current_user, require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database

router = APIRouter(prefix="/api/forests", tags=["Forests"])


# --- Schemas ---

class ForestResponse(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    state: Optional[str] = None
    country: Optional[str] = None
    center_latitude: Optional[float] = None
    center_longitude: Optional[float] = None
    area_sq_km: Optional[float] = None
    is_active: bool = True


class ForestZoneResponse(BaseModel):
    id: str
    forest_id: str
    name: str
    code: str
    description: Optional[str] = None
    center_latitude: Optional[float] = None
    center_longitude: Optional[float] = None
    color: Optional[str] = None
    is_active: bool = True


class CreateZoneRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    code: str = Field(..., min_length=1, max_length=10)
    description: Optional[str] = None
    center_latitude: float = Field(..., ge=-90, le=90)
    center_longitude: float = Field(..., ge=-180, le=180)
    color: Optional[str] = "#2E7D32"


class UpdateZoneRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    color: Optional[str] = None
    is_active: Optional[bool] = None


def _format_forest(doc: dict) -> ForestResponse:
    center = doc.get("center", {})
    coords = center.get("coordinates", [0, 0]) if isinstance(center, dict) else [0, 0]
    return ForestResponse(
        id=str(doc["_id"]),
        name=doc["name"],
        description=doc.get("description"),
        state=doc.get("state"),
        country=doc.get("country"),
        center_latitude=coords[1] if len(coords) > 1 else None,
        center_longitude=coords[0] if len(coords) > 0 else None,
        area_sq_km=doc.get("area_sq_km"),
        is_active=doc.get("is_active", True),
    )


def _format_zone(doc: dict) -> ForestZoneResponse:
    center = doc.get("center", {})
    coords = center.get("coordinates", [0, 0]) if isinstance(center, dict) else [0, 0]
    return ForestZoneResponse(
        id=str(doc["_id"]),
        forest_id=str(doc.get("forest_id", "")),
        name=doc["name"],
        code=doc["code"],
        description=doc.get("description"),
        center_latitude=coords[1] if len(coords) > 1 else None,
        center_longitude=coords[0] if len(coords) > 0 else None,
        color=doc.get("color"),
        is_active=doc.get("is_active", True),
    )


# --- Endpoints ---

@router.get("", response_model=list[ForestResponse])
async def list_forests(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List all active forests."""
    cursor = db.forests.find({"is_active": True})
    forests = await cursor.to_list(length=100)
    return [_format_forest(f) for f in forests]


@router.get("/{forest_id}", response_model=ForestResponse)
async def get_forest(
    forest_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Get a specific forest by ID."""
    try:
        forest = await db.forests.find_one({"_id": ObjectId(forest_id)})
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid forest ID")
    
    if not forest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forest not found")
    return _format_forest(forest)


@router.get("/{forest_id}/zones", response_model=list[ForestZoneResponse])
async def list_zones(
    forest_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List all zones for a specific forest."""
    try:
        oid = ObjectId(forest_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid forest ID")
    
    cursor = db.forest_zones.find({"forest_id": oid, "is_active": True})
    zones = await cursor.to_list(length=100)
    return [_format_zone(z) for z in zones]


@router.post("/{forest_id}/zones", response_model=ForestZoneResponse, status_code=status.HTTP_201_CREATED)
async def create_zone(
    forest_id: str,
    request: CreateZoneRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.ADMIN])),
):
    """Create a new zone in a forest (Admin only)."""
    try:
        oid = ObjectId(forest_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid forest ID")

    forest = await db.forests.find_one({"_id": oid})
    if not forest:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Forest not found")

    from datetime import datetime, timezone
    zone_doc = {
        "forest_id": oid,
        "name": request.name,
        "code": request.code,
        "description": request.description,
        "center": {"type": "Point", "coordinates": [request.center_longitude, request.center_latitude]},
        "color": request.color,
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    result = await db.forest_zones.insert_one(zone_doc)
    zone_doc["_id"] = result.inserted_id
    return _format_zone(zone_doc)


@router.put("/{forest_id}/zones/{zone_id}", response_model=ForestZoneResponse)
async def update_zone(
    forest_id: str,
    zone_id: str,
    request: UpdateZoneRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.ADMIN])),
):
    """Update a forest zone (Admin only)."""
    try:
        zone_oid = ObjectId(zone_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid zone ID")

    update_data = {k: v for k, v in request.model_dump().items() if v is not None}
    if not update_data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")

    from datetime import datetime, timezone
    update_data["updated_at"] = datetime.now(timezone.utc)

    result = await db.forest_zones.update_one({"_id": zone_oid}, {"$set": update_data})
    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Zone not found")

    zone = await db.forest_zones.find_one({"_id": zone_oid})
    return _format_zone(zone)
