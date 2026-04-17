"""SQLModel-based database storage service."""

from typing import List, Optional
from datetime import datetime
from sqlmodel import Session, select, desc, func
from app.database import engine
from app.models import Product, PriceEntry, AlertRecord, TrackingActivity, IST
from app.utils.logger import get_logger

logger = get_logger("storage")


class StorageService:
    """SQL database storage for products, prices, and alerts."""

    # ─────────── Products ───────────

    def get_all_products(self, user_id: Optional[str] = None) -> List[Product]:
        with Session(engine) as session:
            statement = select(Product)
            if user_id:
                statement = statement.where(Product.user_id == user_id)
            return session.exec(statement).all()

    def get_product(self, product_id: str) -> Optional[Product]:
        with Session(engine) as session:
            return session.get(Product, product_id)

    def add_product(self, product: Product) -> Product:
        with Session(engine) as session:
            session.add(product)
            session.commit()
            session.refresh(product)
            logger.info(f"Product added to DB: {product.id}")
            return product

    def update_product(self, product: Product) -> Product:
        with Session(engine) as session:
            product.updated_at = datetime.now(IST)
            session.add(product)
            session.commit()
            session.refresh(product)
            return product

    def delete_product(self, product_id: str) -> bool:
        with Session(engine) as session:
            product = session.get(Product, product_id)
            if not product:
                return False
            
            # Delete related price entries first
            price_statement = select(PriceEntry).where(PriceEntry.product_id == product_id)
            prices = session.exec(price_statement).all()
            for p in prices:
                session.delete(p)
                
            session.delete(product)
            session.commit()
            logger.info(f"Product deleted: {product_id}")
            return True

    # ─────────── Price History ───────────

    def add_price_entry(self, entry: PriceEntry) -> PriceEntry:
        with Session(engine) as session:
            session.add(entry)
            session.commit()
            session.refresh(entry)
            return entry

    def get_price_history(
        self, product_id: str, limit: int = 100, offset: int = 0
    ) -> List[PriceEntry]:
        with Session(engine) as session:
            statement = select(PriceEntry).where(PriceEntry.product_id == product_id).order_by(desc(PriceEntry.timestamp)).offset(offset).limit(limit)
            return session.exec(statement).all()

    def get_price_count(self, product_id: str) -> int:
        with Session(engine) as session:
            statement = select(func.count()).select_from(PriceEntry).where(PriceEntry.product_id == product_id)
            return session.exec(statement).one()

    # ─────────── Alert History ───────────

    def add_alert_record(self, record: AlertRecord) -> AlertRecord:
        with Session(engine) as session:
            session.add(record)
            session.commit()
            session.refresh(record)
            return record

    def get_alert_history(self, limit: int = 50) -> List[AlertRecord]:
        with Session(engine) as session:
            statement = select(AlertRecord).order_by(desc(AlertRecord.sent_at)).limit(limit)
            return session.exec(statement).all()

    def get_alerts_for_product(self, product_id: str) -> List[AlertRecord]:
        with Session(engine) as session:
            statement = select(AlertRecord).where(AlertRecord.product_id == product_id).order_by(desc(AlertRecord.sent_at))
            return session.exec(statement).all()

    # ─────────── User ActivityLog ───────────

    def add_activity(self, activity: TrackingActivity) -> TrackingActivity:
        with Session(engine) as session:
            session.add(activity)
            session.commit()
            session.refresh(activity)
            return activity

    def get_activity_history(self, user_id: str, limit: int = 50) -> List[TrackingActivity]:
        with Session(engine) as session:
            statement = select(TrackingActivity).where(TrackingActivity.user_id == user_id).order_by(desc(TrackingActivity.timestamp)).limit(limit)
            return session.exec(statement).all()


# Singleton
storage_service = StorageService()
