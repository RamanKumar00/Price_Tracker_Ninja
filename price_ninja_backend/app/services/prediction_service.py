"""Prediction service – simple linear regression to forecast prices."""

from datetime import datetime, timedelta
import math
from typing import Dict, Optional

from app.services.storage_service import storage_service
from app.utils.logger import get_logger

logger = get_logger("prediction")

class PredictionService:
    """Predicts a product's price in the future using basic moving average or linear regression."""

    def predict_price(self, product_id: str, days_ahead: int = 7) -> Dict[str, Optional[float]]:
        history = storage_service.get_price_history(product_id, limit=30)
        
        if len(history) < 3:
            return {
                "predicted_price": None,
                "confidence_percent": None,
                "days_ahead": days_ahead
            }

        # Linear regression calculation
        prices = [e.price for e in history]
        # X array: 0, 1, 2, ...
        x = list(range(len(prices)))
        y = prices
        
        # We need oldest first, so reverse to have time point 0 be the oldest
        y.reverse()

        n = len(x)
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(xi * yi for xi, yi in zip(x, y))
        sum_xx = sum(xi * xi for xi in x)

        denominator = (n * sum_xx - sum_x * sum_x)
        if denominator == 0:
            slope = 0.0
        else:
            slope = (n * sum_xy - sum_x * sum_y) / denominator

        intercept = (sum_y - slope * sum_x) / n

        # Predict for the future
        future_x = n - 1 + days_ahead
        predicted = intercept + slope * future_x
        
        # Ensure predicted doesn't go unreasonably negative
        if predicted < 0:
            predicted = 0.0

        # Basic confidence based on variance (mock logic)
        variance = sum((yi - (intercept + slope * xi)) ** 2 for xi, yi in zip(x, y)) / n
        std_dev = math.sqrt(variance) if variance >= 0 else 0
        avg_p = sum(y) / n
        confidence = 100 - (min(1.0, std_dev / (avg_p if avg_p > 0 else 1)) * 100)
        
        return {
            "predicted_price": round(predicted, 2),
            "confidence_percent": round(confidence, 1),
            "days_ahead": days_ahead
        }

prediction_service = PredictionService()
