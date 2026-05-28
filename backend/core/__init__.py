"""
Core application configuration.

All settings are loaded from environment variables / .env file using
pydantic-settings. Never hardcode secrets — this module is the single
source of truth for every configurable value.
"""

import os
from typing import List

from dotenv import load_dotenv

# Load .env before anything reads os.environ
load_dotenv()


class Settings:
    """Application-wide settings populated from environment variables."""

    # ── MongoDB ──────────────────────────────────────────────────────────
    MONGO_URI: str = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    DATABASE_NAME: str = os.getenv("DATABASE_NAME", "insighthub")
    REVIEWS_COLLECTION: str = os.getenv("REVIEWS_COLLECTION", "reviews")

    # ── Application ──────────────────────────────────────────────────────
    APP_NAME: str = "InsightHub API"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # ── CORS ─────────────────────────────────────────────────────────────
    CORS_ORIGINS: List[str] = os.getenv(
        "CORS_ORIGINS", "*"
    ).split(",")

    # ── Upload limits ────────────────────────────────────────────────────
    MAX_UPLOAD_SIZE_MB: int = int(os.getenv("MAX_UPLOAD_SIZE_MB", "10"))

    # ── Logging ──────────────────────────────────────────────────────────
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


# Singleton – import this everywhere
settings = Settings()
