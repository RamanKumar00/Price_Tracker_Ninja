
from sqlmodel import Session, text
from app.database import engine
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("migration")

def migrate():
    columns_to_add = [
        ("lowest_price", "FLOAT"),
        ("highest_price", "FLOAT"),
        ("average_price", "FLOAT"),
        ("total_checks", "INTEGER DEFAULT 0")
    ]
    
    with Session(engine) as session:
        for col_name, col_type in columns_to_add:
            try:
                logger.info(f"Adding column {col_name} to product table...")
                session.execute(text(f"ALTER TABLE product ADD COLUMN {col_name} {col_type};"))
                session.commit()
                logger.info(f"Successfully added {col_name}")
            except Exception as e:
                session.rollback()
                if "already exists" in str(e).lower():
                    logger.info(f"Column {col_name} already exists, skipping.")
                else:
                    logger.error(f"Error adding {col_name}: {e}")

    logger.info("Migration completed successfully!")

if __name__ == "__main__":
    migrate()
