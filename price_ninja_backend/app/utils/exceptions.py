"""Custom exception classes for Price Ninja."""


class PriceNinjaException(Exception):
    """Base exception."""
    pass


class ScraperException(PriceNinjaException):
    """Raised when scraping fails."""
    pass


class ProductNotFoundException(PriceNinjaException):
    """Raised when a product is not found."""
    pass


class AlertSendException(PriceNinjaException):
    """Raised when an alert fails to send."""
    pass


class InvalidURLException(PriceNinjaException):
    """Raised when a URL is invalid."""
    pass


class RateLimitException(PriceNinjaException):
    """Raised when rate limit is exceeded."""
    pass
