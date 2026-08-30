"""
ForestGuard Backend - Application Settings
Loads all configuration from environment variables using Pydantic BaseSettings.
"""

import json
import os
from typing import List

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # MongoDB
    MONGODB_URI: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "forestguard"

    # JWT Authentication
    JWT_SECRET: str = "change-this-secret-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Server
    BACKEND_HOST: str = "0.0.0.0"
    BACKEND_PORT: int = int(os.getenv("PORT", os.getenv("BACKEND_PORT", "8000")))
    CORS_ORIGINS: str = '["*"]'

    # Detection
    DEFAULT_CONFIDENCE_THRESHOLD: float = 0.70

    @property
    def cors_origins_list(self) -> List[str]:
        """Parse CORS origins from JSON string."""
        try:
            return json.loads(self.CORS_ORIGINS)
        except (json.JSONDecodeError, TypeError):
            return ["*"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Singleton settings instance
settings = Settings()
