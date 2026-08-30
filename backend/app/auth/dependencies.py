"""
ForestGuard - Authentication Dependencies
FastAPI dependencies for JWT validation and RBAC enforcement.
"""

from functools import wraps
from typing import List

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.schemas import UserRole
from app.auth.service import decode_token
from app.database.connection import get_database

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db=Depends(get_database),
) -> dict:
    """
    Extract and validate the current user from JWT token.
    Returns the user document from MongoDB.
    """
    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    username = payload.get("sub")
    if username is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )

    user = await db.users.find_one({"username": username})
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    if not user.get("is_active", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is deactivated",
        )

    # Convert ObjectId to string for serialization
    user["id"] = str(user["_id"])
    return user


def require_role(allowed_roles: List[UserRole]):
    """
    RBAC dependency factory. Restricts endpoint access to specific roles.

    Usage:
        @router.get("/admin-only", dependencies=[Depends(require_role([UserRole.ADMIN]))])
        async def admin_endpoint(): ...
    """
    async def role_checker(current_user: dict = Depends(get_current_user)):
        user_role = current_user.get("role")
        if user_role not in [r.value for r in allowed_roles]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions for this action",
            )
        return current_user
    return role_checker


# Convenience dependencies for common role checks
require_tourist = require_role([UserRole.TOURIST])
require_ranger = require_role([UserRole.RANGER, UserRole.ADMIN])
require_admin = require_role([UserRole.ADMIN])
require_ranger_or_admin = require_role([UserRole.RANGER, UserRole.ADMIN])
