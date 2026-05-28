"""
Enhanced Reviews Repository — database abstraction layer.

Encapsulates every MongoDB operation for the reviews collection.
No other module should import pymongo directly for CRUD work.

Provides:
- Insert operations
- Query and fetch operations
- Delete operations
- Comprehensive error handling and logging
- Foundation for pagination and filtering
"""

import logging
from typing import Any, Dict, List, Optional

from pymongo.collection import Collection
from pymongo.errors import PyMongoError

from backend.core.config import settings
from backend.db.mongodb import get_database

logger = logging.getLogger(__name__)


class ReviewsRepository:
    """
    Data-access object for the *reviews* collection.
    
    Encapsulates all database operations and provides a clean interface
    for the application layer. No raw PyMongo operations outside this class.
    """

    def __init__(self) -> None:
        self._collection: Optional[Collection] = None

    @property
    def collection(self) -> Collection:
        """
        Lazy-load the collection reference.
        
        Returns:
            MongoDB collection reference
        """
        if self._collection is None:
            self._collection = get_database()[settings.REVIEWS_COLLECTION]
            logger.debug(
                "Initialized collection: %s.%s",
                settings.DATABASE_NAME,
                settings.REVIEWS_COLLECTION
            )
        return self._collection

    # ────────────────────────────────────────────────────────────────
    # INSERT OPERATIONS
    # ────────────────────────────────────────────────────────────────

    def insert_many(self, documents: List[Dict[str, Any]]) -> int:
        """
        Bulk-insert review documents into MongoDB.

        Args:
            documents: List of review documents ready for database insertion.

        Returns:
            Number of documents successfully inserted.

        Raises:
            RuntimeError: If database operation fails.
        """
        if not documents:
            logger.warning("Empty documents list provided for insertion")
            return 0
        
        try:
            logger.debug("Inserting %d documents into %s", len(documents), self.collection.name)
            result = self.collection.insert_many(documents, ordered=False)
            count = len(result.inserted_ids)
            logger.info("✅ Inserted %d reviews into MongoDB.", count)
            return count
        except PyMongoError as exc:
            logger.error("❌ MongoDB insert_many failed: %s", exc)
            raise RuntimeError(f"Database insert failed: {exc}") from exc

    # ────────────────────────────────────────────────────────────────
    # FETCH OPERATIONS
    # ────────────────────────────────────────────────────────────────

    def fetch_all(
        self,
        product_id: Optional[str] = None,
        projection: Optional[Dict] = None,
        limit: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Fetch all reviews, optionally filtered by product_id.
        
        Supports filtering for multi-product scenarios and
        optional pagination for future scalability.

        Args:
            product_id: Optional product ID to filter by.
            projection: MongoDB projection dict (e.g., {"_id": 0}).
                       Defaults to excluding _id field.
            limit: Optional limit on number of documents to return.

        Returns:
            List of review documents.

        Raises:
            RuntimeError: If database operation fails.
        """
        query: Dict[str, Any] = {}
        if product_id:
            query["product_id"] = product_id
            logger.debug("Fetching reviews for product: %s", product_id)
        else:
            logger.debug("Fetching all reviews")

        proj = projection or {"_id": 0}

        try:
            cursor = self.collection.find(query, proj)
            if limit:
                cursor = cursor.limit(limit)
            
            results = list(cursor)
            logger.info(
                "Fetched %d reviews (product_id: %s)",
                len(results),
                product_id or "all"
            )
            return results
        except PyMongoError as exc:
            logger.error("❌ MongoDB fetch_all failed: %s", exc)
            raise RuntimeError(f"Database read failed: {exc}") from exc

    def count(self, product_id: Optional[str] = None) -> int:
        """
        Return the count of stored reviews.
        
        Args:
            product_id: Optional product ID to filter count.

        Returns:
            Number of reviews matching the query.
        """
        query: Dict[str, Any] = {}
        if product_id:
            query["product_id"] = product_id
        
        try:
            count = self.collection.count_documents(query)
            logger.debug("Review count: %d", count)
            return count
        except PyMongoError as exc:
            logger.error("❌ MongoDB count failed: %s", exc)
            return 0

    def fetch_by_sentiment(
        self,
        sentiment: str,
        product_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Fetch reviews filtered by sentiment.
        
        Args:
            sentiment: Sentiment value (positive, negative, neutral).
            product_id: Optional product ID filter.
        
        Returns:
            List of matching reviews.
        """
        query: Dict[str, Any] = {"sentiment": sentiment}
        if product_id:
            query["product_id"] = product_id
        
        try:
            results = list(self.collection.find(query, {"_id": 0}))
            logger.info(
                "Fetched %d %s reviews",
                len(results),
                sentiment
            )
            return results
        except PyMongoError as exc:
            logger.error("❌ Failed to fetch %s reviews: %s", sentiment, exc)
            return []

    # ────────────────────────────────────────────────────────────────
    # DELETE OPERATIONS
    # ────────────────────────────────────────────────────────────────

    def delete_all(self, product_id: Optional[str] = None) -> int:
        """
        Delete all reviews, optionally filtered by product_id.
        
        **Warning**: This is a destructive operation. Use with caution.
        Currently only available in DEBUG mode for testing.

        Args:
            product_id: Optional product ID to delete only that product's reviews.

        Returns:
            Number of documents deleted.

        Raises:
            RuntimeError: If database operation fails.
        """
        query: Dict[str, Any] = {}
        if product_id:
            query["product_id"] = product_id
            logger.warning(
                "⚠️  Deleting all reviews for product: %s",
                product_id
            )
        else:
            logger.warning("⚠️  Deleting ALL reviews from database!")
        
        try:
            result = self.collection.delete_many(query)
            logger.info("✅ Deleted %d reviews.", result.deleted_count)
            return result.deleted_count
        except PyMongoError as exc:
            logger.error("❌ MongoDB delete_all failed: %s", exc)
            raise RuntimeError(f"Database delete failed: {exc}") from exc

    def delete_by_sentiment(self, sentiment: str) -> int:
        """
        Delete reviews by sentiment (for cleanup purposes).
        
        Args:
            sentiment: Sentiment to delete (positive, negative, neutral).
        
        Returns:
            Number of documents deleted.
        """
        logger.warning("Deleting all %s reviews", sentiment)
        try:
            result = self.collection.delete_many({"sentiment": sentiment})
            logger.info("Deleted %d %s reviews", result.deleted_count, sentiment)
            return result.deleted_count
        except PyMongoError as exc:
            logger.error("Failed to delete %s reviews: %s", sentiment, exc)
            return 0

    # ────────────────────────────────────────────────────────────────
    # UTILITY OPERATIONS
    # ────────────────────────────────────────────────────────────────

    def create_indexes(self) -> None:
        """
        Create database indexes for optimized queries.
        
        Should be called during application initialization
        for better query performance.
        """
        try:
            logger.info("Creating database indexes...")
            self.collection.create_index("product_id")
            self.collection.create_index("sentiment")
            self.collection.create_index("created_at")
            logger.info("✅ Indexes created successfully")
        except PyMongoError as exc:
            logger.warning("Failed to create indexes: %s", exc)


# Singleton instance — import this in routes / services
reviews_repo = ReviewsRepository()
