"""
╔══════════════════════════════════════════════════════╗
║     🛒 PRICE NINJA v4.0 - FastAPI Backend           ║
║     E-Commerce Price Tracker API                     ║
╚══════════════════════════════════════════════════════╝

Run:
    uvicorn main:app --reload --host 0.0.0.0 --port 8000

Docs:
    http://localhost:8000/docs   (Swagger UI)
    http://localhost:8000/redoc  (ReDoc)
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from starlette.concurrency import run_in_threadpool

from app.routes import products, scrape, alerts, websocket, health
from app.utils.logger import get_logger
from app.services.storage_service import storage_service
from app.services.scraper_service import scraper_service
from app.services.data_service import data_service
from app.services.alert_service import alert_service
from app.models import PriceEntry
from config import settings
from apscheduler.schedulers.background import BackgroundScheduler
import asyncio

logger = get_logger("main")


async def run_auto_scrape():
    """Background task to update all tracked products."""
    logger.info("⏰ Auto-scrape started...")
    products = storage_service.get_all_products()
    if not products:
        logger.info("   No products to scrape.")
        return

    scraped_count = 0
    alerts_count = 0

    for product in products:
        try:
            # Run sync scraper in a thread (non-blocking)
            scraped = await run_in_threadpool(scraper_service.scrape, product.url)
            price = scraped["price"]

            change = None
            if product.current_price and product.current_price > 0:
                change = round(((price - product.current_price) / product.current_price) * 100, 2)

            # Record price
            entry = PriceEntry(product_id=product.id, price=price, change_percent=change)
            storage_service.add_price_entry(entry)

            # Update metrics
            data_service.update_product_metrics(product)
            scraped_count += 1

            # Check alerts
            sent = await alert_service.check_and_alert(
                product_id=product.id,
                product_name=product.name,
                current_price=price,
                target_price=product.target_price,
                url=product.url,
                email=product.alert_config.email_address,
                whatsapp=product.alert_config.whatsapp_number,
                email_enabled=product.alert_config.email_enabled,
                whatsapp_enabled=product.alert_config.whatsapp_enabled,
                last_alert_price=product.last_alert_price,
                starting_price=product.starting_price,
                expires_at=product.expires_at,
            )
            alerts_count += sent
            
            if sent > 0:
                product.last_alert_price = price
                storage_service.update_product(product)

            # Small delay to be polite to servers
            await asyncio.sleep(2)

        except Exception as e:
            logger.error(f"   Auto-scrape failed for {product.name}: {e}")

    logger.info(f"✅ Auto-scrape finished. Scraped: {scraped_count}, Alerts: {alerts_count}")


def start_scheduler():
    """Helper to start APScheduler and link it to the async task."""
    scheduler = BackgroundScheduler()
    # Scrape every 6 hours
    scheduler.add_job(
        lambda: asyncio.run(run_auto_scrape()), 
        "interval", 
        hours=6,
        id="price_check_job",
        replace_existing=True
    )
    scheduler.start()
    return scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    logger.info("🛒 Price Ninja Backend starting...")
    logger.info(f"   Debug mode: {settings.DEBUG}")
    logger.info(f"   Data dir:   {settings.DATA_DIR}")

    # Start APScheduler for automatic scraping
    scheduler = start_scheduler()
    logger.info("📅 Background scheduler active (checking every 6h)")

    yield

    scheduler.shutdown()

    logger.info("🛒 Price Ninja Backend shutting down...")


app = FastAPI(
    title="🛒 Price Ninja API",
    description="Advanced E-Commerce Price Tracker - Amazon.in & Flipkart",
    version="4.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS – very permissive regex for debugging web connectivity
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r".*", # Allow all origins for debug
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(health.router)
app.include_router(products.router)
app.include_router(scrape.router)
app.include_router(alerts.router)
app.include_router(websocket.router)


@app.get("/")
async def root():
    return {
        "service": "🛒 Price Ninja API",
        "version": "4.0.0",
        "docs": "/docs",
        "health": "/health",
    }
