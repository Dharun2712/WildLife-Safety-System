# ForestGuard — Troubleshooting & Diagnostic FAQ

## ❓ Frequently Encountered Scenarios

### 1. AI Camera: "Camera Offline" or Index Error
- **Cause:** OpenCV cannot open default camera index 0 (camera already in use by Zoom/Teams/OBS or permission denied).
- **Fix:**
  - Close other webcam applications.
  - In `ai-camera/config.py` or `.env`, set `CAMERA_INDEX=1` or test with simulation mode (simulation mode does not require physical camera access).

### 2. Mobile App: "Cannot connect to server"
- **Cause:** Incorrect API host address.
- **Fix:**
  - If running in **Android Emulator**: Ensure base URL is set to `http://10.0.2.2:8000`.
  - If running on a **Physical Device**: Update `lib/config/constants.dart` with your development computer's LAN IP (e.g. `http://192.168.1.100:8000`).

### 3. Backend: "pymongo.errors.ServerSelectionTimeoutError"
- **Cause:** MongoDB service is not started.
- **Fix:**
  - Verify MongoDB service is active: `mongosh --eval "db.runCommand('ping')"`
  - Or launch via Docker: `docker-compose up -d`

### 4. WebSocket Disconnections in Field / Mobile
- **Cause:** Transient cellular network packet loss.
- **Fix:**
  - ForestGuard client includes built-in auto-reconnection with exponential backoff (1s to 30s max jitter). The app will automatically resume state streaming upon link recovery.
