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
    elif "croma" in url_lower:
        return Platform.UNKNOWN  # Will use generic scraper
    elif "ajio" in url_lower:
        return Platform.UNKNOWN
    elif "nykaa" in url_lower:
        return Platform.UNKNOWN
    return Platform.UNKNOWN


def is_valid_product_url(url: str) -> bool:
    """Check if the URL is a valid e-commerce product URL.
    
    Supports Amazon, Flipkart, Myntra, eBay, Croma, Ajio, Nykaa,
    and any other valid HTTP/HTTPS URL.
    """
    # Must be a valid HTTP/HTTPS URL
    if not re.match(r"https?://", url):
        return False
    
    # Known platforms — always valid
    known_patterns = [
        r"https?://(www\.)?amazon\.(in|com)/.*",
        r"https?://(www\.)?flipkart\.com/.*",
        r"https?://dl\.flipkart\.com/.*",
        r"https?://(www\.)?myntra\.com/.*",
        r"https?://(www\.)?ebay\.(com|in|co\.uk)/.*",
        r"https?://(www\.)?croma\.com/.*",
        r"https?://(www\.)?ajio\.com/.*",
        r"https?://(www\.)?nykaa\.com/.*",
        r"https?://(www\.)?nykaafashion\.com/.*",
        r"https?://(www\.)?jiomart\.com/.*",
        r"https?://(www\.)?snapdeal\.com/.*",
        r"https?://(www\.)?meesho\.com/.*",
        r"https?://(www\.)?tatacliq\.com/.*",
    ]
    if any(re.match(p, url) for p in known_patterns):
        return True
    
    # Accept any valid-looking domain URL
    return bool(re.match(r"https?://[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}", url))


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
