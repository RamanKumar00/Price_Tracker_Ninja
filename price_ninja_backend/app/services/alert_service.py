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

        msg = MIMEMultipart("alternative")
        msg["From"] = settings.SMTP_USER
        msg["To"] = email
        msg["Subject"] = subject

        html_body = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: 'Inter', Helvetica, Arial, sans-serif; background-color: #0f172a; margin: 0; padding: 20px; }}
                .container {{ max-width: 600px; margin: 0 auto; background: #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); }}
                .header {{ background: linear-gradient(135deg, #10b981 0%, #3b82f6 100%); padding: 30px; text-align: center; }}
                .header h1 {{ margin: 0; color: #ffffff; font-size: 28px; font-weight: 800; letter-spacing: 1px; }}
                .content {{ padding: 40px 30px; color: #f8fafc; line-height: 1.6; font-size: 16px; }}
                .price-box {{ background: rgba(16, 185, 129, 0.1); border-left: 4px solid #10b981; padding: 20px; margin: 25px 0; border-radius: 8px; }}
                .price-text {{ font-size: 20px; font-weight: 700; color: #10b981; margin: 8px 0; }}
                .target-text {{ font-size: 18px; font-weight: 600; color: #94a3b8; margin: 8px 0; }}
                .info-text {{ font-size: 16px; font-weight: 500; color: #f8fafc; margin: 8px 0; }}
                .btn {{ display: inline-block; padding: 14px 28px; background: linear-gradient(135deg, #10b981 0%, #3b82f6 100%); color: white; text-decoration: none; border-radius: 8px; font-weight: 700; font-size: 16px; margin-top: 25px; text-align: center; width: 100%; box-sizing: border-box; }}
                .footer {{ text-align: center; padding: 20px; color: #64748b; font-size: 13px; background: #0f172a; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🥷 PRICE NINJA</h1>
                </div>
                <div class="content">
                    <h2 style="margin-top: 0; color: #f8fafc; font-size: 24px;">Drop Detected! 📉</h2>
                    {f'<p style="color: #38bdf8; font-weight: bold;">{savings_starting.strip()}</p>' if savings_starting else ''}
                    <p style="color: #cbd5e1;">Great news! The price for <strong>{product_name}</strong> just dropped below your target.</p>
                    
                    <div class="price-box">
                        <p class="price-text">Current Price: ₹{current_price:,.0f}</p>
                        <p class="target-text">Target Price: ₹{target_price:,.0f}</p>
                        <p class="info-text">Total Savings: ₹{(target_price - current_price):,.0f}</p>
                    </div>
                    
                    <a href="{url}" class="btn">View & Buy Now</a>
                </div>
                <div class="footer">
                    Price Ninja v4.0 • Premium Price Tracking<br>
                    <span style="font-size: 11px;">You are receiving this because you set a price alert.</span>
                </div>
            </div>
        </body>
        </html>
        """
        msg.attach(MIMEText(body, "plain"))
        msg.attach(MIMEText(html_body, "html"))

        success = False
        error_msg = None

        try:
            # --- Method A: Resend API (HTTP Based, Recommended for Cloud/Railway) ---
            if settings.RESEND_API_KEY and not settings.RESEND_API_KEY.startswith("re_xxxx"):
                try:
                    import requests
                    logger.info(f"Sending email via Resend API to {email}")
                    response = requests.post(
                        "https://api.resend.com/emails",
                        headers={
                            "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "from": "Price Ninja <onboarding@resend.dev>",
                            "to": email,
                            "subject": subject,
                            "html": html_body,
                            "text": body,
                        },
                        timeout=10
                    )
                    if response.status_code in (200, 201):
                        logger.info(f"Resend email success!")
                        success = True
                    else:
                        raise AlertSendException(f"Resend API Error: {response.text}")
                except Exception as resend_err:
                    logger.warning(f"Resend failed, trying SMTP fallback: {resend_err}")

            # --- Method B: SMTP (Fallback) ---
            if not success:
                if not settings.SMTP_USER or not settings.SMTP_PASSWORD or settings.SMTP_USER == "your_email@gmail.com":
                    raise AlertSendException("Email credentials (Resend or SMTP) not configured")

                with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as server:
                    server.starttls()
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                    server.send_message(msg)

                logger.info(f"Email alert sent to {email} for {product_name}")
                success = True

        except Exception as e:
            error_msg = f"EMAIL_ERROR: {str(e)}"
            if "authentication failed" in error_msg.lower():
                error_msg = "GMAIL_AUTH_FAILED: Use an 'App Password', not your main password."
            elif "connection refused" in error_msg.lower():
                error_msg = "SMTP_CONN_REFUSED: Railway blocks port 587. Use RESEND_API_KEY instead."
            logger.error(f"Email alert failed: {error_msg}")

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
            if not settings.TWILIO_SID or not settings.TWILIO_AUTH_TOKEN or "xxxx" in settings.TWILIO_SID.lower() or settings.TWILIO_SID.startswith("AC" + "x" * 10):
                raise AlertSendException("Twilio credentials not configured")

            from twilio.rest import Client
            
            # Ensure phone has + prefix for Twilio
            formatted_phone = phone if phone.startswith("+") else f"+{phone}"

            client = Client(settings.TWILIO_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=message_body,
                from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}",
                to=f"whatsapp:{formatted_phone}",
            )
            logger.info(f"WhatsApp alert sent to {formatted_phone} for {product_name}")
            success = True

        except Exception as e:
            error_msg = f"WHATSAPP_ERROR: {str(e)}"
            if "sandbox" in error_msg.lower() or "63032" in error_msg:
                error_msg = "SANDBOX_ERROR: Recipient has NOT joined your Twilio sandbox (send 'join keyword')."
            elif "authenticate" in error_msg.lower():
                error_msg = "TWILIO_AUTH_FAILED: Check SID and Token in Railway environment."
            logger.error(f"WhatsApp alert failed: {error_msg}")

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
        """Send a registration confirmation. Non-blocking — skips if creds not configured."""
        sent = 0
        price_str = f"INR {current_price:,.0f}" if current_price else "Fetching..."
        expiry_str = f"\nTracking until: {expires_at.strftime('%d %b %Y')}" if expires_at else ""

        # ─── Email confirmation ───
        if email_enabled and email:
            # Guard: skip if SMTP not configured
            if not settings.SMTP_USER or not settings.SMTP_PASSWORD or settings.SMTP_USER == "your_email@gmail.com":
                logger.info(f"Skipping email confirmation — SMTP not configured")
            else:
                try:
                    subject = f"Tracker Active: {product_name[:30]}..."
                    body_plain = f"PRICE NINJA - Tracker Active\n\nTracking started for {product_name}.\nCurrent Price: {price_str}\nTarget: INR {target_price:,.0f}\n{expiry_str}\n\nPrice Ninja v4.0"
                    
                    html_body = f"""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body {{ font-family: 'Inter', Helvetica, Arial, sans-serif; background-color: #0f172a; margin: 0; padding: 20px; }}
                            .container {{ max-width: 600px; margin: 0 auto; background: #1e293b; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }}
                            .header {{ background: linear-gradient(135deg, #8b5cf6 0%, #3b82f6 100%); padding: 30px; text-align: center; }}
                            .header h1 {{ margin: 0; color: #ffffff; font-size: 28px; font-weight: 800; letter-spacing: 1px; }}
                            .content {{ padding: 35px 30px; color: #f8fafc; line-height: 1.6; font-size: 16px; }}
                            .product-title {{ color: #ffffff; font-size: 18px; font-weight: 600; margin-bottom: 20px; }}
                            .price-box {{ background: rgba(139, 92, 246, 0.1); border-left: 4px solid #8b5cf6; padding: 20px; margin: 20px 0; border-radius: 8px; }}
                            .price-text {{ font-size: 18px; font-weight: 500; color: #cbd5e1; margin: 6px 0; }}
                            .price-val {{ font-size: 20px; font-weight: 700; color: #ffffff; }}
                            .target-val {{ font-weight: 700; color: #8b5cf6; }}
                            .footer {{ text-align: center; padding: 20px; color: #64748b; font-size: 13px; background: #0f172a; border-top: 1px solid #1e293b; }}
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="header">
                                <h1>🥷 PRICE NINJA</h1>
                            </div>
                            <div class="content">
                                <h2 style="margin-top: 0; color: #f8fafc; font-size: 24px;">Tracking Started! 🎯</h2>
                                <p style="color: #cbd5e1;">Your ninja is now watching the prices for:</p>
                                <div class="product-title">{product_name}</div>
                                
                                <div class="price-box">
                                    <p class="price-text">Current Price: <span class="price-val">{price_str}</span></p>
                                    <p class="price-text">Target Price: <span class="price-val target-val">INR {target_price:,.0f}</span></p>
                                </div>
                                
                                <p style="color: #94a3b8; font-size: 15px;">We'll secretly monitor this and immediately alert you via Email & WhatsApp the moment it drops below your target.</p>
                                {f'<p style="color: #8b5cf6; font-size: 14px; font-weight: 600;">Tracking valid until: {expires_at.strftime("%d %b %Y")}</p>' if expires_at else ''}
                            </div>
                            <div class="footer">
                                Price Ninja v4.0 • We track, you save.<br>
                                <span style="font-size: 11px;">You are receiving this because you added a product on Price Ninja.</span>
                            </div>
                        </div>
                    </body>
                    </html>
                    """

                    msg = MIMEMultipart("alternative")
                    msg["From"] = settings.SMTP_USER
                    msg["To"] = email
                    msg["Subject"] = subject
                    msg.attach(MIMEText(body_plain, "plain"))
                    msg.attach(MIMEText(html_body, "html"))
                    
                    with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as server:
                        server.starttls()
                        server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                        server.send_message(msg)
                    sent += 1
                    logger.info(f"Email confirmation sent to {email}")
                except Exception as e:
                    logger.error(f"Email confirmation failed: {e}")

        # ─── WhatsApp confirmation ───
        if whatsapp_enabled and whatsapp:
            if not settings.TWILIO_SID or not settings.TWILIO_AUTH_TOKEN or "xxxx" in settings.TWILIO_SID.lower() or settings.TWILIO_SID.startswith("AC" + "x" * 10):
                logger.info(f"Skipping WhatsApp confirmation — Twilio not configured")
            else:
                try:
                    message_body = f"PRICE NINJA - Tracker Active\n\nTracking started for: *{product_name}*\nTarget: *INR {target_price:,.0f}*\n{expiry_str}\n\nPrice Ninja v4.0"
                    from twilio.rest import Client
                    client = Client(settings.TWILIO_SID, settings.TWILIO_AUTH_TOKEN)
                    client.messages.create(body=message_body, from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}", to=f"whatsapp:{whatsapp}")
                    sent += 1
                    logger.info(f"WhatsApp confirmation sent to {whatsapp}")
                except Exception as e:
                    logger.error(f"WhatsApp confirmation failed: {e}")

        return sent

alert_service = AlertService()
