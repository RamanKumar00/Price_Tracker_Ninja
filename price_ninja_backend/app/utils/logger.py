"""Logging utility for the Price Ninja backend."""

import logging
import sys

try:
    # python-json-logger v4+
    from pythonjsonlogger.json import JsonFormatter
except ImportError:
    # python-json-logger v2-3
    from pythonjsonlogger import jsonlogger
    JsonFormatter = jsonlogger.JsonFormatter


def get_logger(name: str = "price_ninja") -> logging.Logger:
    """Get a configured logger instance."""
    logger = logging.getLogger(name)

    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        formatter = JsonFormatter(
            "%(asctime)s %(name)s %(levelname)s %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        logger.setLevel(logging.INFO)

    return logger
