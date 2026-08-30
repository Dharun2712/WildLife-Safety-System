"""
ForestGuard - Database Seed Script
Seeds MongoDB with demo data for the Mudumalai Wildlife Reserve demo.
All data is configurable — no hard-coded values in the application.

Usage:
    python seed_data.py                 # Seed database
    python seed_data.py --verify        # Verify seed data
    python seed_data.py --drop          # Drop and re-seed
"""

import argparse
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

from dotenv import load_dotenv
from passlib.context import CryptContext
from pymongo import MongoClient

# Load environment variables
env_path = Path(__file__).resolve().parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    # Try .env.example as fallback for first run
    env_example = Path(__file__).resolve().parent.parent.parent / ".env.example"
    if env_example.exists():
        load_dotenv(env_example)

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("MONGODB_DB_NAME", "forestguard")

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def get_demo_forest():
    """Mudumalai Wildlife Reserve demo forest configuration."""
    return {
        "name": "Mudumalai Wildlife Reserve",
        "description": "Mudumalai Wildlife Sanctuary is located in the Nilgiri Hills, "
                       "part of the Western Ghats in Tamil Nadu, India. It is home to "
                       "several endangered species including tigers, elephants, and leopards.",
        "state": "Tamil Nadu",
        "country": "India",
        "center": {
            "type": "Point",
            "coordinates": [76.6320, 11.5690]  # [lng, lat] GeoJSON format
        },
        "boundary": {
            "type": "Polygon",
            "coordinates": [[
                [76.5800, 11.5200],
                [76.6900, 11.5200],
                [76.6900, 11.6200],
                [76.5800, 11.6200],
                [76.5800, 11.5200]
            ]]
        },
        "area_sq_km": 321.0,
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc)
    }


def get_demo_zones(forest_id):
    """Four demo zones within Mudumalai Wildlife Reserve."""
    zones = [
        {
            "forest_id": forest_id,
            "name": "Zone A",
            "code": "A",
            "description": "Northern sector - Dense forest area with tiger corridor",
            "center": {"type": "Point", "coordinates": [76.6100, 11.5900]},
            "boundary": {
                "type": "Polygon",
                "coordinates": [[
                    [76.5800, 11.5700],
                    [76.6350, 11.5700],
                    [76.6350, 11.6200],
                    [76.5800, 11.6200],
                    [76.5800, 11.5700]
                ]]
            },
            "color": "#2E7D32",
            "is_active": True,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "forest_id": forest_id,
            "name": "Zone B",
            "code": "B",
            "description": "Eastern sector - Elephant habitat and water bodies",
            "center": {"type": "Point", "coordinates": [76.6700, 11.5600]},
            "boundary": {
                "type": "Polygon",
                "coordinates": [[
                    [76.6350, 11.5400],
                    [76.6900, 11.5400],
                    [76.6900, 11.5700],
                    [76.6350, 11.5700],
                    [76.6350, 11.5400]
                ]]
            },
            "color": "#1565C0",
            "is_active": True,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "forest_id": forest_id,
            "name": "Zone C",
            "code": "C",
            "description": "Southern sector - Safari route and visitor area",
            "center": {"type": "Point", "coordinates": [76.6100, 11.5350]},
            "boundary": {
                "type": "Polygon",
                "coordinates": [[
                    [76.5800, 11.5200],
                    [76.6350, 11.5200],
                    [76.6350, 11.5400],
                    [76.5800, 11.5400],
                    [76.5800, 11.5200]
                ]]
            },
            "color": "#E65100",
            "is_active": True,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "forest_id": forest_id,
            "name": "Zone D",
            "code": "D",
            "description": "Western sector - Leopard territory and hillside terrain",
            "center": {"type": "Point", "coordinates": [76.5900, 11.5550]},
            "boundary": {
                "type": "Polygon",
                "coordinates": [[
                    [76.5800, 11.5400],
                    [76.6350, 11.5400],
                    [76.6350, 11.5700],
                    [76.5800, 11.5700],
                    [76.5800, 11.5400]
                ]]
            },
            "color": "#6A1B9A",
            "is_active": True,
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        }
    ]
    return zones


