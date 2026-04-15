"""Pydantic models for Product, PriceEntry, AlertConfig."""

from __future__ import annotations
from pydantic import BaseModel, Field, HttpUrl
from typing import Optional, List
from datetime import datetime
from enum import Enum
import uuid


class Platform(str, Enum):
    AMAZON = "Amazon"
    FLIPKART = "Flipkart"
    MYNTRA = "Myntra"
    EBAY = "eBay"
    UNKNOWN = "Unknown"


class AlertType(str, Enum):
    EMAIL = "email"
    WHATSAPP = "whatsapp"
    BROWSER = "browser"


class AlertConfig(BaseModel):
    email_enabled: bool = True
    whatsapp_enabled: bool = False
    browser_enabled: bool = True
    email_address: str = ""
    whatsapp_number: str = ""


class PriceEntry(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    product_id: str
    price: float
    currency: str = "₹"
    timestamp: datetime = Field(default_factory=datetime.now)
    change_percent: Optional[float] = None
    status: str = "ok"  # ok, error, timeout


class Product(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    user_id: Optional[str] = None
    name: str
    url: str
    image_url: Optional[str] = None
    description: Optional[str] = None
    platform: Platform = Platform.UNKNOWN
    current_price: Optional[float] = None
    lowest_price: Optional[float] = None
    highest_price: Optional[float] = None
    average_price: Optional[float] = None
    target_price: float = 0.0
    total_checks: int = 0
    alert_config: AlertConfig = Field(default_factory=AlertConfig)
    is_favorite: bool = False
    last_checked: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.now)
    updated_at: datetime = Field(default_factory=datetime.now)
    last_alert_price: Optional[float] = None
    starting_price: Optional[float] = None
    expires_at: Optional[datetime] = None


class AlertRecord(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    product_id: str
    product_name: str
    price: float
    target_price: float
    alert_type: AlertType
    sent_at: datetime = Field(default_factory=datetime.now)
    success: bool = True
    error_message: Optional[str] = None
