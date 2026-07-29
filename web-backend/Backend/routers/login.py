"""
Admin Login Route
File location: Backend/routers/login.py
(matches your main.py -> from routers import login)
"""
import secrets
from datetime import datetime

from fastapi import APIRouter, HTTPException, Form, Depends, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, field_validator

from database import get_db
from models.admin import AdminUser
from auth import verify_password, create_access_token, get_password_hash
from email_utils import send_otp_email

router = APIRouter(prefix="/admin", tags=["Admin Auth"])

# In-memory store for password reset OTPs (dev only - resets on server restart)
_reset_otps: dict[str, dict] = {}
OTP_EXPIRY_SECONDS = 600  # 10 minutes


# ---------------------------------------------------
# Pydantic model — validates shape/format of input
# ---------------------------------------------------
class LoginRequest(BaseModel):
    email: EmailStr          # auto-validates proper email format
    password: str

    @field_validator("password")
    @classmethod
    def password_not_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Password cannot be empty")
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v


# ---------------------------------------------------
# POST /admin/login
# ---------------------------------------------------
@router.post("/login")
async def admin_login(
    email: str = Form(...),
    password: str = Form(...),
    db: Session = Depends(get_db),
):
    # 1) Validate input shape (email format, password length) — raises 422 if invalid
    try:
        data = LoginRequest(email=email, password=password)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    # 2) Look up admin by email
    admin = db.query(AdminUser).filter(AdminUser.email == data.email).first()
    if not admin:
        # Don't reveal whether email or password was wrong
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # 3) Verify password against argon2 hash
    if not verify_password(data.password, str(admin.password)):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )

    # 4) Issue JWT with role + admin_id in claims (useful for role-based access later)
    access_token = create_access_token(
        data={
            "sub": admin.email,
            "role": admin.role.value,
            "admin_id": admin.admin_id,
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "role": admin.role.value,
    }


# ---------------------------------------------------
# GET /admin/profile
# ---------------------------------------------------
@router.get("/profile")
def get_admin_profile(db: Session = Depends(get_db)):
    """Get admin profile information"""
    admin = db.query(AdminUser).first()
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    return {
        "admin_id": admin.admin_id,
        "name": admin.name,
        "email": admin.email,
        "role": admin.role.value,
        "profile_picture": getattr(admin, "profile_picture", None),
        "created_at": admin.created_at,
    }


# ---------------------------------------------------
# PUT /admin/profile
# ---------------------------------------------------
@router.put("/profile")
def update_admin_profile(
    name: str = Form(...),
    profile_picture: str = Form(None),
    db: Session = Depends(get_db),
):
    """Update admin profile information"""
    admin = db.query(AdminUser).first()
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    admin.name = name
    if profile_picture:
        admin.profile_picture = profile_picture

    db.commit()

    return {
        "message": "Profile updated successfully",
        "admin": {
            "admin_id": admin.admin_id,
            "name": admin.name,
            "email": admin.email,
            "role": admin.role.value,
            "profile_picture": getattr(admin, "profile_picture", None),
        },
    }


# ---------------------------------------------------
# PUT /admin/settings
# ---------------------------------------------------
@router.put("/change-password")
def change_password(
    current_password: str = Form(...),
    new_password: str = Form(...),
    confirm_password: str = Form(...),
    db: Session = Depends(get_db),
):
    """Change password for the logged-in admin, verified against their current password"""
    admin = db.query(AdminUser).first()
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    if not verify_password(current_password, str(admin.password)):
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    if new_password != confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters long")

    admin.password = get_password_hash(new_password)
    db.commit()

    return {"message": "Password changed successfully"}


@router.put("/settings")
def update_admin_settings(notifications: bool = Form(True)):
    """Update admin settings (not persisted to DB - no settings table yet)"""
    settings = {
        "notifications": notifications,
        "updated_at": datetime.now().isoformat(),
    }

    return {
        "message": "Settings updated successfully",
        "settings": settings,
    }


# ---------------------------------------------------
# POST /admin/forgot-password
# ---------------------------------------------------
@router.post("/forgot-password")
def forgot_password(email: str = Form(...), db: Session = Depends(get_db)):
    """Generate and email a 6-digit OTP for an admin email"""
    admin = db.query(AdminUser).filter(AdminUser.email == email).first()
    if not admin:
        # Don't reveal if email exists or not for security
        return {"message": "If the email exists, a reset code has been sent"}

    otp = f"{secrets.randbelow(1_000_000):06d}"
    _reset_otps[email] = {"otp": otp, "created_at": datetime.now()}

    try:
        send_otp_email(email, otp)
    except Exception as e:
        print(f"Failed to send OTP email to {email}: {e}")
        raise HTTPException(status_code=500, detail="Failed to send reset email. Please try again later.")

    return {"message": "A 6-digit reset code has been sent to your email"}


# ---------------------------------------------------
# POST /admin/reset-password
# ---------------------------------------------------
@router.post("/reset-password")
def reset_password(
    email: str = Form(...),
    otp: str = Form(...),
    new_password: str = Form(...),
    confirm_password: str = Form(...),
    db: Session = Depends(get_db),
):
    """Reset admin password after verifying the emailed OTP"""
    otp_data = _reset_otps.get(email)
    if not otp_data:
        raise HTTPException(status_code=400, detail="No reset code was requested for this email")

    if (datetime.now() - otp_data["created_at"]).total_seconds() > OTP_EXPIRY_SECONDS:
        del _reset_otps[email]
        raise HTTPException(status_code=400, detail="Reset code has expired. Please request a new one.")

    if otp != otp_data["otp"]:
        raise HTTPException(status_code=400, detail="Invalid reset code")

    if new_password != confirm_password:
        raise HTTPException(status_code=400, detail="Passwords do not match")

    if len(new_password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters long")

    admin = db.query(AdminUser).filter(AdminUser.email == email).first()
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")

    admin.password = get_password_hash(new_password)
    db.commit()

    del _reset_otps[email]

    return {"message": "Password reset successfully. You can now login with your new password."}