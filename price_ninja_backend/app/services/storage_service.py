"""JSON-based local storage service for development.

Stores products and price history as JSON files in a data directory.
In production, swap this with a Firestore-backed implementation.
"""

import json
import os
from datetime import datetime
from typing import List, Optional
from pathlib import Path

from app.models import Product, PriceEntry, AlertRecord, TrackingActivity
from app.utils.logger import get_logger
from config import settings

logger = get_logger("storage")


class StorageService:
    """JSON file-based storage for products, prices, and alerts."""

    def __init__(self):
        self.data_dir = Path(settings.DATA_DIR)
        self.products_file = self.data_dir / "products.json"
        self.prices_file = self.data_dir / "price_history.json"
        self.alerts_file = self.data_dir / "alert_history.json"
        self.activity_file = self.data_dir / "activity_history.json"
        self._ensure_data_dir()

    def _ensure_data_dir(self):
        """Create data directory and files if they don't exist."""
        self.data_dir.mkdir(parents=True, exist_ok=True)
        for filepath in [self.products_file, self.prices_file, self.alerts_file, self.activity_file]:
            if not filepath.exists():
                filepath.write_text("[]", encoding="utf-8")

    def _read_json(self, filepath: Path) -> list:
        try:
            return json.loads(filepath.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, FileNotFoundError):
            return []

    def _write_json(self, filepath: Path, data: list):
        filepath.write_text(
            json.dumps(data, indent=2, default=str),
            encoding="utf-8",
        )

    # ─────────── Products ───────────

    def get_all_products(self, user_id: Optional[str] = None) -> List[Product]:
        raw = self._read_json(self.products_file)
        products = [Product(**item) for item in raw]
        if user_id:
            products = [p for p in products if p.user_id == user_id]
        return products

    def get_product(self, product_id: str) -> Optional[Product]:
        for item in self._read_json(self.products_file):
            if item["id"] == product_id:
                return Product(**item)
        return None

    def add_product(self, product: Product) -> Product:
        products = self._read_json(self.products_file)
        products.append(product.model_dump())
        self._write_json(self.products_file, products)
        logger.info(f"Product added: {product.name} ({product.id})")
        return product

    def update_product(self, product: Product) -> Product:
        products = self._read_json(self.products_file)
        for i, item in enumerate(products):
            if item["id"] == product.id:
                product.updated_at = datetime.now()
                products[i] = product.model_dump()
                break
        self._write_json(self.products_file, products)
        return product

    def delete_product(self, product_id: str) -> bool:
        products = self._read_json(self.products_file)
        new_products = [p for p in products if p["id"] != product_id]
        if len(new_products) == len(products):
            return False
        self._write_json(self.products_file, new_products)
        # Also delete price history for this product
        prices = self._read_json(self.prices_file)
        prices = [p for p in prices if p.get("product_id") != product_id]
        self._write_json(self.prices_file, prices)
        logger.info(f"Product deleted: {product_id}")
        return True

    # ─────────── Price History ───────────

    def add_price_entry(self, entry: PriceEntry) -> PriceEntry:
        prices = self._read_json(self.prices_file)
        prices.append(entry.model_dump())
        self._write_json(self.prices_file, prices)
        return entry

    def get_price_history(
        self, product_id: str, limit: int = 100, offset: int = 0
    ) -> List[PriceEntry]:
        prices = self._read_json(self.prices_file)
        filtered = [p for p in prices if p.get("product_id") == product_id]
        # Sort by timestamp descending
        filtered.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        sliced = filtered[offset : offset + limit]
        return [PriceEntry(**item) for item in sliced]

    def get_price_count(self, product_id: str) -> int:
        prices = self._read_json(self.prices_file)
        return sum(1 for p in prices if p.get("product_id") == product_id)

    # ─────────── Alert History ───────────

    def add_alert_record(self, record: AlertRecord) -> AlertRecord:
        alerts = self._read_json(self.alerts_file)
        alerts.append(record.model_dump())
        self._write_json(self.alerts_file, alerts)
        return record

    def get_alert_history(self, limit: int = 50) -> List[AlertRecord]:
        alerts = self._read_json(self.alerts_file)
        alerts.sort(key=lambda x: x.get("sent_at", ""), reverse=True)
        return [AlertRecord(**a) for a in alerts[:limit]]

    def get_alerts_for_product(self, product_id: str) -> List[AlertRecord]:
        alerts = self._read_json(self.alerts_file)
        filtered = [a for a in alerts if a.get("product_id") == product_id]
        filtered.sort(key=lambda x: x.get("sent_at", ""), reverse=True)
        return [AlertRecord(**a) for a in filtered]

    # ─────────── User ActivityLog ───────────

    def add_activity(self, activity: TrackingActivity) -> TrackingActivity:
        activities = self._read_json(self.activity_file)
        activities.append(activity.model_dump())
        self._write_json(self.activity_file, activities)
        return activity

    def get_activity_history(self, user_id: str, limit: int = 50) -> List[TrackingActivity]:
        activities = self._read_json(self.activity_file)
        filtered = [a for a in activities if a.get("user_id") == user_id]
        filtered.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
        return [TrackingActivity(**a) for a in filtered[:limit]]


# Singleton
storage_service = StorageService()
