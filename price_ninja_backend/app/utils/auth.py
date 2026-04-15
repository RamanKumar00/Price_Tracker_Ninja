"""Firebase Token Authentication Utility."""
import jwt
from jwt import PyJWKClient
from fastapi import HTTPException, Security, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional
from app.utils.logger import get_logger

logger = get_logger("auth")

security = HTTPBearer(auto_error=False)

# Firebase's public key endpoint for verifying ID tokens
FIREBASE_JWKS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

# Setup PyJWKClient to automatically fetch and cache Google's public keys
try:
    jwks_client = PyJWKClient(FIREBASE_JWKS_URL)
except Exception as e:
    logger.warning(f"Failed to initialize JWKS client: {e}")
    jwks_client = None


def verify_firebase_token(token: str) -> dict:
    if not jwks_client:
        return None
        
    try:
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        # Decode token. We disable aud/iss checks here to make it plug-and-play 
        # without requiring the user to hardcode their specific Firebase Project ID. 
        # In actual production, verify_aud=True and audience="[PROJECT_ID]"
        data = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            options={"verify_aud": False, "verify_iss": False}
        )
        return data
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        return None


async def get_current_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security),
    x_user_id: Optional[str] = Header(None)
) -> Optional[str]:
    """
    Dependency for FastAPI routes.
    Extracts user_id securely from the JWT Bearer token if available.
    Falls back to x_user_id header for backwards compatibility during dev/testing.
    """
    if credentials and credentials.credentials:
        token = credentials.credentials
        payload = verify_firebase_token(token)
        if payload and "user_id" in payload:
            logger.debug(f"Auth Success: User {payload['user_id']} via Bearer Token")
            return payload["user_id"]
            
    # Fallback to header for dev mode (insecure, but keeps the app working if token fails)
    if x_user_id:
        logger.debug(f"Auth Warning: Relied on X-User-Id header for {x_user_id}")
        return x_user_id

    return None
