"""
ForestGuard - Notifications Router
User notification management.
"""

from datetime import datetime, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel

from app.auth.dependencies import get_current_user
from app.database.connection import get_database

router = APIRouter(prefix="/api/notifications", tags=["Notifications"])


class NotificationResponse(BaseModel):
    id: str
    type: str
    title: str
    message: str
    animal_type: Optional[str] = None
    alert_id: Optional[str] = None
    safety_status: Optional[str] = None
    is_read: bool = False
    is_simulation: Optional[bool] = False
    created_at: Optional[str] = None


def _format_notif(n: dict) -> NotificationResponse:
    return NotificationResponse(
        id=str(n["_id"]),
        type=n.get("type", "info"),
        title=n.get("title", ""),
        message=n.get("message", ""),
        animal_type=n.get("animal_type"),
        alert_id=str(n.get("alert_id")) if n.get("alert_id") else None,
        safety_status=n.get("safety_status"),
        is_read=n.get("is_read", False),
        is_simulation=n.get("is_simulation", False),
        created_at=n.get("created_at", "").isoformat() if n.get("created_at") else None,
    )


@router.get("", response_model=list[NotificationResponse])
async def list_notifications(
    unread_only: bool = False,
    limit: int = Query(50, ge=1, le=200),
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """List notifications for the current user."""
    query = {"user_id": current_user["_id"]}
    if unread_only:
        query["is_read"] = False
    
    cursor = db.notifications.find(query).sort("created_at", -1).limit(limit)
    notifs = await cursor.to_list(length=limit)
    return [_format_notif(n) for n in notifs]


@router.patch("/{notification_id}")
async def mark_notification_read(
    notification_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Mark a notification as read."""
    try:
        oid = ObjectId(notification_id)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid notification ID")
    
    result = await db.notifications.update_one(
        {"_id": oid, "user_id": current_user["_id"]},
        {"$set": {"is_read": True, "read_at": datetime.now(timezone.utc)}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    
    return {"message": "Notification marked as read"}


@router.patch("/read-all")
async def mark_all_read(
    db: AsyncIOMotorDatabase = Depends(get_database),
    current_user: dict = Depends(get_current_user),
):
    """Mark all notifications as read for the current user."""
    now = datetime.now(timezone.utc)
    result = await db.notifications.update_many(
        {"user_id": current_user["_id"], "is_read": False},
        {"$set": {"is_read": True, "read_at": now}}
    )
    return {"message": f"{result.modified_count} notifications marked as read"}
