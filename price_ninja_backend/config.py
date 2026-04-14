"""Application configuration loaded from environment variables."""

import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """App settings from .env file."""

    # Server
    BACKEND_URL: str = "http://localhost:8000"
    BACKEND_PORT: int = 8000
    DEBUG: bool = True

    # Email (Gmail SMTP)
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    # WhatsApp (Twilio)
    TWILIO_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_WHATSAPP_NUMBER: str = "+14155238886"
    USER_WHATSAPP_NUMBER: str = ""

    # Scraping
    SCRAPE_TIMEOUT_SECONDS: int = 30
    SCRAPE_RATE_LIMIT_SECONDS: int = 2

    # JWT
    JWT_SECRET_KEY: str = "price-ninja-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_MINUTES: int = 60

    # Data directory
    DATA_DIR: str = "data"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
