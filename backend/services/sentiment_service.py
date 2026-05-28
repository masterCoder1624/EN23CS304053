"""
Enhanced Sentiment Analysis Service.

Encapsulates sentiment classification using TextBlob.
Configurable polarity thresholds for customized classification.
"""

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from textblob import TextBlob

logger = logging.getLogger(__name__)


class SentimentService:
    """
    Service for sentiment classification and analysis.
    
    Uses TextBlob for sentiment polarity analysis and classifies
    into positive, negative, or neutral categories.
    """
    
    # Configurable thresholds
    POLARITY_POSITIVE_THRESHOLD = 0.1
    POLARITY_NEGATIVE_THRESHOLD = -0.1

    @staticmethod
    def _classify_polarity(polarity: float) -> str:
        """
        Map a TextBlob polarity value to a sentiment label.
        
        Args:
            polarity: Float between -1 and 1 from TextBlob sentiment
        
        Returns:
            Sentiment label: "positive", "negative", or "neutral"
        
        Classification:
            - polarity > 0.1: positive
            - polarity < -0.1: negative
            - -0.1 <= polarity <= 0.1: neutral
        """
        if polarity > SentimentService.POLARITY_POSITIVE_THRESHOLD:
            return "positive"
        elif polarity < SentimentService.POLARITY_NEGATIVE_THRESHOLD:
            return "negative"
        return "neutral"

    def analyze(
        self,
        reviews: List[str],
        product_id: str = "default"
    ) -> List[Dict[str, Any]]:
        """
        Run sentiment analysis on a list of review strings.
        
        Args:
            reviews: List of review text strings
            product_id: Product identifier (for multi-product support)

        Returns:
            List of dictionaries with analyzed sentiment data:
            - product_id (str): Product identifier
            - text (str): Original review text
            - sentiment (str): Sentiment classification
            - polarity (float): Numeric polarity score
            - created_at (datetime): Analysis timestamp
        
        Raises:
            ValueError: If reviews list is empty
        """
        if not reviews:
            logger.warning("Empty reviews list provided for sentiment analysis")
            raise ValueError("Reviews list cannot be empty")
        
        logger.info(
            "Running sentiment analysis for %d reviews (product: %s)",
            len(reviews),
            product_id
        )
        
        results: List[Dict[str, Any]] = []
        errors = 0

        for idx, text in enumerate(reviews):
            try:
                blob = TextBlob(text)
                polarity = round(blob.sentiment.polarity, 4)
                label = self._classify_polarity(polarity)

                results.append(
                    {
                        "product_id": product_id,
                        "text": text,
                        "sentiment": label,
                        "polarity": polarity,
                        "created_at": datetime.utcnow(),
                    }
                )
            except Exception as exc:
                logger.warning(
                    "Failed to analyze review %d: %s", idx + 1, exc
                )
                errors += 1
                # Continue with next review instead of failing completely
                continue

        if errors > 0:
            logger.warning(
                "Failed to analyze %d/%d reviews",
                errors,
                len(reviews)
            )

        logger.info(
            "Successfully analyzed %d reviews (distribution: "
            "%d positive, %d negative, %d neutral)",
            len(results),
            sum(1 for r in results if r["sentiment"] == "positive"),
            sum(1 for r in results if r["sentiment"] == "negative"),
            sum(1 for r in results if r["sentiment"] == "neutral"),
        )

        return results

    @staticmethod
    def get_sentiment_stats(analyzed_results: List[Dict[str, Any]]) -> Dict[str, int]:
        """
        Get sentiment distribution statistics.
        
        Args:
            analyzed_results: List of analyzed result dictionaries
        
        Returns:
            Dictionary with counts of each sentiment type
        """
        return {
            "positive": sum(1 for r in analyzed_results if r["sentiment"] == "positive"),
            "negative": sum(1 for r in analyzed_results if r["sentiment"] == "negative"),
            "neutral": sum(1 for r in analyzed_results if r["sentiment"] == "neutral"),
        }


# Singleton instance
sentiment_service = SentimentService()