def get_demo_camera(forest_id):
    """Camera C-01 configuration."""
    return {
        "camera_id": "C-01",
        "name": "Main Entrance Camera",
        "forest_id": forest_id,
        "location": {
            "type": "Point",
            "coordinates": [76.6320, 11.5690]  # [lng, lat]
        },
        "latitude": 11.5690,
        "longitude": 76.6320,
        "status": "online",
        "type": "webcam",
        "description": "Development laptop webcam for wildlife detection demo",
        "is_active": True,
        "last_heartbeat": datetime.now(timezone.utc),
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc)
    }


def get_demo_users():
    """Demo user accounts with bcrypt-hashed passwords."""
    now = datetime.now(timezone.utc)
    return [
        {
            "username": "demo_tourist",
            "email": "tourist@forestguard.demo",
            "password_hash": pwd_context.hash("password123"),
            "full_name": "Demo Tourist",
            "phone": "+91-9876543210",
            "role": "tourist",
            "is_active": True,
            "created_at": now,
            "updated_at": now
        },
        {
            "username": "demo_ranger",
            "email": "ranger@forestguard.demo",
            "password_hash": pwd_context.hash("password123"),
            "full_name": "Demo Ranger",
            "phone": "+91-9876543211",
            "role": "ranger",
            "badge_number": "MWR-001",
            "is_active": True,
            "created_at": now,
            "updated_at": now
        },
        {
            "username": "demo_admin",
            "email": "admin@forestguard.demo",
            "password_hash": pwd_context.hash("password123"),
            "full_name": "Demo Admin",
            "phone": "+91-9876543212",
            "role": "admin",
            "is_active": True,
            "created_at": now,
            "updated_at": now
        }
    ]


def get_safety_configurations():
    """Animal safety configurations — all configurable, demo defaults only."""
    return [
        {
            "animal_type": "tiger",
            "display_name": "Tiger",
            "danger_radius_meters": 2000,
            "approaching_multiplier": 1.5,
            "confidence_threshold": 0.70,
            "icon": "🐯",
            "color": "#FF6F00",
            "description": "Operational demo parameter. Not a scientific safety guarantee.",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "animal_type": "elephant",
            "display_name": "Elephant",
            "danger_radius_meters": 2500,
            "approaching_multiplier": 1.5,
            "confidence_threshold": 0.70,
            "icon": "🐘",
            "color": "#5D4037",
            "description": "Operational demo parameter. Not a scientific safety guarantee.",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "animal_type": "lion",
            "display_name": "Lion",
            "danger_radius_meters": 2000,
            "approaching_multiplier": 1.5,
            "confidence_threshold": 0.70,
            "icon": "🦁",
            "color": "#BF360C",
            "description": "Operational demo parameter. Not a scientific safety guarantee.",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "animal_type": "leopard",
            "display_name": "Leopard",
            "danger_radius_meters": 1500,
            "approaching_multiplier": 1.5,
            "confidence_threshold": 0.70,
            "icon": "🐆",
            "color": "#4E342E",
            "description": "Operational demo parameter. Not a scientific safety guarantee.",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        },
        {
            "animal_type": "bear",
            "display_name": "Bear",
            "danger_radius_meters": 1500,
            "approaching_multiplier": 1.5,
            "confidence_threshold": 0.70,
            "icon": "🐻",
            "color": "#3E2723",
            "description": "Operational demo parameter. Not a scientific safety guarantee.",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        }
    ]


