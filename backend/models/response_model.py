"""
Enhanced Data Models for InsightHub.

Comprehensive Pydantic models for requests, responses, and internal data structures.
Includes validation, examples, and support for multi-tenant scalability.
"""

from datetime import datetime
from typing import Any, Generic, List, Optional, TypeVar

from pydantic import BaseModel, Field, field_validator

DataT = TypeVar("DataT")




class APIResponse(BaseModel, Generic[DataT]):
    """
    Standard wrapper for all API responses.
    
    Provides consistency across all endpoints with success indicator,
    data payload, and optional message.
    """

    success: bool = Field(
        ..., description="Whether the operation was successful"
    )
    data: Optional[DataT] = Field(
        default=None, description="Response data payload"
    )
    message: Optional[str] = Field(
        default=None, description="Human-readable message"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "data": {"any": "payload"},
                "message": "Operation completed successfully.",
            }
        }


class ErrorResponse(BaseModel):
    """Standard error response structure."""
    
    success: bool = False
    message: str = Field(..., description="Error message")
    details: Optional[str] = Field(
        default=None, description="Additional error details"
    )


# ─────────────────────────────────────────────────────────────────────────
# Review Models (Database)
# ─────────────────────────────────────────────────────────────────────────

class ReviewDocument(BaseModel):
    """
    Document model for MongoDB reviews collection.
    Represents a processed customer review with all derived analytics.
    """

    product_id: str = Field(
        default="default",
        description="Product identifier for multi-product support"
    )
    text: str = Field(..., description="Original review text")
    sentiment: str = Field(
        ...,
        description="Sentiment classification: positive, negative, or neutral"
    )
    polarity: float = Field(
        ...,
        ge=-1.0,
        le=1.0,
        description="Polarity score from -1 to 1"
    )
    topics: List[str] = Field(
        default_factory=list,
        description="Extracted topics from review"
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Timestamp when review was created"
    )
    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Timestamp when review was last updated"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "product_id": "phone_x1",
                "text": "Amazing phone with great camera!",
                "sentiment": "positive",
                "polarity": 0.85,
                "topics": ["camera", "performance"],
                "created_at": "2026-04-14T10:30:00",
                "updated_at": "2026-04-14T10:30:00",
            }
        }


# ─────────────────────────────────────────────────────────────────────────
# Upload Request/Response Models
# ─────────────────────────────────────────────────────────────────────────

class UploadResponse(BaseModel):
    """Response from CSV upload endpoint."""
    
    job_id: str = Field(
        ..., description="Unique job identifier for tracking"
    )
    status: str = Field(
        default="processing",
        description="Job status: pending, processing, completed, failed"
    )
    reviews_processed: int = Field(
        ..., description="Number of reviews queued for processing"
    )
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Upload timestamp"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "job_id": "550e8400-e29b-41d4-a716-446655440000",
                "status": "processing",
                "reviews_processed": 145,
                "timestamp": "2026-04-14T10:30:00",
            }
        }


# ─────────────────────────────────────────────────────────────────────────
# Analytics Models
# ─────────────────────────────────────────────────────────────────────────

class SentimentDistribution(BaseModel):
    """Sentiment distribution statistics."""
    
    positive: int = Field(ge=0, description="Count of positive reviews")
    negative: int = Field(ge=0, description="Count of negative reviews")
    neutral: int = Field(ge=0, description="Count of neutral reviews")


class Issue(BaseModel):
    """Detected product issue from negative reviews."""
    
    topic: str = Field(..., description="Issue topic")
    frequency: int = Field(ge=1, description="How many times mentioned")
    severity: str = Field(
        ...,
        description="Severity level: low, medium, high"
    )


class AIInsights(BaseModel):
    """AI-generated narrative insights."""
    
    what_users_love: List[str] = Field(
        default_factory=list,
        description="Top positive aspects mentioned by users"
    )
    main_complaints: List[str] = Field(
        default_factory=list,
        description="Main complaints from negative reviews"
    )
    summary: str = Field(
        ...,
        description="Generated narrative summary of insights"
    )


class DashboardInsights(BaseModel):
    """Complete dashboard analytics response."""
    
    total_reviews: int = Field(ge=0, description="Total reviews processed")
    sentiment: SentimentDistribution = Field(
        ..., description="Sentiment distribution"
    )
    issues: List[Issue] = Field(
        default_factory=list,
        description="Detected product issues"
    )
    top_keywords: List[str] = Field(
        default_factory=list,
        description="Top TF-IDF keywords"
    )
    ai_insights: AIInsights = Field(
        ..., description="AI-generated insights"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "total_reviews": 150,
                "sentiment": {
                    "positive": 90,
                    "negative": 40,
                    "neutral": 20,
                },
                "issues": [
                    {
                        "topic": "battery",
                        "frequency": 25,
                        "severity": "high",
                    },
                ],
                "top_keywords": ["battery", "performance", "camera"],
                "ai_insights": {
                    "what_users_love": ["camera", "performance"],
                    "main_complaints": ["battery", "heating"],
                    "summary": "Users love the camera but complain about battery.",
                },
            }
        }


# ─────────────────────────────────────────────────────────────────────────
# Health Check Models
# ─────────────────────────────────────────────────────────────────────────

class HealthCheckData(BaseModel):
    """Health check response data."""
    
    status: str = Field(..., description="System status: healthy, degraded, unhealthy")
    version: str = Field(..., description="API version")
    environment: str = Field(..., description="Environment: dev, staging, production")
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Health check timestamp"
    )
