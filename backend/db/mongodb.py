"""
MongoDB connection manager.

Provides a lazily-initialised MongoClient and database reference.
All connection parameters come from core.config — nothing is hardcoded.
"""

import logging
from typing import Optional

from pymongo import MongoClient
from pymongo.database import Database
from pymongo.errors import ConnectionFailure

from backend.core.config import settings

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Module-level state (lazy singleton)
# ---------------------------------------------------------------------------
_client: Optional[MongoClient] = None
_db: Optional[Database] = None


def get_client() -> MongoClient:
    """Return the shared MongoClient, creating it on first call."""
    global _client
    if _client is None:
        logger.info("Connecting to MongoDB at %s …", settings.MONGO_URI[:40])
        _client = MongoClient(
            settings.MONGO_URI,
            serverSelectionTimeoutMS=5000,
            maxPoolSize=50,
        )
        # Ping to fail-fast on misconfiguration
        try:
            _client.admin.command("ping")
            logger.info("✅ MongoDB connected successfully.")
        except ConnectionFailure as exc:
            logger.warning("⚠️  MongoDB ping failed: %s", exc)
    return _client


def get_database() -> Database:
    """Return the application database."""
    global _db
    if _db is None:
        _db = get_client()[settings.DATABASE_NAME]
    return _db


def close_connection() -> None:
    """Gracefully close the MongoDB client (call on app shutdown)."""
    global _client, _db
    if _client:
        _client.close()
        logger.info("MongoDB connection closed.")
    _client = None
    _db = None
