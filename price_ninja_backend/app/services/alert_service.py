"""Alert service for sending Email and WhatsApp notifications."""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import Optional

from app.models import AlertRecord, AlertType
from app.services.storage_service import storage_service
from app.utils.logger import get_logger
from app.utils.exceptions import AlertSendException
from config import settings

logger = get_logger("alerts")


class AlertService:
    """Sends price drop alerts via Email and WhatsApp."""

    async def send_email_alert(
        self,
        email: str,
        product_name: str,
        current_price: float,
        target_price: float,
        url: str,
        product_id: str = "",
        starting_price: Optional[float] = None,
    ) -> bool:
        """Send email alert via Gmail SMTP."""
        subject = f"🎯 Price Drop Alert - {product_name}"
        
        savings_starting = ""
        if starting_price and starting_price > current_price:
            drop = starting_price - current_price
            percent = (drop / starting_price) * 100
            savings_starting = f"\n📉 DROP DETECTED: ₹{drop:,.0f} off ({percent:.1f}%) since you started tracking!"

        body = f"""
╔══════════════════════════════════════════════════════╗
║         🛒 PRICE NINJA - Price Alert                ║
╚══════════════════════════════════════════════════════╝

📉 PRICE DROPPED BELOW YOUR TARGET!
{savings_starting}

📦 Product:  {product_name}
💰 Current:  ₹{current_price:,.0f}
🎯 Target:   ₹{target_price:,.0f}
💸 Savings:  ₹{target_price - current_price:,.0f} below target!

🔗 Buy Now:  {url}

════════════════════════════════════════════════════════
Price Ninja v4.0
        """.strip()

        success = False
        error_msg = None

        try:
            if not settings.SMTP_USER or not settings.SMTP_PASSWORD:
                raise AlertSendException("SMTP credentials not configured")

            msg = MIMEMultipart()
            msg["From"] = settings.SMTP_USER
            msg["To"] = email
            msg["Subject"] = subject
            msg.attach(MIMEText(body, "plain"))

            with smtplib.SMTP("smtp.gmail.com", 587) as server:
                server.starttls()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.send_message(msg)

            logger.info(f"Email alert sent to {email} for {product_name}")
            success = True

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Email alert failed: {e}")

        # Record the alert
        record = AlertRecord(
            product_id=product_id,
            product_name=product_name,
            price=current_price,
            target_price=target_price,
            alert_type=AlertType.EMAIL,
            success=success,
            error_message=error_msg,
        )
        storage_service.add_alert_record(record)
        return success

    # ─────────── WhatsApp ───────────

    async def send_whatsapp_alert(
        self,
        phone: str,
        product_name: str,
        current_price: float,
        target_price: float,
        url: str,
        product_id: str = "",
        starting_price: Optional[float] = None,
    ) -> bool:
        """Send WhatsApp alert via Twilio."""
        drop_text = ""
        if starting_price and starting_price > current_price:
            drop = starting_price - current_price
            percent = (drop / starting_price) * 100
            drop_text = f"\n📉 *DROP:* ₹{drop:,.0f} ({percent:.1f}%) since tracking started!\n"

        message_body = f"""🛒 *PRICE NINJA ALERT* 🎯

📉 *PRICE DROP DETECTED!*
{drop_text}
📦 Product: {product_name}
💰 Current: ₹{current_price:,.0f}
🎯 Target: ₹{target_price:,.0f}
💸 Savings: ₹{target_price - current_price:,.0f} below target!

🔗 Buy Now: {url}

_Price Ninja v4.0_""".strip()

        success = False
        error_msg = None

        try:
            if not settings.TWILIO_SID or not settings.TWILIO_AUTH_TOKEN:
                raise AlertSendException("Twilio credentials not configured")

            from twilio.rest import Client

            client = Client(settings.TWILIO_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=message_body,
                from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}",
                to=f"whatsapp:{phone}",
            )
            logger.info(f"WhatsApp alert sent to {phone} for {product_name}")
            success = True

        except Exception as e:
            error_msg = str(e)
            logger.error(f"WhatsApp alert failed: {e}")

        record = AlertRecord(
            product_id=product_id,
            product_name=product_name,
            price=current_price,
            target_price=target_price,
            alert_type=AlertType.WHATSAPP,
            success=success,
            error_message=error_msg,
        )
        storage_service.add_alert_record(record)
        return success

    async def check_and_alert(self, product_id, product_name, current_price, target_price, url, email="", whatsapp="", email_enabled=True, whatsapp_enabled=False, last_alert_price=None, starting_price=None, expires_at=None):
        if expires_at and expires_at < datetime.now(): return 0
        if current_price >= target_price: return 0
        if last_alert_price is not None and abs(current_price - last_alert_price) < 1: return 0
        sent = 0
        if email_enabled and email:
            ok = await self.send_email_alert(
                email, product_name, current_price, target_price, url, product_id, starting_price
            )
            if ok:
                sent += 1

        if whatsapp_enabled and whatsapp:
            ok = await self.send_whatsapp_alert(
                whatsapp, product_name, current_price, target_price, url, product_id, starting_price
            )
            if ok:
                sent += 1
        return sent

    async def send_registration_confirmation(self, product_name, target_price, current_price, email="", whatsapp="", email_enabled=True, whatsapp_enabled=False, product_id="", expires_at=None):
        sent = 0
        price_str = f"INR {current_price:,.0f}" if current_price else "Fetching..."
        expiry_str = f"\nTracking until: {expires_at.strftime('%d %b %Y')}" if expires_at else ""
        if email_enabled and email:
            subject = f"Tracking Started: {product_name}"
            body = f"PRICE NINJA - Tracker Active\n\nHello!\n\nTracking started for {product_name}.\nTarget: INR {target_price:,.0f}\n{expiry_str}\n\nPrice Ninja v4.0"
            try:
                msg = MIMEMultipart(); msg["From"] = settings.SMTP_USER; msg["To"] = email; msg["Subject"] = subject; msg.attach(MIMEText(body, "plain"))
                with smtplib.SMTP("smtp.gmail.com", 587) as server:
                    server.starttls(); server.login(settings.SMTP_USER, settings.SMTP_PASSWORD); server.send_message(msg)
                sent += 1
            except Exception as e: logger.error(f"Email confirmation failed: {e}")
        if whatsapp_enabled and whatsapp:
            message_body = f"PRICE NINJA - Tracker Active\n\nTracking started for: *{product_name}*\nTarget: *INR {target_price:,.0f}*\n{expiry_str}\n\nPrice Ninja v4.0"
            try:
                from twilio.rest import Client
                client = Client(settings.TWILIO_SID, settings.TWILIO_AUTH_TOKEN)
                client.messages.create(body=message_body, from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}", to=f"whatsapp:{whatsapp}")
                sent += 1
            except Exception as e: logger.error(f"WhatsApp confirmation failed: {e}")
        return sent

alert_service = AlertService()
