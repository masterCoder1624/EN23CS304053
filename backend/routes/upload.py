"""
Enhanced Upload API Route.

Handles async CSV ingestion with robust validation, error handling,
background processing, and comprehensive logging.
"""

import logging
import uuid
from typing import List

from fastapi import APIRouter, BackgroundTasks, File, HTTPException, UploadFile

from backend.core.config import settings
from backend.models.response_model import APIResponse, UploadResponse
from backend.repositories.reviews_repository import reviews_repo
from backend.services.csv_parser import parse_csv
from backend.services.sentiment_service import sentiment_service
from backend.services.topic_service import topic_service

logger = logging.getLogger(__name__)

router = APIRouter()

# In-memory job tracking (can be extended to Redis for scalability)
job_status: dict = {}


def process_reviews_background(job_id: str, reviews_text: List[str], product_id: str = "default") -> None:
    """
    Background task to run heavy NLP pipeline.
    
    This runs asynchronously to avoid blocking the API response.
    Processes sentiment analysis, topic extraction, and database insertion.
    """
    job_status[job_id] = {"status": "processing", "progress": 0}
    
    try:
        logger.info(
            "[Job %s] Starting processing for %d reviews (product: %s)",
            job_id, len(reviews_text), product_id
        )
        
        # 1. Classify sentiment
        logger.debug("[Job %s] Running sentiment analysis...", job_id)
        processed = sentiment_service.analyze(reviews_text, product_id=product_id)
        job_status[job_id]["progress"] = 33
        
        # 2. Extract topics into the same dicts
        logger.debug("[Job %s] Extracting topics...", job_id)
        topic_service.process_reviews_topics(processed)
        job_status[job_id]["progress"] = 66
        
        # 3. Save to DB layer
        logger.debug("[Job %s] Inserting to MongoDB...", job_id)
        inserted = reviews_repo.insert_many(processed)
        job_status[job_id]["progress"] = 100
        
        job_status[job_id]["status"] = "completed"
        logger.info(
            "[Job %s] Successfully processed and inserted %d reviews.",
            job_id, inserted
        )
    except Exception as exc:
        logger.exception("[Job %s] Background processing failed: %s", job_id, exc)
        job_status[job_id]["status"] = "failed"
        job_status[job_id]["error"] = str(exc)


@router.post("/upload", response_model=APIResponse[UploadResponse], tags=["Upload"])
async def upload_csv(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(..., description="CSV file with review column")
):
    """
    Upload and process a CSV file containing customer reviews.

    - **file**: CSV file with a required "review" column
    
    Returns:
    - job_id: Unique identifier to track processing status
    - status: Current job status (processing, completed, failed)
    - reviews_processed: Number of reviews queued for analysis
    
    Example CSV format:
    ```
    review
    "Great product!"
    "Poor quality"
    "Amazing service"
    ```
    """
    
    # ─────────────────────────────────────────────────────────────────────
    # Validation
    # ─────────────────────────────────────────────────────────────────────
    
    # 1. Check file type
    if file.content_type not in (
        "text/csv",
        "application/vnd.ms-excel",
        "application/octet-stream",
    ):
        logger.warning(
            "Invalid file type '%s' uploaded", file.content_type
        )
        raise HTTPException(
            status_code=400,
            detail=(
                f"Invalid file type '{file.content_type}'. "
                "Please upload a CSV file."
            ),
        )

    # 2. Check file size
    max_size_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if file.size and file.size > max_size_bytes:
        logger.warning(
            "File size %d exceeds limit of %d bytes",
            file.size, max_size_bytes
        )
        raise HTTPException(
            status_code=413,
            detail=(
                f"File size exceeds limit of "
                f"{settings.MAX_UPLOAD_SIZE_MB}MB"
            ),
        )

    # ─────────────────────────────────────────────────────────────────────
    # Parse and validate CSV
    # ─────────────────────────────────────────────────────────────────────
    
    try:
        contents = await file.read()
        reviews = parse_csv(contents)
        logger.info("Successfully parsed CSV with %d reviews", len(reviews))
    except HTTPException:
        raise
    except Exception as exc:
        logger.exception("CSV parsing failed: %s", exc)
        raise HTTPException(
            status_code=400,
            detail=f"Failed to parse CSV: {str(exc)}"
        )

    # ─────────────────────────────────────────────────────────────────────
    # Queue for background processing
    # ─────────────────────────────────────────────────────────────────────
    
    job_id = str(uuid.uuid4())
    product_id = "default"  # Can be extended to support multi-product
    
    # Track job in memory
    job_status[job_id] = {
        "status": "pending",
        "reviews_count": len(reviews),
        "product_id": product_id,
    }
    
    # Schedule background processing
    background_tasks.add_task(
        process_reviews_background,
        job_id,
        reviews,
        product_id
    )

    logger.info(
        "Queued job %s for processing %d reviews", job_id, len(reviews)
    )

    return APIResponse(
        success=True,
        data=UploadResponse(
            job_id=job_id,
            status="processing",
            reviews_processed=len(reviews),
        ),
        message="File uploaded successfully. Processing started in the background."
    )


@router.get("/upload/status/{job_id}", tags=["Upload"])
async def get_upload_status(job_id: str):
    """
    Get the status of an upload job.
    
    - **job_id**: The job ID returned from the upload endpoint
    """
    if job_id not in job_status:
        raise HTTPException(
            status_code=404,
            detail=f"Job {job_id} not found"
        )
    
    status_info = job_status[job_id]
    return APIResponse(
        success=True,
        data=status_info,
        message=f"Job status: {status_info.get('status', 'unknown')}"
    )
