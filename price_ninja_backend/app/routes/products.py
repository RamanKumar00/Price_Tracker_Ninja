"""Product management API routes."""

from fastapi import APIRouter, HTTPException, Header
from datetime import datetime
from typing import Optional, List

from app.models import Product, Platform, AlertConfig
from app.schemas import (
    AddProductRequest,
    UpdateProductRequest,
    ApiResponse,
)
from app.services.storage_service import storage_service
from app.services.scraper_service import scraper_service
from app.services.data_service import data_service
from app.services.alert_service import alert_service
from app.utils.validators import detect_platform, is_valid_product_url
from app.utils.exceptions import ScraperException
from app.utils.logger import get_logger

logger = get_logger("routes.products")
router = APIRouter(prefix="/api/products", tags=["Products"])


@router.post("/add", response_model=ApiResponse)
async def add_product(req: AddProductRequest, x_user_id: Optional[str] = Header(None)):
    """Add a new product to track."""
    if not is_valid_product_url(req.url):
        raise HTTPException(400, "Invalid product URL. Only Amazon.in and Flipkart are supported.")

    platform = detect_platform(req.url)

    # Try to scrape initial price
    scraped = None
    try:
        scraped = scraper_service.scrape(req.url)
    except ScraperException as e:
        logger.warning(f"Initial scrape failed for {req.url}: {e}")

    product = Product(
        user_id=x_user_id,
        name=req.name or (scraped["title"] if scraped else "Unknown Product"),
        url=req.url,
        image_url=scraped["image_url"] if scraped else None,
        platform=platform,
        current_price=scraped["price"] if scraped else None,
        starting_price=scraped["price"] if scraped else None,
        target_price=req.target_price,
        expires_at=req.expires_at,
        alert_config=AlertConfig(
            email_enabled=req.email_enabled,
            whatsapp_enabled=req.whatsapp_enabled,
            browser_enabled=req.browser_enabled,
            email_address=req.email_address,
            whatsapp_number=req.whatsapp_number,
        ),
    )

    saved = storage_service.add_product(product)

    # Save initial price entry if scraped
    if scraped:
        from app.models import PriceEntry

        entry = PriceEntry(product_id=saved.id, price=scraped["price"])
        storage_service.add_price_entry(entry)
        data_service.update_product_metrics(saved)
        
    # Send confirmation alert
    await alert_service.send_registration_confirmation(
        product_name=saved.name,
        target_price=saved.target_price,
        current_price=saved.current_price,
        email=saved.alert_config.email_address,
        whatsapp=saved.alert_config.whatsapp_number,
        email_enabled=saved.alert_config.email_enabled,
        whatsapp_enabled=saved.alert_config.whatsapp_enabled,
        product_id=saved.id
    )

    return ApiResponse(
        success=True,
        message=f"Product added: {saved.name}",
        data=saved.model_dump(),
    )


@router.get("", response_model=ApiResponse)
async def list_products(x_user_id: Optional[str] = Header(None)):
    """Get all tracked products."""
    products = storage_service.get_all_products(user_id=x_user_id)
    return ApiResponse(
        success=True,
        message=f"{len(products)} products found",
        data=[p.model_dump() for p in products],
    )


@router.get("/{product_id}", response_model=ApiResponse)
async def get_product(product_id: str, x_user_id: Optional[str] = Header(None)):
    """Get a specific product by ID."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")
    return ApiResponse(success=True, data=product.model_dump())


@router.put("/{product_id}", response_model=ApiResponse)
async def update_product(product_id: str, req: UpdateProductRequest, x_user_id: Optional[str] = Header(None)):
    """Update a product's settings."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")

    if req.name is not None:
        product.name = req.name
    if req.target_price is not None:
        product.target_price = req.target_price
    if req.is_favorite is not None:
        product.is_favorite = req.is_favorite
    if req.email_enabled is not None:
        product.alert_config.email_enabled = req.email_enabled
    if req.whatsapp_enabled is not None:
        product.alert_config.whatsapp_enabled = req.whatsapp_enabled
    if req.browser_enabled is not None:
        product.alert_config.browser_enabled = req.browser_enabled
    if req.expires_at is not None:
        product.expires_at = req.expires_at

    updated = storage_service.update_product(product)
    return ApiResponse(
        success=True,
        message="Product updated",
        data=updated.model_dump(),
    )


@router.delete("/{product_id}", response_model=ApiResponse)
async def delete_product(product_id: str, x_user_id: Optional[str] = Header(None)):
    """Delete a product and its history."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")
    
    deleted = storage_service.delete_product(product_id)
    if not deleted:
        raise HTTPException(404, "Product not found")
    return ApiResponse(success=True, message="Product deleted")


@router.get("/{product_id}/history", response_model=ApiResponse)
async def get_price_history(product_id: str, limit: int = 100, offset: int = 0, x_user_id: Optional[str] = Header(None)):
    """Get price history for a product."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")

    history = storage_service.get_price_history(product_id, limit=limit, offset=offset)
    total = storage_service.get_price_count(product_id)
    metrics = data_service.compute_metrics(product_id)

    return ApiResponse(
        success=True,
        data={
            "product_id": product_id,
            "product_name": product.name,
            "entries": [e.model_dump() for e in history],
            "total": total,
            **metrics,
        },
    )


@router.get("/{product_id}/trend")
async def get_price_trend(product_id: str, limit: int = 30, x_user_id: Optional[str] = Header(None)):
    """Get price trend data for charts."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")

    trend = data_service.get_price_trend(product_id, limit=limit)
    return ApiResponse(success=True, data=trend)


@router.get("/{product_id}/export")
async def export_csv(product_id: str, x_user_id: Optional[str] = Header(None)):
    """Export price history as CSV."""
    from fastapi.responses import PlainTextResponse

    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")

    csv_data = data_service.export_csv(product_id)
    return PlainTextResponse(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={product.name}_prices.csv"},
    )

@router.get("/{product_id}/prediction")
async def get_price_prediction(product_id: str, days: int = 7, x_user_id: Optional[str] = Header(None)):
    """Predict price based on history."""
    from app.services.prediction_service import prediction_service
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != x_user_id):
        raise HTTPException(404, "Product not found")

    pred = prediction_service.predict_price(product_id, days_ahead=days)
    return ApiResponse(success=True, data=pred)
