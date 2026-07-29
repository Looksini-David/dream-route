"""
Email sending via Gmail SMTP
Used for admin password-reset OTP emails
"""
import os
import smtplib
from email.mime.text import MIMEText

SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587


def send_otp_email(to_email: str, otp: str) -> None:
    """Send a password-reset OTP code to the given email via Gmail SMTP"""
    sender_email = os.getenv("SMTP_EMAIL")
    app_password = os.getenv("SMTP_APP_PASSWORD")

    if not sender_email or not app_password:
        raise RuntimeError("SMTP_EMAIL / SMTP_APP_PASSWORD not configured in .env")

    message = MIMEText(
        f"Your DreamRoute admin password reset code is: {otp}\n\n"
        f"This code expires in 10 minutes. If you didn't request this, ignore this email."
    )
    message["Subject"] = "DreamRoute Admin - Password Reset Code"
    message["From"] = sender_email
    message["To"] = to_email

    with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
        server.starttls()
        server.login(sender_email, app_password.replace(" ", ""))
        server.sendmail(sender_email, [to_email], message.as_string())