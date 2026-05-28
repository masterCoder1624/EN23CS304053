"""
Enhanced CSV Parsing Service.

Reads an uploaded CSV file, validates structure, extracts the 'review' column,
and returns cleaned review strings with comprehensive error handling.
"""

import csv
import logging
from io import BytesIO, StringIO
from typing import List

import pandas as pd
from fastapi import HTTPException

logger = logging.getLogger(__name__)


def _detect_delimiter(file_bytes: bytes) -> str:
    """
    Auto-detect the CSV delimiter using csv.Sniffer.

    Supports comma, semicolon, tab, and pipe delimiters.
    Falls back to comma if detection fails.
    """
    try:
        # Decode and read a sample of the file for sniffing
        sample = file_bytes[:8192].decode("utf-8", errors="replace")
        dialect = csv.Sniffer().sniff(sample, delimiters=",;\t|")
        detected = dialect.delimiter
        logger.info("Auto-detected CSV delimiter: %r", detected)
        return detected
    except csv.Error:
        logger.info("Could not detect delimiter, defaulting to comma")
        return ","


def parse_csv(file_bytes: bytes) -> List[str]:
    """
    Parse raw CSV bytes and return a list of sanitized review strings.

    Args:
        file_bytes: Raw bytes of the uploaded CSV file.

    Returns:
        List of cleaned review texts.

    Raises:
        HTTPException:
            - 400 if CSV cannot be parsed
            - 400 if 'review' column not found
            - 400 if all reviews are empty
    """
    # ─────────────────────────────────────────────────────────────────
    # 1. Detect delimiter and read CSV
    # ─────────────────────────────────────────────────────────────────
    
    delimiter = _detect_delimiter(file_bytes)
    
    try:
        df = pd.read_csv(BytesIO(file_bytes), sep=delimiter)
    except pd.errors.ParserError as exc:
        logger.warning("CSV parsing error: %s", exc)
        raise HTTPException(
            status_code=400,
            detail=f"Invalid CSV format: {exc}",
        )
    except Exception as exc:
        logger.warning("Unexpected error reading CSV: %s", exc)
        raise HTTPException(
            status_code=400,
            detail=f"Failed to read CSV file: {exc}",
        )

    # ─────────────────────────────────────────────────────────────────
    # 2. Normalize column names
    # ─────────────────────────────────────────────────────────────────
    
    original_cols = df.columns.tolist()
    df.columns = df.columns.str.strip().str.lower()
    
    logger.debug("Original columns: %s", original_cols)
    logger.debug("Normalized columns: %s", df.columns.tolist())

    # ─────────────────────────────────────────────────────────────────
    # 3. Validate required column exists
    # ─────────────────────────────────────────────────────────────────
    
    if "review" not in df.columns:
        logger.error(
            "Required 'review' column not found. Available columns: %s",
            list(df.columns)
        )
        raise HTTPException(
            status_code=400,
            detail=(
                "CSV must contain a 'review' column (case-insensitive). "
                f"Found columns: {list(df.columns)}"
            ),
        )

    # ─────────────────────────────────────────────────────────────────
    # 4. Extract and clean reviews
    # ─────────────────────────────────────────────────────────────────
    
    reviews = (
        df["review"]
        .astype(str)
        .str.strip()
        .dropna()
        .loc[lambda s: s != ""]
        .tolist()
    )

    logger.info(
        "Extracted %d non-empty reviews from %d rows",
        len(reviews),
        len(df)
    )

    # ─────────────────────────────────────────────────────────────────
    # 5. Validate we have reviews
    # ─────────────────────────────────────────────────────────────────
    
    if not reviews:
        logger.warning("No valid reviews found in CSV")
        raise HTTPException(
            status_code=400,
            detail="The 'review' column is empty — no reviews to process.",
        )

    # ─────────────────────────────────────────────────────────────────
    # 6. Additional validation
    # ─────────────────────────────────────────────────────────────────
    
    # Check for minimum review length
    min_length = 5
    valid_reviews = [r for r in reviews if len(r) >= min_length]
    
    if len(valid_reviews) < len(reviews):
        logger.debug(
            "Filtered out %d reviews shorter than %d characters",
            len(reviews) - len(valid_reviews),
            min_length
        )
        reviews = valid_reviews

    logger.info("Successfully validated and parsed %d reviews", len(reviews))
    return reviews
