import pytest
from httpx import AsyncClient
from main import app

@pytest.mark.asyncio
async def test_health_check():
    """Test the health check API of the backend."""
    # Using httpx's AsyncClient to test FastAPI asynchronously
    async with AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/health")
        
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
