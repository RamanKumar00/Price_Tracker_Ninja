"""Health check route."""

from fastapi import APIRouter
from datetime import datetime

from app.services.storage_service import storage_service
from app.schemas import ApiResponse

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check():
    """Basic health check endpoint."""
    products = storage_service.get_all_products()
    return {
        "status": "healthy",
        "service": "Price Ninja Backend",
        "version": "4.0.0",
        "timestamp": datetime.now().isoformat(),
        "products_tracked": len(products),
    }
