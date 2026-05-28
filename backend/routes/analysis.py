"""
Enhanced Analysis API Route.

Fetches data via the repository layer, orchestrates insight generation,
and supports product filtering for multi-product scalability.
"""

import logging
from typing import Optional

from fastapi import APIRouter, Query

from backend.models.response_model import APIResponse, DashboardInsights
from backend.repositories.reviews_repository import reviews_repo
from backend.services.insight_service import insight_service

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/insights", response_model=APIResponse[DashboardInsights], tags=["Analytics"])
async def get_insights(
    product_id: Optional[str] = Query(
        None,
        description="Optional product ID to filter insights by product"
    )
):
    """
    Retrieve comprehensive analytics for all reviews.

    Returns:
    - total_reviews: Total number of reviews processed
    - sentiment: Distribution of positive/negative/neutral sentiments
    - issues: Detected product issues with severity levels
    - top_keywords: Most important keywords from reviews (TF-IDF)
    - ai_insights: AI-generated narrative about what users love and complain about
    
    Query Parameters:
    - product_id: Optional filter to get insights for a specific product
    
    Example: `/insights?product_id=phone_x1`
    """
    
    logger.info(
        "Fetching insights (product_id: %s)",
        product_id or "all"
    )
    
    try:
        # Use repository layer instead of hardcoded PyMongo code
        reviews = reviews_repo.fetch_all(product_id=product_id)
        logger.debug("Retrieved %d reviews from database", len(reviews))

        # Pass to the service layer for aggregation and analysis
        insights = insight_service.build_dashboard_insights(reviews)
        
        logger.info(
            "Generated insights for %d reviews (positive: %d, negative: %d, neutral: %d)",
            insights.total_reviews,
            insights.sentiment.positive,
            insights.sentiment.negative,
            insights.sentiment.neutral,
        )
        
        return APIResponse(
            success=True,
            data=insights,
            message="Insights generated successfully."
        )
    
    except Exception as exc:
        logger.exception("Failed to generate insights: %s", exc)
        raise


@router.get("/insights/summary", tags=["Analytics"])
async def get_insights_summary(
    product_id: Optional[str] = Query(None, description="Optional product ID filter")
):
    """
    Get a quick summary of analytics without detailed breakdown.
    
    Returns only:
    - total_reviews
    - sentiment distribution
    - top 3 issues
    
    Useful for lightweight summary displays.
    """
    
    logger.info("Fetching insights summary (product_id: %s)", product_id or "all")
    
    try:
        reviews = reviews_repo.fetch_all(product_id=product_id)
        insights = insight_service.build_dashboard_insights(reviews)
        
        # Return only essential fields
        summary = {
            "total_reviews": insights.total_reviews,
            "sentiment": insights.sentiment,
            "top_issues": insights.issues[:3],  # Only top 3
        }
        
        return APIResponse(
            success=True,
            data=summary,
            message="Summary generated successfully."
        )
    
    except Exception as exc:
        logger.exception("Failed to generate summary: %s", exc)
        raise


@router.post("/insights/refresh", tags=["Analytics"])
async def refresh_insights(
    product_id: Optional[str] = Query(None, description="Optional product ID filter")
):
    """
    Manually trigger a refresh of cached insights.
    
    In a production system, this would clear caches and regenerate.
    Currently demonstrates the pattern for cache invalidation.
    """
    
    logger.info("Refreshing insights cache (product_id: %s)", product_id or "all")
    
    try:
        # In production, this would clear distributed cache (Redis)
        # For now, just regenerate fresh insights
        reviews = reviews_repo.fetch_all(product_id=product_id)
        insights = insight_service.build_dashboard_insights(reviews)
        
        return APIResponse(
            success=True,
            data=insights,
            message="Insights refreshed successfully."
        )
    
    except Exception as exc:
        logger.exception("Failed to refresh insights: %s", exc)
        raise