def seed_database(drop_existing=False):
    """Seed the ForestGuard MongoDB database with demo data."""
    print(f"🌲 ForestGuard Database Seeder")
    print(f"   MongoDB URI: {MONGODB_URI}")
    print(f"   Database: {DB_NAME}")
    print()

    client = MongoClient(MONGODB_URI)
    db = client[DB_NAME]

    if drop_existing:
        print("⚠️  Dropping existing database...")
        client.drop_database(DB_NAME)
        db = client[DB_NAME]
        print("   Database dropped.\n")

    # Check if already seeded
    if db.users.count_documents({}) > 0 and not drop_existing:
        print("ℹ️  Database already contains data. Use --drop to re-seed.")
        print("   Run: python seed_data.py --drop")
        client.close()
        return

    # 1. Seed Forest
    print("🌳 Seeding forest...")
    forest = get_demo_forest()
    result = db.forests.insert_one(forest)
    forest_id = result.inserted_id
    print(f"   ✅ Forest '{forest['name']}' created (ID: {forest_id})")

    # 2. Seed Zones
    print("📍 Seeding forest zones...")
    zones = get_demo_zones(forest_id)
    zone_results = db.forest_zones.insert_many(zones)
    for i, zone in enumerate(zones):
        print(f"   ✅ {zone['name']} - {zone['description']}")

    # 3. Seed Camera
    print("📷 Seeding camera...")
    camera = get_demo_camera(forest_id)
    camera["zone_ids"] = [z for z in zone_results.inserted_ids]
    db.cameras.insert_one(camera)
    print(f"   ✅ Camera '{camera['camera_id']}' - {camera['name']}")

    # 4. Seed Users
    print("👤 Seeding demo users...")
    users = get_demo_users()
    for user in users:
        # Assign forest to ranger
        if user["role"] == "ranger":
            user["assigned_forest_id"] = forest_id
        db.users.insert_one(user)
        print(f"   ✅ {user['username']} ({user['role']})")

    # 5. Seed Safety Configurations
    print("⚙️  Seeding safety configurations...")
    configs = get_safety_configurations()
    db.safety_configurations.insert_many(configs)
    for config in configs:
        print(f"   ✅ {config['display_name']}: {config['danger_radius_meters']}m radius, "
              f"{config['confidence_threshold']*100:.0f}% threshold")

    # 6. Create empty collections for runtime data
    print("📦 Creating runtime collections...")
    runtime_collections = [
        "wildlife_detections", "wildlife_movements", "danger_zones",
        "alerts", "notifications", "tourist_locations", "incidents"
    ]
    for coll_name in runtime_collections:
        if coll_name not in db.list_collection_names():
            db.create_collection(coll_name)
            print(f"   ✅ {coll_name}")
        else:
            print(f"   ℹ️  {coll_name} (already exists)")

    print()
    print("🎉 Database seeding complete!")
    print()
    print("   Demo Accounts:")
    print("   ┌─────────────────┬──────────────┬─────────┐")
    print("   │ Username        │ Password     │ Role    │")
    print("   ├─────────────────┼──────────────┼─────────┤")
    print("   │ demo_tourist    │ password123  │ tourist │")
    print("   │ demo_ranger     │ password123  │ ranger  │")
    print("   │ demo_admin      │ password123  │ admin   │")
    print("   └─────────────────┴──────────────┴─────────┘")

    client.close()


def verify_database():
    """Verify that the database has been seeded correctly."""
    print(f"🔍 Verifying ForestGuard Database")
    print(f"   MongoDB URI: {MONGODB_URI}")
    print(f"   Database: {DB_NAME}")
    print()

    client = MongoClient(MONGODB_URI)
    db = client[DB_NAME]

    collections = {
        "users": 3,
        "forests": 1,
        "forest_zones": 4,
        "cameras": 1,
        "safety_configurations": 5
    }

    all_ok = True
    for coll_name, expected_count in collections.items():
        actual = db[coll_name].count_documents({})
        status = "✅" if actual >= expected_count else "❌"
        if actual < expected_count:
            all_ok = False
        print(f"   {status} {coll_name}: {actual} documents (expected ≥ {expected_count})")

    # Check indexes
    print()
    print("   Indexes:")
    for coll_name in db.list_collection_names():
        indexes = list(db[coll_name].list_indexes())
        geo_indexes = [idx for idx in indexes if any(
            v == "2dsphere" for v in (idx.get("key", {}).values() if isinstance(idx.get("key", {}), dict) else [])
        )]
        if geo_indexes:
            print(f"   ✅ {coll_name}: {len(geo_indexes)} geospatial index(es)")

    print()
    if all_ok:
        print("🎉 Verification passed!")
    else:
        print("⚠️  Verification found issues. Run: python seed_data.py --drop")

    client.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="ForestGuard Database Seeder")
    parser.add_argument("--verify", action="store_true", help="Verify seed data")
    parser.add_argument("--drop", action="store_true", help="Drop and re-seed database")
    args = parser.parse_args()

    if args.verify:
        verify_database()
    else:
        seed_database(drop_existing=args.drop)
