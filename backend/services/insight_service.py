"""
Enhanced Insights Orchestration Service.

Combines AI narrative generation and aggregates the dashboard response.
Uses TopicService internally for topic extraction and issue detection.
Provides comprehensive analytics for the dashboard.
"""

import logging
from collections import Counter
from typing import Any, Dict, List

from backend.models.response_model import DashboardInsights
from backend.services.topic_service import topic_service

logger = logging.getLogger(__name__)


class InsightService:
    """
    Service to generate dashboard analytics and AI narrative summaries.
    
    Orchestrates multiple analysis services to provide comprehensive
    insights about customer feedback.
    """

    @staticmethod
    def _top_items(counter: Counter, n: int = 5) -> List[str]:
        """
        Return the top-N items from a counter.
        
        Args:
            counter: Counter object with items and frequencies
            n: Number of top items to return
        
        Returns:
            List of top N items
        """
        return [item for item, _ in counter.most_common(n)]

    def generate_ai_narrative(
        self,
        reviews: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Produce AI-generated narrative insights from processed reviews.
        
        Analyzes topics in positive and negative reviews to generate
        human-readable narratives about what users love and complain about.
        
        Args:
            reviews: List of processed review dictionaries
        
        Returns:
            Dictionary with:
            - what_users_love: Top positive topics
            - main_complaints: Top negative topics
            - summary: Generated narrative
        """
        positive_topics: Counter = Counter()
        negative_topics: Counter = Counter()

        for review in reviews:
            topics = review.get("topics") or topic_service.extract_topics(
                review["text"]
            )
            sentiment = review.get("sentiment", "neutral")

            if sentiment == "positive":
                for t in topics:
                    positive_topics[t] += 1
            elif sentiment == "negative":
                for t in topics:
                    negative_topics[t] += 1

        loved = self._top_items(positive_topics)
        complaints = self._top_items(negative_topics)

        # Generate summary
        if loved and complaints:
            summary = (
                f"Users appreciate {', '.join(loved)} but frequently complain "
                f"about {', '.join(complaints)}. Focusing on the top complaints "
                f"could significantly improve overall customer satisfaction."
            )
        elif loved:
            summary = (
                f"Users overwhelmingly appreciate {', '.join(loved)}. "
                "No significant complaints were detected."
            )
        elif complaints:
            summary = (
                f"Users frequently complain about {', '.join(complaints)}. "
                "Addressing these issues should be the top priority."
            )
        else:
            summary = (
                "Not enough topical data to generate detailed insights. "
                "Consider collecting more reviews."
            )

        logger.info(
            "Generated AI narrative with %d positive topics and %d negative topics",
            len(loved),
            len(complaints)
        )

        return {
            "what_users_love": loved,
            "main_complaints": complaints,
            "summary": summary,
        }

    def build_dashboard_insights(
        self,
        reviews: List[Dict[str, Any]]
    ) -> DashboardInsights:
        """
        Aggregate all analytics for a set of processed reviews.
        
        This is the main entry point that orchestrates all analysis services
        to produce the complete dashboard response.
        
        Args:
            reviews: List of processed review dictionaries
        
        Returns:
            Dictionary with complete dashboard data:
            - total_reviews: Total count
            - sentiment: Distribution
            - issues: Detected issues
            - top_keywords: TF-IDF keywords
            - ai_insights: Generated insights
        """
        total = len(reviews)
        
        logger.info("Building dashboard insights for %d reviews", total)
        
        if total == 0:
            logger.info("No reviews available, returning empty dashboard")
            return DashboardInsights(
                total_reviews=0,
                sentiment={"positive": 0, "negative": 0, "neutral": 0},
                issues=[],
                top_keywords=[],
                ai_insights={
                    "what_users_love": [],
                    "main_complaints": [],
                    "summary": "No reviews found. Upload a CSV to get started.",
                },
            )

        # 1. Sentiment distribution
        sentiment_counter = Counter(
            r.get("sentiment", "neutral") for r in reviews
        )
        sentiment_distribution = {
            "positive": sentiment_counter.get("positive", 0),
            "negative": sentiment_counter.get("negative", 0),
            "neutral": sentiment_counter.get("neutral", 0),
        }
        logger.debug(
            "Sentiment distribution: %s", sentiment_distribution
        )

        # 2. Detect issues
        issues = topic_service.detect_issues(reviews)
        logger.debug("Detected %d issues", len(issues))

        # 3. Generate AI insights
        ai_insights = self.generate_ai_narrative(reviews)

        # 4. Extract top keywords
        texts = [r["text"] for r in reviews if r.get("text")]
        top_keywords = topic_service.extract_top_keywords(texts)
        logger.debug("Extracted %d top keywords", len(top_keywords))

        dashboard_data = {
            "total_reviews": total,
            "sentiment": sentiment_distribution,
            "issues": issues,
            "top_keywords": top_keywords,
            "ai_insights": ai_insights,
        }
        
        logger.info(
            "Built dashboard insights: %d reviews, %d positive, "
            "%d issues, %d keywords",
            total,
            sentiment_distribution["positive"],
            len(issues),
            len(top_keywords)
        )

        return DashboardInsights(**dashboard_data)


# Singleton instance
insight_service = InsightService()
