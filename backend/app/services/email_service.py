import json
import logging
import smtplib
import urllib.request
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

from app.core.config import settings

logger = logging.getLogger("priora.email")


class EmailService:
    """
    Email service handling transactional emails for Priora.
    Supports Resend API, standard SMTP (TLS/SSL), with local dev logging fallback.
    """

    def send_verification_otp(self, to_email: str, otp_code: str, full_name: str | None = None) -> bool:
        """
        Send 6-digit verification OTP code to the recipient.
        """
        display_name = full_name if full_name else "Productivity Enthusiast"
        subject = f"{otp_code} is your Priora verification code"

        html_content = f"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{subject}</title>
</head>
<body style="margin: 0; padding: 0; background-color: #090D16; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #F8FAFC;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #090D16; padding: 40px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 520px; background: #0F172A; border-radius: 16px; border: 1px solid #1E293B; overflow: hidden; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);" cellspacing="0" cellpadding="0">
          <!-- Header Banner -->
          <tr>
            <td style="padding: 32px 32px 20px 32px; text-align: center; border-bottom: 1px solid #1E293B; background: linear-gradient(180deg, rgba(245, 158, 11, 0.08) 0%, rgba(15, 23, 42, 0) 100%);">
              <div style="font-size: 28px; font-weight: 800; color: #F59E0B; letter-spacing: -0.5px;">⚡ Priora</div>
              <div style="font-size: 13px; color: #94A3B8; margin-top: 4px; font-weight: 500;">Plan. Prioritize. Progress.</div>
            </td>
          </tr>

          <!-- Content Body -->
          <tr>
            <td style="padding: 32px;">
              <h1 style="font-size: 20px; font-weight: 700; color: #F8FAFC; margin: 0 0 12px 0;">Verify your email address</h1>
              <p style="font-size: 14px; line-height: 22px; color: #CBD5E1; margin: 0 0 24px 0;">
                Hello {display_name},<br>
                Thank you for joining Priora. Please use the 6-digit verification code below to activate your account and start organizing your workspace.
              </p>

              <!-- OTP Code Display Box -->
              <div style="background-color: #090D16; border: 1.5px solid #F59E0B; border-radius: 12px; padding: 20px; text-align: center; margin: 24px 0;">
                <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: 800; letter-spacing: 10px; color: #FBBF24; display: inline-block; margin-left: 10px;">{otp_code}</span>
              </div>

              <p style="font-size: 13px; color: #94A3B8; line-height: 20px; margin: 20px 0 0 0;">
                ⏱️ <strong>This code will expire in {settings.OTP_EXPIRE_MINUTES} minutes.</strong><br>
                If you did not request this verification, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 20px 32px; background-color: #0B1120; border-top: 1px solid #1E293B; text-align: center;">
              <p style="font-size: 12px; color: #64748B; margin: 0;">
                © 2026 Priora Productivity Platform • Secure Identity Protection
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
"""
        plain_content = f"Your Priora verification code is: {otp_code}. This code expires in {settings.OTP_EXPIRE_MINUTES} minutes."

        # 1. Resend API Delivery
        if settings.RESEND_API_KEY:
            sent = self._send_via_resend(to_email, subject, html_content, plain_content)
            if sent:
                return True

        # 2. Standard SMTP Delivery
        if settings.SMTP_HOST and settings.SMTP_USER:
            sent = self._send_via_smtp(to_email, subject, html_content, plain_content)
            if sent:
                return True

        # 3. Dev Logger Fallback
        logger.info(f"📧 [DEV EMAIL SERVICE] OTP Code for {to_email} is: {otp_code}")
        print(f"\n========================================\n📧 [DEV EMAIL] To: {to_email}\n🔑 OTP Code: {otp_code} (Valid for {settings.OTP_EXPIRE_MINUTES}m)\n========================================\n")
        return True

    def _send_via_resend(self, to_email: str, subject: str, html: str, text: str) -> bool:
        """Send email using Resend HTTP API."""
        try:
            url = "https://api.resend.com/emails"
            headers = {
                "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                "Content-Type": "application/json",
                "User-Agent": "Priora-App/1.1.3 (https://priora.app)",
            }
            payload = {
                "from": f"{settings.EMAILS_FROM_NAME} <{settings.EMAILS_FROM_EMAIL}>",
                "to": [to_email],
                "subject": subject,
                "html": html,
                "text": text,
            }
            data = json.dumps(payload).encode("utf-8")
            req = urllib.request.Request(url, data=data, headers=headers, method="POST")
            with urllib.request.urlopen(req, timeout=10) as response:
                if response.status in (200, 201):
                    logger.info(f"Successfully sent OTP to {to_email} via Resend")
                    return True
                logger.error(f"Resend API returned status: {response.status}")
                return False
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8") if e.fp else str(e)
            logger.error(f"Failed to send email via Resend HTTP {e.code}: {error_body}")
            print(f"\n⚠️ [RESEND NOTICE] Could not deliver to {to_email} via Resend sandbox: {error_body}")
            return False
        except Exception as e:
            logger.error(f"Failed to send email via Resend: {e!s}")
            return False

    def _send_via_smtp(self, to_email: str, subject: str, html: str, text: str) -> bool:
        """Send email using standard SMTP with TLS / SSL fallback."""
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = f"{settings.EMAILS_FROM_NAME} <{settings.EMAILS_FROM_EMAIL}>"
        msg["To"] = to_email

        part1 = MIMEText(text, "plain")
        part2 = MIMEText(html, "html")
        msg.attach(part1)
        msg.attach(part2)

        # Try configured port first, fallback between 465 (SSL) and 587 (TLS)
        ports_to_try = [settings.SMTP_PORT, 465, 587]
        seen = set()
        ports_to_try = [p for p in ports_to_try if not (p in seen or seen.add(p))]

        for port in ports_to_try:
            try:
                if port == 465:
                    server = smtplib.SMTP_SSL(settings.SMTP_HOST, 465, timeout=12)
                else:
                    server = smtplib.SMTP(settings.SMTP_HOST, port, timeout=12)
                    server.starttls()

                if settings.SMTP_USER and settings.SMTP_PASSWORD:
                    server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)

                server.sendmail(settings.EMAILS_FROM_EMAIL, [to_email], msg.as_string())
                server.quit()
                logger.info(f"Successfully sent OTP to {to_email} via SMTP on port {port}")
                return True
            except Exception as e:
                logger.warning(f"SMTP delivery attempt to {to_email} failed on port {port}: {e!s}")
                continue

        logger.error(f"Failed to send email to {to_email} via SMTP on all attempted ports.")
        return False


email_service = EmailService()
