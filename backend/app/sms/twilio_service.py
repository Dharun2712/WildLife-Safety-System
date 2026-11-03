"""
ForestGuard - Twilio SMS Service
Sends emergency alert SMS messages to tourist emergency contacts
when a dangerous wildlife detection occurs nearby.
"""

import logging
from datetime import datetime, timezone
from typing import List, Optional

from twilio.rest import Client

from app.config.settings import settings

logger = logging.getLogger("forestguard.sms")


class TwilioSMSService:
    """Twilio SMS client for sending WildGuard emergency alerts."""

    def __init__(self):
        self._client: Optional[Client] = None
        self._initialized = False

    def _ensure_client(self):
        """Lazily initialize the Twilio client."""
        if not self._initialized:
            try:
                if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN:
                    self._client = Client(
                        settings.TWILIO_ACCOUNT_SID,
                        settings.TWILIO_AUTH_TOKEN,
                    )
                    self._initialized = True
                    logger.info("✅ Twilio SMS client initialized")
                else:
                    logger.warning("⚠️ Twilio credentials not configured — SMS alerts disabled")
            except Exception as e:
                logger.error(f"❌ Failed to initialize Twilio client: {e}")

    def _format_phone(self, phone: str) -> str:
        """Ensure phone number has country code prefix."""
        phone = phone.strip().replace(" ", "").replace("-", "")
        if not phone.startswith("+"):
            # Default to India country code
            if phone.startswith("0"):
                phone = phone[1:]
            phone = f"+91{phone}"
        return phone

    def _build_alert_message(
        self,
        tourist_name: str,
        animal_name: str,
        risk_level: str,
        location: str,
        detection_time: str,
    ) -> str:
        """Build the WildGuard emergency alert message."""
        return (
            f"🚨 WILDGUARD EMERGENCY ALERT\n\n"
            f"Warning! A potentially dangerous wild animal has been detected near {tourist_name}.\n\n"
            f"👤 Tourist: {tourist_name}\n"
            f"🐘 Animal Detected: {animal_name}\n"
            f"⚠️ Risk Level: {risk_level}\n"
            f"📍 Location: {location}\n"
            f"🕒 Time: {detection_time}\n\n"
            f"Please contact the tourist immediately and follow the safety instructions. "
            f"If necessary, contact the local forest authorities.\n\n"
            f"This is an automated safety alert from WildGuard."
        )

    async def send_emergency_alert(
        self,
        phone_numbers: List[str],
        tourist_name: str,
        animal_name: str,
        risk_level: str,
        location: str,
        detection_time: Optional[str] = None,
    ) -> dict:
        """
        Send emergency SMS alert to a list of emergency contact phone numbers.

        Returns dict with success/failure counts.
        """
        self._ensure_client()

        if not self._client:
            logger.warning("⚠️ Twilio client not available — skipping SMS alerts")
            return {"sent": 0, "failed": 0, "skipped": True}

        if not phone_numbers:
            return {"sent": 0, "failed": 0, "skipped": True}

        if not detection_time:
            detection_time = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

        message_body = self._build_alert_message(
            tourist_name=tourist_name,
            animal_name=animal_name,
            risk_level=risk_level,
            location=location,
            detection_time=detection_time,
        )

        sent = 0
        failed = 0
        from_number = self._format_phone(settings.TWILIO_FROM_NUMBER)

        for phone in phone_numbers:
            try:
                to_number = self._format_phone(phone)
                message = self._client.messages.create(
                    body=message_body,
                    from_=from_number,
                    to=to_number,
                )
                logger.info(
                    f"✅ [SMS SENT] Alert to {to_number} for tourist '{tourist_name}' — SID: {message.sid}"
                )
                sent += 1
            except Exception as e:
                logger.error(f"❌ [SMS FAILED] Could not send to {phone}: {e}")
                failed += 1

        return {"sent": sent, "failed": failed, "skipped": False}


# Singleton service instance
sms_service = TwilioSMSService()

