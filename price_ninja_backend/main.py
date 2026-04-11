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

from app.routes import products, scrape, alerts, websocket, health
from app.utils.logger import get_logger
from config import settings

logger = get_logger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and shutdown events."""
    logger.info("🛒 Price Ninja Backend starting...")
    logger.info(f"   Debug mode: {settings.DEBUG}")
    logger.info(f"   Data dir:   {settings.DATA_DIR}")

    # Optional: start APScheduler for automatic scraping
    # scheduler = BackgroundScheduler()
    # scheduler.add_job(scrape_all, "interval", hours=6)
    # scheduler.start()

    yield

    logger.info("🛒 Price Ninja Backend shutting down...")


app = FastAPI(
    title="🛒 Price Ninja API",
    description="Advanced E-Commerce Price Tracker - Amazon.in & Flipkart",
    version="4.0.0",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS – allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
