"""
ForestGuard - Reports Router
Reporting endpoints for detection, incident, and tourist statistics.
"""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.auth.dependencies import require_role
from app.auth.schemas import UserRole
from app.database.connection import get_database

router = APIRouter(prefix="/api/reports", tags=["Reports"])


@router.get("/detections")
async def detection_report(
    days: int = Query(7, ge=1, le=90),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Detection statistics report (Ranger/Admin only)."""
    from datetime import timedelta
    since = datetime.now(timezone.utc) - timedelta(days=days)
    
    total = await db.wildlife_detections.count_documents({"created_at": {"$gte": since}})
    
    # Group by animal type
    pipeline = [
        {"$match": {"created_at": {"$gte": since}}},
        {"$group": {"_id": "$animal_type", "count": {"$sum": 1}, "avg_confidence": {"$avg": "$confidence"}}},
        {"$sort": {"count": -1}},
    ]
    by_animal = await db.wildlife_detections.aggregate(pipeline).to_list(length=10)
    
    simulated = await db.wildlife_detections.count_documents({"created_at": {"$gte": since}, "is_simulation": True})
    
    return {
        "period_days": days,
        "total_detections": total,
        "simulated_detections": simulated,
        "real_detections": total - simulated,
        "by_animal": [
            {"animal_type": a["_id"], "count": a["count"], "avg_confidence": round(a["avg_confidence"], 3)}
            for a in by_animal
        ],
    }


@router.get("/incidents")
async def incident_report(
    days: int = Query(7, ge=1, le=90),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Alert/incident statistics report."""
    from datetime import timedelta
    since = datetime.now(timezone.utc) - timedelta(days=days)
    
    total_alerts = await db.alerts.count_documents({"created_at": {"$gte": since}})
    active = await db.alerts.count_documents({"status": {"$in": ["active", "acknowledged", "monitoring"]}})
    closed = await db.alerts.count_documents({"created_at": {"$gte": since}, "status": "closed"})
    rejected = await db.alerts.count_documents({"created_at": {"$gte": since}, "status": "rejected"})
    
    active_zones = await db.danger_zones.count_documents({"status": "active"})
    
    return {
        "period_days": days,
        "total_alerts": total_alerts,
        "currently_active": active,
        "closed": closed,
        "rejected": rejected,
        "active_danger_zones": active_zones,
    }


@router.get("/tourists")
async def tourist_report(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(require_role([UserRole.RANGER, UserRole.ADMIN])),
):
    """Tourist statistics report (aggregate only, no individual data)."""
    total_tourists = await db.users.count_documents({"role": "tourist", "is_active": True})
    
    # Count tourists with recent locations (active in last hour)
    from datetime import timedelta
    recent = datetime.now(timezone.utc) - timedelta(hours=1)
    pipeline = [
        {"$match": {"timestamp": {"$gte": recent}}},
        {"$group": {"_id": "$user_id"}},
        {"$count": "total"},
    ]
    result = await db.tourist_locations.aggregate(pipeline).to_list(length=1)
    active_tourists = result[0]["total"] if result else 0
    
    total_notifications = await db.notifications.count_documents({"type": "wildlife_warning"})
    
    return {
        "total_registered_tourists": total_tourists,
        "currently_active": active_tourists,
        "total_warnings_sent": total_notifications,
    }
