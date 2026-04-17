"""Scraping API routes – trigger price scrapes on demand."""

from fastapi import APIRouter, HTTPException
from datetime import datetime
from starlette.concurrency import run_in_threadpool

from app.models import PriceEntry
from app.schemas import ApiResponse, ScrapeResult
from app.services.storage_service import storage_service
from app.services.scraper_service import scraper_service
from app.services.data_service import data_service
from app.services.alert_service import alert_service
from app.utils.exceptions import ScraperException
from app.utils.logger import get_logger

logger = get_logger("routes.scrape")
router = APIRouter(prefix="/api/scrape", tags=["Scraping"])


@router.post("/now", response_model=ApiResponse)
async def scrape_all_products():
    """Scrape prices for all tracked products in parallel."""
    products = storage_service.get_all_products()
    if not products:
        return ApiResponse(success=True, message="No products to scrape", data=[])

    result = ScrapeResult()

    async def _scrape_one(product):
        try:
            scraped = await run_in_threadpool(scraper_service.scrape, product.url)
            price = scraped.get("price", 0.0)

            # ONLY save entry and update metrics if price is valid (>0)
            if price > 0:
                 # Compute change percent
                 change = None
                 if product.current_price and product.current_price > 0:
                     change = round(((price - product.current_price) / product.current_price) * 100, 2)

                 # Save price entry
                 entry = PriceEntry(
                     product_id=product.id,
                     price=price,
                     change_percent=change,
                 )
                 storage_service.add_price_entry(entry)

                 # Update product metrics
                 data_service.update_product_metrics(product)
            else:
                 logger.warning(f"Skipping update for {product.name} because price is 0 (Failed scrape)")
                 return {"success": False, "product_id": product.id, "name": product.name, "error": "Price not found"}

            # Check and send alerts
            alerts_sent = await alert_service.check_and_alert(
                product_id=product.id,
                product_name=product.name,
                current_price=price,
                target_price=product.target_price,
                url=product.url,
                email=product.alert_config.get("email_address", ""),
                whatsapp=product.alert_config.get("whatsapp_number", ""),
                fcm_token=product.alert_config.get("fcm_token", ""),
                email_enabled=product.alert_config.get("email_enabled", True),
                whatsapp_enabled=product.alert_config.get("whatsapp_enabled", False),
                push_enabled=product.alert_config.get("fcm_token", "") != "",
                last_alert_price=product.last_alert_price,
                starting_price=product.starting_price,
                expires_at=product.expires_at,
            )

            if alerts_sent > 0:
                product.last_alert_price = price
                storage_service.update_product(product)

            return {
                "success": True,
                "product_id": product.id,
                "name": product.name,
                "price": price,
                "change_percent": change,
                "alerts_sent": alerts_sent
            }

        except Exception as e:
            logger.error(f"Scrape failed for {product.name}: {e}")
            return {
                "success": False,
                "product_id": product.id,
                "name": product.name,
                "error": str(e)
            }

    # Run all scrapes in parallel
    tasks = [_scrape_one(p) for p in products]
    responses = await asyncio.gather(*tasks)

    for resp in responses:
        if resp["success"]:
            result.products_scraped += 1
            result.alerts_sent += resp["alerts_sent"]
            result.prices.append({
                "product_id": resp["product_id"],
                "name": resp["name"],
                "price": resp["price"],
                "change_percent": resp["change_percent"],
            })
        else:
            result.errors.append({
                "product_id": resp["product_id"],
                "name": resp["name"],
                "error": resp["error"],
            })

    return ApiResponse(
        success=True,
        message=f"Scraped {result.products_scraped}/{len(products)} products, {result.alerts_sent} alerts sent",
        data=result.model_dump(),
    )


@router.post("/{product_id}", response_model=ApiResponse)
async def scrape_single_product(product_id: str):
    """Scrape price for a specific product."""
    product = storage_service.get_product(product_id)
    if not product:
        raise HTTPException(404, "Product not found")

    try:
        scraped = await run_in_threadpool(scraper_service.scrape, product.url)
        price = scraped.get("price", 0.0)
        
        if price <= 0:
             return ApiResponse(success=False, message="Scraping failed: Price not found on page. The product may be out of stock or link is blocked.")

        change = None
        if product.current_price and product.current_price > 0:
            change = round(((price - product.current_price) / product.current_price) * 100, 2)

        entry = PriceEntry(
            product_id=product.id,
            price=price,
            change_percent=change,
        )
        storage_service.add_price_entry(entry)

        # Update image if missing
        if not product.image_url and scraped.get("image_url"):
            product.image_url = scraped["image_url"]

        product = data_service.update_product_metrics(product)

        # Check alerts
        alerts_sent = await alert_service.check_and_alert(
            product_id=product.id,
            product_name=product.name,
            current_price=price,
            target_price=product.target_price,
            url=product.url,
            email=product.alert_config.get("email_address", ""),
            whatsapp=product.alert_config.get("whatsapp_number", ""),
            fcm_token=product.alert_config.get("fcm_token", ""),
            email_enabled=product.alert_config.get("email_enabled", True),
            whatsapp_enabled=product.alert_config.get("whatsapp_enabled", False),
            push_enabled=product.alert_config.get("fcm_token", "") != "",
            last_alert_price=product.last_alert_price,
            starting_price=product.starting_price,
            expires_at=product.expires_at,
        )

        if alerts_sent > 0:
            product.last_alert_price = price
            storage_service.update_product(product)

        return ApiResponse(
            success=True,
            message=f"Price scraped: ₹{price:,.0f}" + (f" ({change:+.1f}%)" if change else ""),
            data={
                "product_id": product.id,
                "name": product.name,
                "price": price,
                "change_percent": change,
                "alerts_sent": alerts_sent,
                "product": product.model_dump(),
            },
        )

    except ScraperException as e:
        raise HTTPException(500, f"Scraping failed: {e}")
