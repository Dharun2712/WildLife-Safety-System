# ForestGuard — Database Architecture & Schema

ForestGuard uses **MongoDB** with `2dsphere` geospatial indexes for sub-millisecond proximity queries.

## 🗄️ Collections Overview

```
forestguard (Database)
├── users                   # Tourists, Rangers, Admins with hashed passwords
├── forests                 # Reserve polygons & centers
├── forest_zones            # Zonal partitions (Zone A, B, C, D)
├── cameras                 # Static & Webcam IoT configurations
├── wildlife_detections     # Full immutable history of detections
├── wildlife_movements      # Trajectory movement log
├── danger_zones            # Active and closed dynamic danger buffers
├── alerts                  # Incident state machine records
├── notifications           # Individual tourist & ranger notifications (TTL)
├── tourist_locations       # Ephemeral GPS telemetry (TTL: 1 hour)
└── safety_configurations   # Animal species safety buffer radii & thresholds
```

---

## 📐 Geospatial & Compound Indexes

1. **`2dsphere` Geospatial Indexes:**
   - `forests.center`, `forests.boundary`
   - `forest_zones.center`, `forest_zones.boundary`
   - `cameras.location`
   - `wildlife_detections.location`
   - `wildlife_movements.location`
   - `danger_zones.center`
   - `tourist_locations.location`

2. **Compound Indexes:**
   - `(forest_id, code)` on `forest_zones`
   - `(camera_id, timestamp DESC)` on `wildlife_detections`
   - `(animal_type, timestamp DESC)` on `wildlife_detections`
   - `(forest_id, status)` on `danger_zones`
   - `(user_id, created_at DESC)` on `notifications`
   - `(user_id, timestamp DESC)` on `tourist_locations`

3. **Time-To-Live (TTL) Indexes:**
   - `tourist_locations.timestamp` (Expires after **3600 seconds** / 1 hour) — *Privacy preservation*
   - `notifications.created_at` (Expires after **30 days**) — *Database hygiene*

---

## 🔒 Data Preservation Guarantee
Per critical architecture requirements, **historical detections and movements are never deleted or modified**. They serve as permanent telemetry for wildlife tracking and incident audits.
