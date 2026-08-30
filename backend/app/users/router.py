"""
ForestGuard - Users Router
User profile management endpoints.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.auth.dependencies import get_current_user
from app.auth.schemas import ChangePasswordRequest, UpdateProfileRequest, UserResponse
from app.auth.service import hash_password, verify_password
from app.database.connection import get_database

router = APIRouter(prefix="/api/users", tags=["Users"])


@router.get("/me", response_model=UserResponse)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get current user's profile."""
    return UserResponse(
        id=current_user["id"],
        username=current_user["username"],
        email=current_user["email"],
        full_name=current_user["full_name"],
        phone=current_user.get("phone"),
        role=current_user["role"],
        is_active=current_user["is_active"],
        created_at=current_user.get("created_at"),
    )


@router.put("/me", response_model=UserResponse)
async def update_profile(
    request: UpdateProfileRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Update current user's profile."""
    update_data = {k: v for k, v in request.model_dump().items() if v is not None}

    if not update_data:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")

    # Check email uniqueness if being updated
    if "email" in update_data:
        existing = await db.users.find_one({"email": update_data["email"], "username": {"$ne": current_user["username"]}})
        if existing:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already in use")

    from datetime import datetime, timezone
    update_data["updated_at"] = datetime.now(timezone.utc)

    await db.users.update_one({"_id": current_user["_id"]}, {"$set": update_data})

    updated_user = await db.users.find_one({"_id": current_user["_id"]})
    return UserResponse(
        id=str(updated_user["_id"]),
        username=updated_user["username"],
        email=updated_user["email"],
        full_name=updated_user["full_name"],
        phone=updated_user.get("phone"),
        role=updated_user["role"],
        is_active=updated_user["is_active"],
        created_at=updated_user.get("created_at"),
    )


@router.post("/me/password", status_code=status.HTTP_200_OK)
async def change_password(
    request: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Change current user's password."""
    if not verify_password(request.current_password, current_user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect")

    from datetime import datetime, timezone
    await db.users.update_one(
        {"_id": current_user["_id"]},
        {"$set": {
            "password_hash": hash_password(request.new_password),
            "updated_at": datetime.now(timezone.utc),
        }},
    )

    return {"message": "Password updated successfully"}
