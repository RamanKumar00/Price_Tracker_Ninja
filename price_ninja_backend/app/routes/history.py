"""Historical audit log routes."""

from fastapi import APIRouter, Depends, Query
from typing import List, Optional
from app.utils.auth import get_current_user_id
from app.services.storage_service import storage_service
from app.schemas import ApiResponse

router = APIRouter(prefix="/api/history", tags=["History"])

@router.get("", response_model=ApiResponse)
async def get_tracking_history(
    limit: int = Query(50, ge=1, le=200),
    user_id: str = Depends(get_current_user_id)
):
    """Get history of tracking actions (added, deleted)."""
    history = storage_service.get_activity_history(user_id, limit=limit)
    return ApiResponse(
        success=True,
        data=[h.model_dump() for h in history]
    )
