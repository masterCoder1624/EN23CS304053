"""
Pydantic data models for reviews and API responses.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class ReviewModel(BaseModel):
    """Schema for a single processed review stored in MongoDB."""

    product_id: str = Field(
        default="default", description="Partitioning identifier to group reviews"
    )
    text: str = Field(..., description="Original review text")
    sentiment: str = Field(
        ..., description="Sentiment label: positive | negative | neutral"
    )
    topics: List[str] = Field(
        default_factory=list, description="Detected topic tags"
    )
    created_at: datetime = Field(
        default_factory=datetime.utcnow,
        description="Timestamp when the review was processed",
    )

    class Config:
        json_schema_extra = {
            "example": {
                "product_id": "default",
                "text": "Battery life is amazing but the camera quality is poor.",
                "sentiment": "positive",
                "topics": ["battery", "camera"],
                "created_at": "2026-04-14T10:00:00Z",
            }
        }


class UploadResponse(BaseModel):
    """Response returned after a successful CSV upload."""

    success: bool
    message: str
    reviews_processed: int


class IssueItem(BaseModel):
    """A single detected issue."""

    topic: str
    frequency: int
    severity: str  # high | medium | low


class AIInsights(BaseModel):
    """AI-generated narrative insights."""

    what_users_love: List[str]
    main_complaints: List[str]
    summary: str


class InsightsResponse(BaseModel):
    """Full analytics response for the /insights endpoint."""

    total_reviews: int
    sentiment: dict  # {"positive": N, "negative": N, "neutral": N}
    issues: List[IssueItem]
    ai_insights: AIInsights
