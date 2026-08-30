# ForestGuard — System Architecture & Design

ForestGuard is designed as an event-driven, role-segregated safety platform.

## 🔄 End-to-End Incident Flow Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Cam as AI Camera (C-01)
    participant API as FastAPI Backend
    participant DB as MongoDB
    participant WS as WebSocket Hub
    participant Rng as Ranger App
    participant Trt as Tourist App

    Cam->>API: POST /api/wildlife/detections (YOLOv8n / Simulation)
    API->>DB: Store in wildlife_detections
    alt Confidence >= 0.70 (High)
        API->>DB: Create danger_zone (ACTIVE) & alert (ACTIVE)
        API->>WS: Broadcast wildlife_detected & danger_zone_created
        WS-->>Rng: Real-time Incident Alert
        API->>DB: Query tourists within 1.5x danger radius
        API->>WS: Broadcast tourist_warning
        WS-->>Trt: Safety status -> APPROACHING / INSIDE
    else Confidence < 0.70 (Low)
        API->>DB: Create alert (NEEDS_VERIFICATION)
        API->>WS: Broadcast wildlife_detected (Needs verification)
        WS-->>Rng: Review prompt
        Rng->>API: PATCH /api/alerts/{id}/verify
        API->>DB: Activate danger zone
        API->>WS: Broadcast danger_zone_created & tourist_warning
        WS-->>Trt: Tourist Alert Triggered
    end

    opt Ranger updates location
        Rng->>API: PATCH /api/alerts/{id}/location
        API->>DB: Record wildlife_movement & move zone center
        API->>WS: Broadcast danger_zone_updated
        WS-->>Rng: Map danger circle moves
        WS-->>Trt: Map danger circle moves & status recalculated
    end

    Rng->>API: PATCH /api/alerts/{id}/close
    API->>DB: Mark alert & danger_zone as CLOSED
    API->>WS: Broadcast alert_closed & alert_closed_notification
    WS-->>Trt: Safety status -> SAFE & Closure message
```

## 🛡️ Security & Privacy Model
1. **RBAC at Gateway & Endpoints:** Endpoints explicitly enforce `require_tourist`, `require_ranger`, or `require_admin`.
2. **Tourist Location Privacy:** Tourists can only retrieve their own location. They never receive or see coordinates of other tourists.
3. **Restricted Incident Visibility:** Rangers can only view tourist coordinates within an active incident zone during an ongoing response.
