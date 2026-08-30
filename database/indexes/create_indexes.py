"""
ForestGuard - MongoDB Index Creation Script
Creates all required indexes including 2dsphere geospatial, TTL, and compound indexes.

Usage:
    python create_indexes.py
"""

import os
import sys
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

from dotenv import load_dotenv
from pymongo import ASCENDING, DESCENDING, MongoClient

# Load environment variables
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    env_example = Path(__file__).resolve().parent.parent.parent / ".env.example"
    if env_example.exists():
        load_dotenv(env_example)

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("MONGODB_DB_NAME", "forestguard")


def create_indexes():
    """Create all MongoDB indexes for ForestGuard."""
    print("🔧 Creating ForestGuard MongoDB Indexes")
    print(f"   URI: {MONGODB_URI}")
    print(f"   Database: {DB_NAME}")
    print()

    client = MongoClient(MONGODB_URI)
    db = client[DB_NAME]

    # --- Users ---
    print("👤 users:")
    db.users.create_index("username", unique=True)
    print("   ✅ username (unique)")
    db.users.create_index("email", unique=True)
    print("   ✅ email (unique)")
    db.users.create_index("role")
    print("   ✅ role")

    # --- Forests ---
    print("🌳 forests:")
    db.forests.create_index([("center", "2dsphere")])
    print("   ✅ center (2dsphere)")
    db.forests.create_index([("boundary", "2dsphere")])
    print("   ✅ boundary (2dsphere)")

    # --- Forest Zones ---
    print("📍 forest_zones:")
    db.forest_zones.create_index([("center", "2dsphere")])
    print("   ✅ center (2dsphere)")
    db.forest_zones.create_index([("boundary", "2dsphere")])
    print("   ✅ boundary (2dsphere)")
    db.forest_zones.create_index([("forest_id", ASCENDING), ("code", ASCENDING)])
    print("   ✅ (forest_id, code) compound")

    # --- Cameras ---
    print("📷 cameras:")
    db.cameras.create_index([("location", "2dsphere")])
    print("   ✅ location (2dsphere)")
    db.cameras.create_index("camera_id", unique=True)
    print("   ✅ camera_id (unique)")
    db.cameras.create_index([("forest_id", ASCENDING)])
    print("   ✅ forest_id")

    # --- Wildlife Detections ---
    print("🐾 wildlife_detections:")
    db.wildlife_detections.create_index([("location", "2dsphere")])
    print("   ✅ location (2dsphere)")
    db.wildlife_detections.create_index([("camera_id", ASCENDING), ("timestamp", DESCENDING)])
    print("   ✅ (camera_id, timestamp) compound")
    db.wildlife_detections.create_index([("animal_type", ASCENDING), ("timestamp", DESCENDING)])
    print("   ✅ (animal_type, timestamp) compound")
    db.wildlife_detections.create_index([("forest_id", ASCENDING)])
    print("   ✅ forest_id")
    db.wildlife_detections.create_index("status")
    print("   ✅ status")

    # --- Wildlife Movements ---
    print("🦶 wildlife_movements:")
    db.wildlife_movements.create_index([("location", "2dsphere")])
    print("   ✅ location (2dsphere)")
    db.wildlife_movements.create_index([("detection_id", ASCENDING), ("timestamp", DESCENDING)])
    print("   ✅ (detection_id, timestamp) compound")
    db.wildlife_movements.create_index([("animal_type", ASCENDING), ("timestamp", DESCENDING)])
    print("   ✅ (animal_type, timestamp) compound")

    # --- Danger Zones ---
    print("⚠️  danger_zones:")
    db.danger_zones.create_index([("center", "2dsphere")])
    print("   ✅ center (2dsphere)")
    db.danger_zones.create_index("status")
    print("   ✅ status")
    db.danger_zones.create_index([("forest_id", ASCENDING), ("status", ASCENDING)])
    print("   ✅ (forest_id, status) compound")
    db.danger_zones.create_index([("animal_type", ASCENDING), ("status", ASCENDING)])
    print("   ✅ (animal_type, status) compound")
    db.danger_zones.create_index("detection_id")
    print("   ✅ detection_id")

    # --- Alerts ---
    print("🚨 alerts:")
    db.alerts.create_index([("alert_id", ASCENDING), ("status", ASCENDING)])
    print("   ✅ (alert_id, status) compound")
    db.alerts.create_index("status")
    print("   ✅ status")
    db.alerts.create_index([("forest_id", ASCENDING), ("status", ASCENDING)])
    print("   ✅ (forest_id, status) compound")
    db.alerts.create_index([("created_at", DESCENDING)])
    print("   ✅ created_at descending")
    db.alerts.create_index("danger_zone_id")
    print("   ✅ danger_zone_id")

    # --- Notifications ---
    print("🔔 notifications:")
    db.notifications.create_index([("user_id", ASCENDING), ("created_at", DESCENDING)])
    print("   ✅ (user_id, created_at) compound")
    db.notifications.create_index("is_read")
    print("   ✅ is_read")
    # TTL: auto-delete notifications after 30 days
    db.notifications.create_index("created_at", expireAfterSeconds=30 * 24 * 3600)
    print("   ✅ created_at TTL (30 days)")

    # --- Tourist Locations ---
    print("📍 tourist_locations:")
    db.tourist_locations.create_index([("location", "2dsphere")])
    print("   ✅ location (2dsphere)")
    db.tourist_locations.create_index([("user_id", ASCENDING), ("timestamp", DESCENDING)])
    print("   ✅ (user_id, timestamp) compound")
    # TTL: auto-delete location data after 1 hour
    db.tourist_locations.create_index("timestamp", expireAfterSeconds=3600)
    print("   ✅ timestamp TTL (1 hour)")

    # --- Incidents ---
    print("📋 incidents:")
    db.incidents.create_index([("forest_id", ASCENDING), ("status", ASCENDING)])
    print("   ✅ (forest_id, status) compound")
    db.incidents.create_index([("created_at", DESCENDING)])
    print("   ✅ created_at descending")

    # --- Safety Configurations ---
    print("⚙️  safety_configurations:")
    db.safety_configurations.create_index("animal_type", unique=True)
    print("   ✅ animal_type (unique)")

    print()
    print("🎉 All indexes created successfully!")
    client.close()


if __name__ == "__main__":
    create_indexes()
