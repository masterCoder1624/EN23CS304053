"""
InsightHub — AI-Powered Feedback Analytics Platform
Main FastAPI application entry point with robust production configurations.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from backend.core.config import settings
from backend.db.mongodb import close_connection
from backend.models.response_model import APIResponse
from backend.repositories.reviews_repository import reviews_repo
from backend.routes.analysis import router as analysis_router
from backend.routes.upload import router as upload_router

# Configure global logger
logging.basicConfig(
    level=settings.LOG_LEVEL,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifecycle events spanning application startup to shutdown."""
    logger.info("Initializing InsightHub API v%s", settings.APP_VERSION)
    yield
    logger.info("Shutting down InsightHub API...")
    close_connection()


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Scalable SaaS backend for NLP-driven customer feedback intelligence.",
    lifespan=lifespan,
    debug=settings.DEBUG,
)

# ---------------------------------------------------------------------------
# CORS Configuration
# ---------------------------------------------------------------------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Global Exception Handlers
# ---------------------------------------------------------------------------
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch unhandled exceptions and return standard API envelope."""
    logger.exception("Unhandled error on %s %s: %s", request.method, request.url.path, exc)
    return JSONResponse(
        status_code=500,
        content=APIResponse(
            success=False,
            message="An unexpected internal server error occurred."
        ).model_dump(),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Catch pydantic validation errors and return standard API envelope."""
    logger.warning("Validation error on %s %s: %s", request.method, request.url.path, exc)
    return JSONResponse(
        status_code=422,
        content=APIResponse(
            success=False,
            message=f"Invalid request data: {exc.errors()}"
        ).model_dump(),
    )


# ---------------------------------------------------------------------------
# Core / Utility Routes
# ---------------------------------------------------------------------------
@app.get("/health", tags=["System"], response_model=APIResponse[dict])
async def health_check():
    """Health-check endpoint for orchestrators (k8s/docker)."""
    return APIResponse(
        success=True,
        data={
            "status": "healthy",
            "version": settings.APP_VERSION,
            "environment": "dev" if settings.DEBUG else "production",
        },
        message="InsightHub system is operational."
    )


@app.delete("/reset", tags=["System"], response_model=APIResponse[dict])
async def reset_database():
    """Clear all reviews (for testing purposes)."""
    if not settings.DEBUG:
        # In actual production, block this or require super-admin roles
        pass
    deleted_count = reviews_repo.delete_all()
    return APIResponse(
        success=True,
        data={"deleted": deleted_count},
        message="Database reset successfully."
    )


# ---------------------------------------------------------------------------
# Register core routers
# ---------------------------------------------------------------------------
app.include_router(upload_router, tags=["Data Ingestion"])
app.include_router(analysis_router, tags=["Analytics"])


# ---------------------------------------------------------------------------
# Startup Event
# ---------------------------------------------------------------------------
@app.on_event("startup")
async def startup_event():
    """Initialize application resources on startup."""
    logger.info("✅ InsightHub API started successfully")
    logger.info(f"📊 API Documentation: http://localhost:8000/docs")


# ---------------------------------------------------------------------------
# Shutdown Event
# ---------------------------------------------------------------------------
@app.on_event("shutdown")
async def shutdown_event():
    """Clean up resources on shutdown."""
    logger.info("🔴 InsightHub API shutdown")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
    )
