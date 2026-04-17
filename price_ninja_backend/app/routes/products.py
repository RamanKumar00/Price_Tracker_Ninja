"""Product management API routes."""

from fastapi import APIRouter, HTTPException, Header, Depends, BackgroundTasks
from app.utils.auth import get_current_user_id
from datetime import datetime
import asyncio
from typing import Optional, List
from starlette.concurrency import run_in_threadpool

from app.models import Product, Platform, AlertConfig, PriceEntry
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


async def _background_scrape_and_update(product_id: str, url: str, alert_config: AlertConfig, target_price: float):
    """Run scrape in background after product is saved. Updates price, title, image."""
    product = storage_service.get_product(product_id)
    if not product:
        logger.warning(f"[BG] Product {product_id} not found starting background task")
        return

    try:
        logger.info(f"[BG] Starting background scrape for product {product_id}")
        scraped = await run_in_threadpool(scraper_service.scrape, url)

        # Update product with scraped data
        if product.name in ("Fetching details...", "Unknown Product", ""):
            product.name = scraped.get("title", product.name)
        if not product.image_url:
            product.image_url = scraped.get("image_url")
        if not product.description:
            product.description = scraped.get("description", "No description available.")

        price = scraped["price"]
        product.current_price = price
        product.starting_price = price
        storage_service.update_product(product)

        # Save initial price entry
        entry = PriceEntry(product_id=product_id, price=price)
        storage_service.add_price_entry(entry)
        data_service.update_product_metrics(product)
        logger.info(f"[BG] Scrape success for {product.name}: ₹{price}")

    except ScraperException as e:
        logger.warning(f"[BG] Initial scrape failed for {product_id}: {e}")
    except Exception as e:
        logger.error(f"[BG] Unexpected error during scrape for {product_id}: {e}")

    # ALWAYS try to send confirmation, even if scrape failed (price will show as "Fetching...")
    try:
        await alert_service.send_registration_confirmation(
            product_name=product.name,
            target_price=target_price,
            current_price=product.current_price,
            email=alert_config.email_address,
            whatsapp=alert_config.whatsapp_number,
            email_enabled=alert_config.email_enabled,
            whatsapp_enabled=alert_config.whatsapp_enabled,
            product_id=product_id,
        )
    except Exception as e:
        logger.error(f"[BG] Failed to send registration confirmation: {e}")



@router.post("/add", response_model=ApiResponse)
async def add_product(
    req: AddProductRequest,
    background_tasks: BackgroundTasks,
    user_id: Optional[str] = Depends(get_current_user_id)
):
    """Add a new product to track. Saves instantly, scrapes price in background."""
    if not user_id:
        raise HTTPException(401, "Unauthorized: user_id is required to add products.")

    if not is_valid_product_url(req.url):
        raise HTTPException(400, "Invalid product URL. Please provide a valid e-commerce product link (Amazon, Flipkart, Myntra, etc.).")

    platform = detect_platform(req.url)

    alert_cfg = AlertConfig(
        email_enabled=req.email_enabled,
        whatsapp_enabled=req.whatsapp_enabled,
        browser_enabled=req.browser_enabled,
        email_address=req.email_address,
        whatsapp_number=req.whatsapp_number,
    )

    # WE REMOVED THE SYNC SCRAPE to make the button instant.
    # The UI will show "Fetching details..." while the background task runs.
    name = "Fetching details..."
    image_url = ""
    description = ""
    initial_price = None

    product = Product(
        user_id=user_id,
        url=req.url,
        platform=platform.value,
        name=name,
        image_url=image_url,
        current_price=initial_price,
        starting_price=initial_price,
        description=description,
        target_price=req.target_price,
        alert_config=alert_cfg,
        created_at=datetime.now(),
        last_checked=datetime.now() if initial_price else None,
    )
    
    storage_service.add_product(product)

    # background_tasks will still run to ensure full price history and initial metrics are solid
    background_tasks.add_task(
        _background_scrape_and_update, 
        product.id, 
        req.url, 
        alert_cfg, 
        req.target_price
    )

    return ApiResponse(
        success=True,
        message="Product added successfully. " + ("Initial fetch complete." if initial_price else "Details being fetched in background."),
        data=product.to_dict()
    )


@router.get("", response_model=ApiResponse)
async def list_products(user_id: Optional[str] = Depends(get_current_user_id)):
    """Get all tracked products."""
    if not user_id:
        raise HTTPException(401, "Unauthorized: user_id is required to fetch products.")
    products = storage_service.get_all_products(user_id=user_id)
    return ApiResponse(
        success=True,
        message=f"{len(products)} products found",
        data=[p.model_dump() for p in products],
    )


@router.get("/{product_id}", response_model=ApiResponse)
async def get_product(product_id: str, user_id: Optional[str] = Depends(get_current_user_id)):
    """Get a specific product by ID."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
        raise HTTPException(404, "Product not found")
    return ApiResponse(success=True, data=product.model_dump())


@router.put("/{product_id}", response_model=ApiResponse)
async def update_product(product_id: str, req: UpdateProductRequest, user_id: Optional[str] = Depends(get_current_user_id)):
    """Update a product's settings."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
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
async def delete_product(product_id: str, user_id: Optional[str] = Depends(get_current_user_id)):
    """Delete a product and its history."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
        raise HTTPException(404, "Product not found")
    
    deleted = storage_service.delete_product(product_id)
    if not deleted:
        raise HTTPException(404, "Product not found")
    return ApiResponse(success=True, message="Product deleted")


@router.get("/{product_id}/history", response_model=ApiResponse)
async def get_price_history(product_id: str, limit: int = 100, offset: int = 0, user_id: Optional[str] = Depends(get_current_user_id)):
    """Get price history for a product."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
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
async def get_price_trend(product_id: str, limit: int = 30, user_id: Optional[str] = Depends(get_current_user_id)):
    """Get price trend data for charts."""
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
        raise HTTPException(404, "Product not found")

    trend = data_service.get_price_trend(product_id, limit=limit)
    return ApiResponse(success=True, data=trend)


@router.get("/{product_id}/export")
async def export_csv(product_id: str, user_id: Optional[str] = Depends(get_current_user_id)):
    """Export price history as CSV."""
    from fastapi.responses import PlainTextResponse

    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
        raise HTTPException(404, "Product not found")

    csv_data = data_service.export_csv(product_id)
    return PlainTextResponse(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={product.name}_prices.csv"},
    )

@router.get("/{product_id}/prediction")
async def get_price_prediction(product_id: str, days: int = 7, user_id: Optional[str] = Depends(get_current_user_id)):
    """Predict price based on history."""
    from app.services.prediction_service import prediction_service
    product = storage_service.get_product(product_id)
    if not product or (product.user_id and product.user_id != user_id):
        raise HTTPException(404, "Product not found")

    pred = prediction_service.predict_price(product_id, days_ahead=days)
    return ApiResponse(success=True, data=pred)
