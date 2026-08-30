"""
ForestGuard - FastAPI Application Entry Point

Wildlife Detection & Tourist Safety Platform Backend.
Provides REST API, WebSocket real-time events, JWT authentication, and RBAC.
"""

import logging
import sys
from contextlib import asynccontextmanager

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config.settings import settings
from app.database.connection import db_manager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("forestguard")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan — connect/disconnect MongoDB."""
    logger.info("🌲 ForestGuard Backend starting...")
    await db_manager.connect()
    logger.info("✅ All systems ready")
    yield
    await db_manager.disconnect()
    logger.info("🔌 ForestGuard Backend shutdown complete")


# Create FastAPI app
app = FastAPI(
    title="ForestGuard API",
    description=(
        "Real-time wildlife detection and tourist safety platform. "
        "Provides REST API for mobile clients, WebSocket for real-time events, "
        "and integration with AI camera detection pipeline."
    ),
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Global Exception Handler ---
# Never expose stack traces to clients

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all exception handler — no stack traces exposed to clients."""
    logger.error(f"Unhandled error on {request.method} {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An internal server error occurred. Please try again later."},
    )


@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": "Resource not found"},
    )


# --- Register Routers ---

from app.auth.router import router as auth_router
from app.users.router import router as users_router
from app.forests.router import router as forests_router
from app.wildlife.router import router as wildlife_router
from app.danger_zones.router import router as danger_zones_router
from app.alerts.router import router as alerts_router
from app.tourists.router import router as tourists_router
from app.notifications.router import router as notifications_router
from app.cameras.router import router as cameras_router
from app.reports.router import router as reports_router
from app.websocket.router import router as websocket_router

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(forests_router)
app.include_router(wildlife_router)
app.include_router(danger_zones_router)
app.include_router(alerts_router)
app.include_router(tourists_router)
app.include_router(notifications_router)
app.include_router(cameras_router)
app.include_router(reports_router)
app.include_router(websocket_router)


# --- Health Check ---

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    try:
        db = db_manager.get_db()
        await db.command("ping")
        db_status = "connected"
    except Exception:
        db_status = "disconnected"

    from app.websocket.manager import ws_manager

    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "service": "ForestGuard API",
        "version": "1.0.0",
        "database": db_status,
        "websocket_connections": {
            "rangers": ws_manager.active_rangers,
            "tourists": ws_manager.active_tourists,
        },
    }


@app.get("/", tags=["Root"])
async def root():
    return {
        "service": "ForestGuard API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }


if __name__ == "__main__":
    import os
    import uvicorn
    port = int(os.getenv("PORT", settings.BACKEND_PORT))
    uvicorn.run(
        "app.main:app",
        host=settings.BACKEND_HOST,
        port=port,
        reload=True,
    )
