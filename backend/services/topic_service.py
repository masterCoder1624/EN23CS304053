"""
Enhanced Topic Analysis Service.

Consolidates keyword-based topic extraction, TF-IDF topic modeling,
issue severity detection, and optional in-memory caching.
"""

import logging
from collections import Counter
from typing import Any, Dict, List, Optional

from sklearn.feature_extraction.text import TfidfVectorizer

logger = logging.getLogger(__name__)

# Topics and associated keyword indicators
# Can be extended with domain-specific keywords
TOPIC_KEYWORDS: Dict[str, List[str]] = {
    "battery": [
        "battery", "charge", "charging", "power", "drain", "mah",
        "battery life", "power bank", "endurance"
    ],
    "performance": [
        "performance", "speed", "fast", "slow", "lag", "laggy",
        "hang", "smooth", "processor", "ram", "benchmark", "fps"
    ],
    "camera": [
        "camera", "photo", "picture", "video", "lens", "selfie",
        "megapixel", "mp", "zoom", "portrait", "night mode"
    ],
    "heating": [
        "heat", "heating", "hot", "overheat", "temperature",
        "warm", "thermal", "overheat"
    ],
    "software": [
        "software", "update", "bug", "crash", "os", "ui", "interface",
        "app", "bloatware", "android", "ios", "firmware"
    ],
}

# In-memory cache for TF-IDF models (can be extended to Redis)
_tfidf_cache: Dict[str, Any] = {}


class TopicService:
    """
    Service combining topic extraction, issue detection, and keyword analysis.
    
    Features:
    - Keyword-based topic extraction
    - TF-IDF based keyword ranking
    - Severity level classification
    - Optional caching for performance
    """

    def extract_topics(self, text: str) -> List[str]:
        """
        Identify topics mentioned in a single review.
        
        Args:
            text: Review text to analyze
        
        Returns:
            List of detected topics
        """
        lower_text = text.lower()
        matched: List[str] = []

        for topic, keywords in TOPIC_KEYWORDS.items():
            if any(kw in lower_text for kw in keywords):
                matched.append(topic)

        return matched

    def process_reviews_topics(
        self,
        reviews: List[Dict[str, Any]]
    ) -> None:
        """
        In-place update of review dictionaries with detected topics.
        
        Args:
            reviews: List of review dictionaries to update
        """
        for idx, result in enumerate(reviews):
            try:
                if "topics" not in result or not result["topics"]:
                    result["topics"] = self.extract_topics(result["text"])
            except Exception as exc:
                logger.warning(
                    "Failed to extract topics from review %d: %s", idx, exc
                )
                result["topics"] = []

    def extract_top_keywords(
        self,
        reviews: List[str],
        top_n: int = 10,
        max_features: int = 500
    ) -> List[str]:
        """
        Extract the top-N keywords from a corpus using TF-IDF.
        
        Args:
            reviews: List of review texts
            top_n: Number of top keywords to return (default: 10)
            max_features: Max features for TF-IDF vectorizer
        
        Returns:
            List of top keywords
        """
        if not reviews:
            logger.warning("Empty reviews list for keyword extraction")
            return []

        try:
            logger.debug(
                "Extracting top %d keywords from %d reviews",
                top_n, len(reviews)
            )
            
            vectorizer = TfidfVectorizer(
                max_features=max_features,
                stop_words="english",
                ngram_range=(1, 2),
                min_df=2,
                max_df=0.9,
            )

            tfidf_matrix = vectorizer.fit_transform(reviews)
            
            if tfidf_matrix.shape[0] == 0:
                logger.warning("TF-IDF matrix is empty")
                return []

            scores = tfidf_matrix.sum(axis=0).A1
            feature_names = vectorizer.get_feature_names_out()

            ranked_indices = scores.argsort()[::-1][:top_n]
            keywords = [feature_names[i] for i in ranked_indices]
            
            logger.debug("Extracted keywords: %s", keywords)
            return keywords
            
        except ValueError as exc:
            logger.warning("TF-IDF extraction failed: %s", exc)
            return []
        except Exception as exc:
            logger.exception("Unexpected error in keyword extraction: %s", exc)
            return []

    def detect_issues(
        self,
        reviews: List[Dict[str, Any]],
        min_frequency: int = 2
    ) -> List[Dict[str, Any]]:
        """
        Detect product issues from negative reviews and assign severity.
        
        Args:
            reviews: List of review dictionaries
            min_frequency: Minimum mentions to report as issue
        
        Returns:
            List of issues with frequency and severity
        
        Severity levels:
            - high: Mentioned 6+ times
            - medium: Mentioned 3-5 times
            - low: Mentioned 1-2 times
        """
        negative_reviews = [
            r for r in reviews
            if r.get("sentiment") == "negative"
        ]

        if not negative_reviews:
            logger.info("No negative reviews to analyze for issues")
            return []

        logger.info(
            "Analyzing %d negative reviews for issues",
            len(negative_reviews)
        )

        topic_counter: Counter = Counter()
        
        for review in negative_reviews:
            topics = review.get("topics") or self.extract_topics(review["text"])
            for topic in topics:
                topic_counter[topic] += 1

        issues: List[Dict[str, Any]] = []
        
        for topic, freq in topic_counter.most_common():
            if freq >= min_frequency:
                # Classify severity
                if freq > 5:
                    severity = "high"
                elif freq > 2:
                    severity = "medium"
                else:
                    severity = "low"

                issues.append({
                    "topic": topic,
                    "frequency": freq,
                    "severity": severity,
                })

        logger.info("Detected %d issues from negative reviews", len(issues))
        return issues


# Singleton instance
topic_service = TopicService()
