# ForestGuard — Setup & Installation Guide

This guide walks you through setting up and running all four components of the **ForestGuard** platform on a single development laptop:
1. **MongoDB Database**
2. **FastAPI Backend Service**
3. **AI Camera & Detection Monitor (Webcam C-01)**
4. **Flutter Mobile Application (Tourist & Ranger)**

---

## 📋 Prerequisites

Ensure you have the following installed on your laptop:
- **Python 3.10+** (`python --version`)
- **MongoDB 6.0+** (or Docker Desktop)
- **Flutter SDK 3.19+** (`flutter doctor`)
- **Webcam** (built-in or USB camera for AI detection)

---

## ⚙️ 1. Environment Configuration

Copy the example environment file at the root:

```bash
cp .env.example .env
```

And in the backend directory:
```bash
cp backend/.env.example backend/.env
```

Default configuration in `.env`:
```env
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=forestguard
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_ALGORITHM=HS256
BACKEND_HOST=0.0.0.0
BACKEND_PORT=8000
CAMERA_ID=C-01
CONFIDENCE_THRESHOLD=0.70
```

---

## 🗄️ 2. Database Initialization

### Option A: Local MongoDB Service
Ensure your local MongoDB service is running on `localhost:27017`.

### Option B: Docker
```bash
docker-compose up -d
```

### Seed Demo Data & Create Indexes
```bash
# Seed initial forest, zones, users, and safety parameters
cd database/seeds
python seed_data.py --drop

# Create geospatial 2dsphere, TTL, and compound indexes
cd ../indexes
python create_indexes.py
```

Demo accounts created:
- **Tourist:** `demo_tourist` / `password123`
- **Ranger:** `demo_ranger` / `password123`
- **Admin:** `demo_admin` / `password123`

---

## 🚀 3. Start FastAPI Backend

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

- API Base URL: `http://localhost:8000`
- Interactive Swagger UI: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/health`
- WebSocket endpoint: `ws://localhost:8000/ws?token=<JWT>`

---

## 📷 4. Start AI Camera & Detection Console

Open a new terminal:
```bash
cd ai-camera
pip install -r requirements.txt
python main.py
```

- Monitoring Web UI: `http://localhost:8501`
- Features:
  - Live webcam MJPEG feed with bounding boxes
  - Simulation buttons (🐯 Tiger, 🐘 Elephant, 🦁 Lion, 🐆 Leopard, 🐻 Bear)
  - Detection history & backend connection status

---

## 📱 5. Run Flutter Mobile App

Open a new terminal:
```bash
cd mobile
flutter pub get
flutter run
```

### Running on Physical Device vs Emulator:
- **Android Emulator**: Uses `http://10.0.2.2:8000` by default (already pre-configured in `lib/config/constants.dart`).
- **Physical Device**: Update `apiBaseUrl` in `lib/config/constants.dart` to your laptop's local IP address (e.g. `http://192.168.1.50:8000`).
