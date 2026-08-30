"""
ForestGuard Backend - MongoDB Connection Manager
Uses Motor async driver with resilient connection & fallback.
"""

import logging
import sys
from typing import Optional

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.config.settings import settings

logger = logging.getLogger("forestguard.database")


class DatabaseManager:
    """Manages MongoDB connection lifecycle with resilient fallback."""

    client: AsyncIOMotorClient = None
    db: AsyncIOMotorDatabase = None

    async def connect(self):
        """Initialize MongoDB connection with fallback options."""
        # 1. Try primary configured URI
        try:
            self.client = AsyncIOMotorClient(
                settings.MONGODB_URI,
                serverSelectionTimeoutMS=5000,
                connectTimeoutMS=5000,
            )
            self.db = self.client[settings.MONGODB_DB_NAME]
            await self.client.admin.command("ping")
            print(f"✅ Connected to MongoDB Atlas: {settings.MONGODB_DB_NAME}")
            return
        except Exception as e:
            print(f"⚠️ Primary MongoDB connection failed: {e}")

        # 2. Try local MongoDB fallback
        try:
            local_uri = "mongodb://localhost:27017"
            self.client = AsyncIOMotorClient(
                local_uri,
                serverSelectionTimeoutMS=3000,
                connectTimeoutMS=3000,
            )
            self.db = self.client[settings.MONGODB_DB_NAME]
            await self.client.admin.command("ping")
            print(f"✅ Connected to Local MongoDB: {settings.MONGODB_DB_NAME}")
            return
        except Exception as e:
            print(f"⚠️ Local MongoDB fallback also unavailable: {e}")
            # Keep client initialized so app routes can operate or handle gracefully
            self.client = AsyncIOMotorClient(settings.MONGODB_URI, serverSelectionTimeoutMS=2000)
            self.db = self.client[settings.MONGODB_DB_NAME]

    async def disconnect(self):
        """Close MongoDB connection."""
        if self.client:
            self.client.close()
            print("🔌 MongoDB connection closed")

    def get_db(self) -> AsyncIOMotorDatabase:
        """Get database instance."""
        if self.db is None:
            raise RuntimeError("Database not initialized. Call connect() first.")
        return self.db


# Singleton database manager
db_manager = DatabaseManager()


async def get_database() -> AsyncIOMotorDatabase:
    """FastAPI dependency to get database instance."""
    return db_manager.get_db()
