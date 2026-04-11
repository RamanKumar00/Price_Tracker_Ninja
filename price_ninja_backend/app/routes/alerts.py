"""Alert management routes."""

from fastapi import APIRouter, HTTPException

from app.schemas import ApiResponse, TestAlertRequest
from app.services.storage_service import storage_service
from app.services.alert_service import alert_service
from app.utils.logger import get_logger

logger = get_logger("routes.alerts")
router = APIRouter(prefix="/api/alerts", tags=["Alerts"])


@router.post("/test", response_model=ApiResponse)
async def send_test_alert(req: TestAlertRequest):
    """Send a test alert (email or whatsapp)."""
    product = None
    if req.product_id:
        product = storage_service.get_product(req.product_id)

    product_name = product.name if product else "Test Product"
    price = product.current_price if product and product.current_price else 9999
    target = product.target_price if product else 15000
    url = product.url if product else "https://example.com"

    if req.alert_type == "email":
        email = req.email_address or (
            product.alert_config.email_address if product else ""
        )
        if not email:
            raise HTTPException(400, "Email address is required")
        success = await alert_service.send_email_alert(
            email, product_name, price, target, url, req.product_id or ""
        )
    elif req.alert_type == "whatsapp":
        phone = req.whatsapp_number or (
            product.alert_config.whatsapp_number if product else ""
        )
        if not phone:
            raise HTTPException(400, "WhatsApp number is required")
        success = await alert_service.send_whatsapp_alert(
            phone, product_name, price, target, url, req.product_id or ""
        )
    else:
        raise HTTPException(400, "Invalid alert type. Use 'email' or 'whatsapp'")

    return ApiResponse(
        success=success,
        message=f"Test {req.alert_type} alert {'sent' if success else 'failed'}",
    )


@router.get("/history", response_model=ApiResponse)
async def get_alert_history(limit: int = 50):
    """Get alert history."""
    alerts = storage_service.get_alert_history(limit=limit)
    return ApiResponse(
        success=True,
        message=f"{len(alerts)} alerts found",
        data=[a.model_dump() for a in alerts],
    )


@router.get("/product/{product_id}", response_model=ApiResponse)
async def get_product_alerts(product_id: str):
    """Get alerts for a specific product."""
    alerts = storage_service.get_alerts_for_product(product_id)
    return ApiResponse(
        success=True,
        message=f"{len(alerts)} alerts for product",
        data=[a.model_dump() for a in alerts],
    )


@router.get("/status", response_model=ApiResponse)
async def get_alert_status():
    """Get alert system status."""
    from config import settings

    return ApiResponse(
        success=True,
        data={
            "email_configured": bool(settings.SMTP_USER and settings.SMTP_PASSWORD),
            "whatsapp_configured": bool(
                settings.TWILIO_SID and settings.TWILIO_AUTH_TOKEN
            ),
            "smtp_user": settings.SMTP_USER[:3] + "***" if settings.SMTP_USER else "",
        },
    )
