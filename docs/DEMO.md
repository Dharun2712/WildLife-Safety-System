# ForestGuard — End-to-End Live Demonstration Guide

Follow this sequential walkthrough to demonstrate the full end-to-end capabilities of ForestGuard on a single development machine.

---

## 🎬 1. Preparation & Startup

1. **MongoDB running** on `localhost:27017`
2. **FastAPI backend running** (`uvicorn app.main:app --port 8000`)
3. **AI Camera UI running** at `http://localhost:8501`
4. **Flutter mobile app running** (in Android Emulator or physical device)

---

## 🧭 2. Step-by-Step Incident Simulation Walkthrough

### Step 1: Tourist Login & Map View
- Open the Flutter App.
- View the onboarding screens -> Tap **Get Started**.
- Select **Tourist** -> Login with `demo_tourist` / `password123`.
- Observe the **Home** tab showing Safety Status: **SAFE** (Green badge: *"No active wildlife safety alert near your current location."*).

### Step 2: Ranger Login
- Switch app or login in another instance as **Ranger** (`demo_ranger` / `password123`).
- Observe **Ranger Operations HQ** with live telemetry counters.

### Step 3: Trigger High-Confidence Wildlife Detection
- In your browser, open the AI Camera console at `http://localhost:8501`.
- Click **SIMULATE TIGER** (triggers a detection in Zone A with ~85% confidence).
- **Observe:**
  - AI Camera log updates immediately with simulated bounding box and demo coordinates.
  - Backend creates a 2000m dynamic Danger Zone in MongoDB.
  - Ranger receives instant WebSocket alert on the **Incident Management** tab.
  - Tourist App receives instant real-time push/in-app alert banner: **WILDLIFE SAFETY ALERT**.
  - Tourist Safety Status changes to **APPROACHING** or **INSIDE**.

### Step 4: Ranger Verification & Location Update
- In the Ranger app, tap **Acknowledge** on the Tiger incident.
- Tap **Update Animal Location** -> Enter updated coordinates.
- **Observe:**
  - MongoDB records the movement trajectory.
  - The danger zone center dynamically moves in real time across both Ranger and Tourist maps via WebSocket without any manual screen refresh.

### Step 5: Multi-Animal Simultaneous Incidents
- In the AI Camera UI, click **SIMULATE ELEPHANT** (Zone B, 2500m radius) and **SIMULATE LION** (Zone C, 2000m radius).
- **Observe:** Multiple distinct simultaneous danger circles render on Ranger HQ and tourist maps.

### Step 6: Incident Closure
- In the Ranger app, tap **Close Alert** on the Tiger incident.
- **Observe:**
  - Danger zone status updates to `CLOSED`.
  - Tourist receives closure notice: *"The wildlife alert in Zone A has been closed by the forest ranger."*
  - Tourist safety status immediately transitions back to **SAFE**.
