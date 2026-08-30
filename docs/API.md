# ForestGuard — REST & WebSocket API Specification

All protected REST endpoints require a JWT Bearer token in the `Authorization` header (`Bearer <token>`).

## 🔐 1. Authentication (`/api/auth`)

### `POST /api/auth/register`
Self-registration for tourists.
- **Request:**
  ```json
  {
    "username": "johndoe",
    "email": "john@example.com",
    "password": "password123",
    "full_name": "John Doe",
    "phone": "+91-9876543210",
    "role": "tourist"
  }
  ```
- **Response `201 Created`:**
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "eyJhbGciOi...",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "66c1f...",
      "username": "johndoe",
      "email": "john@example.com",
      "full_name": "John Doe",
      "role": "tourist"
    }
  }
  ```

### `POST /api/auth/login`
Role-aware authentication for Tourists, Rangers, and Admins.
- **Request:**
  ```json
  {
    "username": "demo_ranger",
    "password": "password123",
    "role": "ranger"
  }
  ```

### `POST /api/auth/refresh`
- **Request:** `{"refresh_token": "..."}`

---

## 🐾 2. Wildlife Detections (`/api/wildlife`)

### `POST /api/wildlife/detections`
Primary ingest endpoint called by AI camera services or simulation controls.
- **Request Payload:**
  ```json
  {
    "animal_type": "tiger",
    "confidence": 0.88,
    "camera_id": "C-01",
    "latitude": 11.5900,
    "longitude": 76.6100,
    "bounding_box": {
      "x_min": 120,
      "y_min": 80,
      "x_max": 450,
      "y_max": 380
    },
    "is_simulation": false
  }
  ```
- **Behavior:**
  - If `confidence >= threshold` (0.70): Auto-creates active danger zone + alert. Broadcasts to Rangers + affected Tourists.
  - If `confidence < threshold`: Creates `needs_verification` alert only (Ranger must verify).

---

## 🚨 3. Alerts & Danger Zones (`/api/alerts`, `/api/danger-zones`)

### `PATCH /api/alerts/{id}/acknowledge`
Ranger acknowledges receipt of an alert.

### `PATCH /api/alerts/{id}/verify`
Ranger confirms low-confidence detection; activates danger zone and broadcasts warnings to tourists.

### `PATCH /api/alerts/{id}/reject`
Ranger discards low-confidence false positive.

### `PATCH /api/alerts/{id}/location`
Ranger updates wildlife position (dynamically moves danger zone center in real time):
- **Request:** `{"latitude": 11.5950, "longitude": 76.6150}`

### `PATCH /api/alerts/{id}/close`
Ranger closes incident; marks danger zone closed and broadcasts closure notices to all tourists.

---

## 📍 4. Tourist Safety & Location (`/api/tourists`)

### `POST /api/tourists/locations`
Updates tourist GPS location securely (with consent).
- **Request:** `{"latitude": 11.5850, "longitude": 76.6120, "accuracy": 5.0}`

### `GET /api/tourists/safety-status`
Returns real-time proximity safety classification:
- **Response:**
  ```json
  {
    "status": "inside",
    "message": "Your current location is within an active wildlife safety zone. Remain at a safe location and follow official ranger instructions.",
    "active_danger_zones": [
      {
        "danger_zone_id": "66c1f...",
        "animal_type": "tiger",
        "distance_meters": 450.2,
        "radius_meters": 2000,
        "status": "inside"
      }
    ]
  }
  ```

---

## ⚡ 5. Real-Time WebSocket (`/ws?token=<JWT>`)

Connect via WebSocket to receive real-time reactive updates:

| Event Name | Audience | Description |
|---|---|---|
| `wildlife_detected` | Rangers | New AI detection event |
| `danger_zone_created` | Rangers & Affected Tourists | Danger zone activated |
| `danger_zone_updated` | Rangers & Affected Tourists | Animal moved / Zone center updated |
| `alert_acknowledged` | Rangers & Tourists | Ranger acknowledged incident |
| `tourist_warning` | Affected Tourists | Direct warning notification |
| `alert_closed` | Rangers | Ranger closed incident |
| `alert_closed_notification` | All Tourists | Official closure broadcast |
| `camera_status_changed` | Rangers | Camera online/offline heartbeat |
