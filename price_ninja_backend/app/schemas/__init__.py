"""Request/Response schemas for the API."""

from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# ───────── Request Schemas ─────────

class AddProductRequest(BaseModel):
    url: str
    name: Optional[str] = None
    target_price: float = 0.0
    email_enabled: bool = True
    whatsapp_enabled: bool = False
    browser_enabled: bool = True
    email_address: str = ""
    whatsapp_number: str = ""
    expires_at: Optional[datetime] = None


class UpdateProductRequest(BaseModel):
    name: Optional[str] = None
    target_price: Optional[float] = None
    email_enabled: Optional[bool] = None
    whatsapp_enabled: Optional[bool] = None
    browser_enabled: Optional[bool] = None
    is_favorite: Optional[bool] = None
    expires_at: Optional[datetime] = None


class TestAlertRequest(BaseModel):
    alert_type: str = "email"  # email | whatsapp
    product_id: Optional[str] = None
    email_address: Optional[str] = None
    whatsapp_number: Optional[str] = None


class AlertConfigUpdateRequest(BaseModel):
    email_enabled: Optional[bool] = None
    whatsapp_enabled: Optional[bool] = None
    browser_enabled: Optional[bool] = None
    email_address: Optional[str] = None
    whatsapp_number: Optional[str] = None


# ───────── Response Schemas ─────────

class ApiResponse(BaseModel):
    success: bool = True
    message: str = ""
    data: Optional[dict | list] = None
    timestamp: datetime = Field(default_factory=datetime.now)


class ScrapeResult(BaseModel):
    products_scraped: int = 0
    prices: list = []
    alerts_sent: int = 0
    errors: list = []
    timestamp: datetime = Field(default_factory=datetime.now)


class PriceHistoryResponse(BaseModel):
    product_id: str
    product_name: str
    entries: list = []
    total: int = 0
    current_price: Optional[float] = None
    lowest_price: Optional[float] = None
    highest_price: Optional[float] = None
    average_price: Optional[float] = None
