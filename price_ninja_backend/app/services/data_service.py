"""Data processing service – calculates metrics, trends, stats."""

from typing import List, Optional, Dict
from datetime import datetime
import statistics

from app.models import Product, PriceEntry
from app.services.storage_service import storage_service
from app.utils.logger import get_logger

logger = get_logger("data")


class DataService:
    """Computes aggregated metrics from price history."""

    def compute_metrics(self, product_id: str) -> Dict:
        """Compute min/max/avg/change for a product."""
        history = storage_service.get_price_history(product_id, limit=10000)
        if not history:
            return {
                "current_price": None,
                "lowest_price": None,
                "highest_price": None,
                "average_price": None,
                "total_checks": 0,
                "change_percent": None,
            }

        prices = [e.price for e in history]
        current = prices[0]  # Most recent (sorted desc)
        lowest = min(prices)
        highest = max(prices)
        average = round(statistics.mean(prices), 2)

        change = None
        if len(prices) >= 2:
            prev = prices[1]
            if prev > 0:
                change = round(((current - prev) / prev) * 100, 2)

        return {
            "current_price": current,
            "lowest_price": lowest,
            "highest_price": highest,
            "average_price": average,
            "total_checks": len(prices),
            "change_percent": change,
        }

    def update_product_metrics(self, product: Product) -> Product:
        """Recalculate and persist product metrics."""
        metrics = self.compute_metrics(product.id)
        product.current_price = metrics["current_price"]
        product.lowest_price = metrics["lowest_price"]
        product.highest_price = metrics["highest_price"]
        product.average_price = metrics["average_price"]
        product.total_checks = metrics["total_checks"]
        product.last_checked = datetime.now()
        storage_service.update_product(product)
        return product

    def get_price_trend(self, product_id: str, limit: int = 30) -> List[Dict]:
        """Get price trend data suitable for charting."""
        history = storage_service.get_price_history(product_id, limit=limit)
        # Reverse so oldest first (for time-series chart)
        history.reverse()
        return [
            {
                "timestamp": e.timestamp.isoformat() if isinstance(e.timestamp, datetime) else str(e.timestamp),
                "price": e.price,
                "change_percent": e.change_percent,
            }
            for e in history
        ]

    def export_csv(self, product_id: str) -> str:
        """Export price history as CSV string."""
        history = storage_service.get_price_history(product_id, limit=100000)
        lines = ["Date,Price,Change %,Status"]
        for e in history:
            ts = e.timestamp.isoformat() if isinstance(e.timestamp, datetime) else str(e.timestamp)
            lines.append(f"{ts},{e.price},{e.change_percent or ''},{ e.status}")
        return "\n".join(lines)


# Singleton
data_service = DataService()
