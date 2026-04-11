"""URL validation and price formatting utilities."""

import re
from app.models import Platform


def detect_platform(url: str) -> Platform:
    """Detect e-commerce platform from URL."""
    url_lower = url.lower()
    if "amazon" in url_lower:
        return Platform.AMAZON
    elif "flipkart" in url_lower:
        return Platform.FLIPKART
    elif "myntra" in url_lower:
        return Platform.MYNTRA
    elif "ebay" in url_lower:
        return Platform.EBAY
    return Platform.UNKNOWN


def is_valid_product_url(url: str) -> bool:
    """Check if the URL is a valid Amazon.in or Flipkart product URL."""
    patterns = [
        r"https?://(www\.)?amazon\.(in|com)/.*",
        r"https?://(www\.)?flipkart\.com/.*",
        r"https?://dl\.flipkart\.com/.*",
        r"https?://(www\.)?myntra\.com/.*",
        r"https?://(www\.)?ebay\.(com|in|co\.uk)/.*",
    ]
    return any(re.match(p, url) for p in patterns)


def format_price(price: float, currency: str = "₹") -> str:
    """Format price with currency and Indian comma system."""
    if price >= 10_000_000:
        return f"{currency}{price / 10_000_000:.2f} Cr"
    if price >= 100_000:
        return f"{currency}{price / 100_000:.2f} L"
    # Indian number system
    price_str = f"{price:,.2f}"
    return f"{currency}{price_str}"


def extract_price_from_text(text: str) -> float:
    """Extract numeric price from text like '₹12,999' → 12999.0."""
    cleaned = re.sub(r"[₹,\s]", "", text)
    match = re.search(r"[\d.]+", cleaned)
    if match:
        return float(match.group())
    raise ValueError(f"Could not extract price from: {text}")
