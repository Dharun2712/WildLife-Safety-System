# 🌲 ForestGuard

**Real-time Wildlife Detection & Tourist Safety Platform**

ForestGuard is a production-quality MVP that integrates AI-powered wildlife detection with real-time tourist safety management. It combines a Flutter mobile app, FastAPI backend, YOLOv8n AI detection, and WebSocket communication to create a comprehensive wildlife safety ecosystem.

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Development Laptop                        │
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌──────────────────┐ │
│  │ AI Camera   │───▶│ FastAPI     │◀──▶│ MongoDB          │ │
│  │ YOLOv8n     │    │ Backend     │    │ Geospatial DB    │ │
│  │ OpenCV      │    │ JWT + RBAC  │    │ 2dsphere indexes │ │
│  └─────────────┘    └──────┬──────┘    └──────────────────┘ │
│                            │                                 │
│                     WebSocket + REST                         │
│                            │                                 │
│              ┌─────────────┼─────────────┐                  │
│              ▼                           ▼                  │
│     ┌──────────────┐          ┌──────────────┐              │
│     │ Flutter App  │          │ Flutter App  │              │
│     │ (Tourist)    │          │ (Ranger)     │              │
│     └──────────────┘          └──────────────┘              │
└──────────────────────────────────────────────────────────────┘
```

## 🌟 Key Features

- **AI Wildlife Detection** — YOLOv8n detects Tiger, Elephant, Lion, Leopard, Bear via webcam
- **Real-time Alerts** — WebSocket pushes wildlife alerts to Rangers and Tourists instantly
- **Dynamic Danger Zones** — Geospatial zones auto-created around detection locations
- **Role-based Mobile App** — Single Flutter app with Tourist and Ranger views
- **Ranger Actions** — Acknowledge, verify, reject, update location, close alerts
- **Tourist Safety** — GPS-based SAFE/APPROACHING/INSIDE status calculation
- **Simulation Mode** — Demo all 5 animals with one click
- **Privacy by Design** — Tourists never see other tourists' locations

## 📦 Project Structure

```
ForestGuard/
├── mobile/          # Flutter app (Tourist + Ranger)
├── backend/         # FastAPI backend (JWT + RBAC + WebSocket)
├── ai-camera/       # AI camera service (OpenCV + YOLOv8n)
├── database/        # MongoDB seeds and indexes
├── docs/            # Documentation
├── docker-compose.yml
└── SETUP.md
```

## 🚀 Quick Start

See [SETUP.md](SETUP.md) for detailed installation instructions.

```bash
# 1. Start MongoDB
docker-compose up -d

# 2. Seed database
cd database/seeds && python seed_data.py

# 3. Create indexes
cd database/indexes && python create_indexes.py

# 4. Start backend
cd backend && pip install -r requirements.txt && uvicorn app.main:app --reload --port 8000

# 5. Start AI Camera
cd ai-camera && pip install -r requirements.txt && python main.py

# 6. Start Flutter app
cd mobile && flutter run
```

## 📱 Demo Accounts

| Username | Password | Role |
|----------|----------|------|
| demo_tourist | password123 | Tourist |
| demo_ranger | password123 | Ranger |
| demo_admin | password123 | Admin |

## 🔗 Documentation

- [Setup Guide](SETUP.md) — Installation and configuration
- [API Documentation](docs/API.md) — REST endpoints and schemas
- [Database Schema](docs/DATABASE.md) — MongoDB collections and indexes
- [Architecture](docs/ARCHITECTURE.md) — System design and data flow
- [Demo Walkthrough](docs/DEMO.md) — Step-by-step demo guide
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Common issues and solutions
- [Deployment](docs/DEPLOYMENT.md) — Production deployment guide

## ⚠️ Important Notes

- AI identification may be inaccurate — all detections require ranger verification
- Safety radii are configurable demo parameters, not scientific safety guarantees
- Historical detections are never deleted
- Simulated detections are clearly labeled
