from sqlmodel import create_engine, SQLModel, Session
from config import settings
import os

# Use PostgreSQL if available, otherwise fallback to local SQLite for development
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = "sqlite:///./price_ninja.db"

# For SQLite, we need to allow multi-threaded access
engine_kwargs = {}
if DATABASE_URL.startswith("sqlite"):
    engine_kwargs = {"connect_args": {"check_same_thread": False}}

engine = create_engine(DATABASE_URL, **engine_kwargs)

def create_db_and_tables():
    """Build the tables based on our models."""
    SQLModel.metadata.create_all(engine)

def get_session():
    """Dependency for routes to get a DB session."""
    with Session(engine) as session:
        yield session
