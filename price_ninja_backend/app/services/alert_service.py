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

    # ─────────── Private Helpers ───────────

    async def _send_email_base(self, to_email: str, subject: str, body_plain: str, html_body: str) -> bool:
        """Internal helper to send email via Resend or SMTP."""
        success = False
        error_msg = None

        try:
            # --- Method A: Resend API (HTTP Based) ---
            if settings.RESEND_API_KEY and not settings.RESEND_API_KEY.startswith("re_xxxx"):
                try:
                    import requests
                    logger.info(f"Sending email via Resend API to {to_email}")
                    response = await run_in_threadpool(
                        requests.post,
                        "https://api.resend.com/emails",
                        headers={
                            "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                            "Content-Type": "application/json",
                        },
                        json={
                            "from": "Price Ninja <onboarding@resend.dev>",
                            "to": to_email,
                            "subject": subject,
                            "html": html_body,
                            "text": body_plain,
                        },
                        timeout=10
                    )
                    if response.status_code in (200, 201):
                        logger.info(f"Resend email success to {to_email}")
                        return True
                    else:
                        logger.warning(f"Resend API Error: {response.text}")
                except Exception as resend_err:
                    logger.warning(f"Resend failed, trying SMTP fallback: {resend_err}")

            # --- Method B: SMTP (Fallback) ---
            if not settings.SMTP_USER or not settings.SMTP_PASSWORD or settings.SMTP_USER == "your_email@gmail.com":
                logger.warning("SMTP credentials not configured and Resend failed/skipped.")
                return False

            def _send_smtp():
                msg = MIMEMultipart("alternative")
                msg["From"] = settings.SMTP_USER
                msg["To"] = to_email
                msg["Subject"] = subject
                msg.attach(MIMEText(body_plain, "plain"))
                msg.attach(MIMEText(html_body, "html"))

                with smtplib.SMTP("smtp.gmail.com", 587, timeout=10) as server:
                    server.starttls()
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                    server.send_message(msg)
                return True

            success = await run_in_threadpool(_send_smtp)
            logger.info(f"Email sent via SMTP to {to_email}")
            return success

        except Exception as e:
            error_msg = str(e)
            logger.error(f"Email base sending failed: {error_msg}")
            return False

    async def _send_whatsapp_base(self, phone: str, message: str) -> bool:
        """Internal helper to send WhatsApp via Twilio."""
        if not settings.TWILIO_SID or not settings.TWILIO_AUTH_TOKEN or "xxxx" in settings.TWILIO_SID.lower():
            logger.warning("Twilio credentials not configured")
            return False

        try:
            from twilio.rest import Client
            
            # Ensure phone has + prefix and E.164 format
            formatted_phone = phone.strip()
            if not formatted_phone.startswith("+"):
                formatted_phone = f"+{formatted_phone}"
            
            # Additional check: if it's a 10 digit Indian number without +91
            if len(formatted_phone) == 11 and formatted_phone.startswith("+"):
                 # Likely missed country code, but let's assume +91 if length is 10+1
                 pass # Twilio might handle it or fail

            def _call_twilio():
                client = Client(settings.TWILIO_SID, settings.TWILIO_AUTH_TOKEN)
                return client.messages.create(
                    body=message,
                    from_=f"whatsapp:{settings.TWILIO_WHATSAPP_NUMBER}",
                    to=f"whatsapp:{formatted_phone}",
                )

            await run_in_threadpool(_call_twilio)
            logger.info(f"WhatsApp message sent to {formatted_phone}")
            return True

        except Exception as e:
            error_msg = str(e)
            if "sandbox" in error_msg.lower() or "63032" in error_msg:
                logger.error(f"WhatsApp Sandbox Error: Recipient {phone} has NOT joined your sandbox. Send 'join <keyword>' to {settings.TWILIO_WHATSAPP_NUMBER}")
            else:
                logger.error(f"WhatsApp base sending failed: {error_msg}")
            return False

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
        """Send email alert for price drop."""
        subject = f"🎯 Price Drop Alert - {product_name[:40]}..."
        
        savings_starting = ""
        if starting_price and starting_price > current_price:
            drop = starting_price - current_price
            percent = (drop / starting_price) * 100
            savings_starting = f"\n📉 DROP DETECTED: ₹{drop:,.0f} off ({percent:.1f}%) since you started tracking!"

        body_plain = f"PRICE NINJA - Price Alert\n\nPrice dropped below target for {product_name}.\nCurrent: ₹{current_price:,.0f}\nTarget: ₹{target_price:,.0f}\n\nBuy Now: {url}"
        
        # (Reusing your beautiful HTML template logic)
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
                .btn {{ display: inline-block; padding: 14px 28px; background: linear-gradient(135deg, #10b981 0%, #3b82f6 100%); color: white; text-decoration: none; border-radius: 8px; font-weight: 700; width: 100%; box-sizing: border-box; text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header"><h1>🥷 PRICE NINJA</h1></div>
                <div class="content">
                    <h2>Price Drop Detected! 📉</h2>
                    {f'<p style="color: #38bdf8;">{savings_starting}</p>' if savings_starting else ''}
                    <p>Good news! <strong>{product_name}</strong> is now at ₹{current_price:,.0f}.</p>
                    <div class="price-box">
                        <p class="price-text">Current Price: ₹{current_price:,.0f}</p>
                        <p>Target Price: ₹{target_price:,.0f}</p>
                    </div>
                    <a href="{url}" class="btn">Buy Now</a>
                </div>
            </div>
        </body>
        </html>
        """

        success = await self._send_email_base(email, subject, body_plain, html_body)
        
        # Record the alert
        record = AlertRecord(
            product_id=product_id,
            product_name=product_name,
            price=current_price,
            target_price=target_price,
            alert_type=AlertType.EMAIL,
            success=success,
            error_message=None if success else "Failed to send email. Check logs."
        )
        storage_service.add_alert_record(record)
        return success

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
        msg = f"🛒 *PRICE NINJA ALERT* 🎯\n\n📉 *PRICE DROP!*\n📦 {product_name}\n💰 Current: ₹{current_price:,.0f}\n🎯 Target: ₹{target_price:,.0f}\n\n🔗 Buy Now: {url}"
        
        success = await self._send_whatsapp_base(phone, msg)
        
        record = AlertRecord(
            product_id=product_id,
            product_name=product_name,
            price=current_price,
            target_price=target_price,
            alert_type=AlertType.WHATSAPP,
            success=success,
            error_message=None if success else "Failed to send WhatsApp. Check sandbox/joined status."
        )
        storage_service.add_alert_record(record)
        return success

    async def check_and_alert(self, product_id, product_name, current_price, target_price, url, email="", whatsapp="", email_enabled=True, whatsapp_enabled=False, last_alert_price=None, starting_price=None, expires_at=None):
        """Check if price dropped below target and send alerts."""
        if expires_at and expires_at < datetime.now(): return 0
        if current_price >= target_price: return 0
        # Prevent spamming if price fluctuates by < 1%
        if last_alert_price is not None and abs(current_price - last_alert_price) < (last_alert_price * 0.01): return 0
        
        sent = 0
        if email_enabled and email:
            if await self.send_email_alert(email, product_name, current_price, target_price, url, product_id, starting_price):
                sent += 1

        if whatsapp_enabled and whatsapp:
            if await self.send_whatsapp_alert(whatsapp, product_name, current_price, target_price, url, product_id, starting_price):
                sent += 1
        return sent

    async def send_registration_confirmation(self, product_name, target_price, current_price, email="", whatsapp="", email_enabled=True, whatsapp_enabled=False, product_id="", expires_at=None):
        """Send a registration confirmation."""
        sent = 0
        price_str = f"₹{current_price:,.0f}" if current_price else "Fetching..."
        expiry_str = f"Tracking until: {expires_at.strftime('%d %b %Y')}" if expires_at else "Tracking until you stop it."

        if email_enabled and email:
            logger.info(f"Triggering email confirmation for {email}")
            subject = f"🥷 Tracker Active: {product_name[:30]}..."
            body_plain = f"PRICE NINJA\n\nTracking started for {product_name}.\nCurrent: {price_str}\nTarget: ₹{target_price:,.0f}\n{expiry_str}"
            
            # Simple but premium HTML
            html_body = f"""
            <html><body style="font-family: sans-serif; background: #0f172a; color: white; padding: 20px;">
                <div style="background: #1e293b; padding: 30px; border-radius: 12px; border: 1px solid #334155;">
                    <h1 style="color: #8b5cf6;">🥷 Tracking Started!</h1>
                    <p>We are now watching the price for:</p>
                    <div style="font-weight: bold; margin: 15px 0;">{product_name}</div>
                    <div style="padding: 15px; background: rgba(139, 92, 246, 0.1); border-left: 4px solid #8b5cf6;">
                        <p>Starting Price: {price_str}</p>
                        <p>Target Price: <strong>₹{target_price:,.0f}</strong></p>
                    </div>
                    <p style="font-size: 14px; color: #94a3b8; margin-top: 20px;">{expiry_str}</p>
                </div>
            </body></html>
            """
            if await self._send_email_base(email, subject, body_plain, html_body):
                sent += 1

        if whatsapp_enabled and whatsapp:
            logger.info(f"Triggering WhatsApp confirmation for {whatsapp}")
            wa_msg = f"🥷 *PRICE NINJA* 🎯\n\nTracking started for:\n*{product_name}*\n\n💰 Current: {price_str}\n🎯 Target: *₹{target_price:,.0f}*\n\n_We will notify you immediately when the price drops!_"
            if await self._send_whatsapp_base(whatsapp, wa_msg):
                sent += 1

        return sent

alert_service = AlertService()

