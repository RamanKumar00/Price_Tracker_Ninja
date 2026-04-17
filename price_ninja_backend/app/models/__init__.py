"""Pydantic models for Product, PriceEntry, AlertConfig."""

from __future__ import annotations
import uuid
from datetime import datetime
from enum import Enum
from typing import Optional, List, Dict
from sqlmodel import SQLModel, Field, Column, JSON
import pytz

# Constants
IST = pytz.timezone('Asia/Kolkata')

class Platform(str, Enum):
    AMAZON = "amazon"
    FLIPKART = "flipkart"
    MYNTRA = "myntra"
    EBAY = "ebay"
    GENERIC = "generic"

class AlertType(str, Enum):
    PRICE_DROP = "price_drop"
    TARGET_REACHED = "target_reached"
    BACK_IN_STOCK = "back_in_stock"
    REGISTRATION = "registration"

class ActivityType(str, Enum):
    ADDED = "added"
    DELETED = "deleted"
    UPDATED = "updated"

class Product(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    user_id: str = Field(index=True)
    url: str
    platform: str
    name: str = "Fetching details..."
    current_price: Optional[float] = None
    starting_price: Optional[float] = None
    target_price: float = 0.0
    image_url: Optional[str] = None
    description: Optional[str] = None
    is_favorite: bool = False
    last_alert_price: Optional[float] = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(IST))
    updated_at: datetime = Field(default_factory=lambda: datetime.now(IST))
    last_checked: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    
    # Store config as a JSON column for simplicity
    alert_config: Dict = Field(default_factory=dict, sa_column=Column(JSON))

class PriceEntry(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    product_id: str = Field(foreign_key="product.id", index=True)
    price: float
    change_percent: Optional[float] = None
    timestamp: datetime = Field(default_factory=lambda: datetime.now(IST))

class AlertRecord(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    product_id: str = Field(index=True)
    product_name: str
    target_price: float
    alert_type: AlertType
    sent_at: datetime = Field(default_factory=lambda: datetime.now(IST))
    success: bool = True
    error_message: Optional[str] = None

class TrackingActivity(SQLModel, table=True):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()), primary_key=True)
    user_id: str = Field(index=True)
    product_id: str = Field(index=True)
    product_name: str
    action: ActivityType
    timestamp: datetime = Field(default_factory=lambda: datetime.now(IST))
    metadata: Optional[Dict] = Field(default=None, sa_column=Column(JSON))
