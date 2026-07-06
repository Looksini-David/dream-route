# from fastapi import APIRouter, Depends, HTTPException, Form
# from sqlalchemy.orm import Session
# from models.admin import AdminUser
# from database import get_db
# from auth import verify_password, create_access_token, get_password_hash
# import secrets
# import smtplib
# from datetime import datetime
# from email.mime.text import MIMEText
# from email.mime.multipart import MIMEMultipart
# import os

# router = APIRouter(prefix="/admin", tags=["Admin"])

# @router.post("/login")
# def admin_login(email: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
#     admin = db.query(AdminUser).filter(AdminUser.email == email).first()
#     if not admin:
#         raise HTTPException(status_code=401, detail="Invalid email or password")
    
#     if not verify_password(password, admin.password):
#         raise HTTPException(status_code=401, detail="Invalid email or password")

#     token = create_access_token({
#         "sub": admin.email,
#         "admin_id": admin.admin_id,
#         "role": admin.role.value
#     })

#     return {
#         "access_token": token,
#         "token_type": "bearer",
#         "admin": {
#             "id": admin.admin_id,
#             "name": admin.name,
#             "email": admin.email,
#             "role": admin.role.value
#         }
#     }

# @router.post("/forgot-password")
# def forgot_password(email: str = Form(...), db: Session = Depends(get_db)):
#     """Send password reset token to admin email"""
#     admin = db.query(AdminUser).filter(AdminUser.email == email).first()
#     if not admin:
#         # Don't reveal if email exists or not for security
#         return {"message": "If the email exists, a reset link has been sent"}
    
#     # Generate a secure reset token
#     reset_token = secrets.token_urlsafe(32)
    
#     # For development: Store token temporarily (in production, use database with expiration)
#     if not hasattr(forgot_password, 'reset_tokens'):
#         forgot_password.reset_tokens = {}
    
#     forgot_password.reset_tokens[reset_token] = {
#         'email': email,
#         'created_at': datetime.now()
#     }
    
#     try:
#         # Send email (simulation for development)
#         send_reset_email(admin.email, admin.name, reset_token)
#         return {
#             "message": "Password reset instructions sent to your email",
#             "reset_token": reset_token,  # In development only
#             "reset_url": f"http://127.0.0.1:51228/forgot_password.html?token={reset_token}"
#         }
#     except Exception as e:
#         print(f"Email error: {e}")
#         # Still return success for development
#         return {
#             "message": "Password reset instructions sent to your email", 
#             "reset_token": reset_token,
#             "reset_url": f"http://127.0.0.1:51228/forgot_password.html?token={reset_token}"
#         }

# @router.post("/reset-password")
# def reset_password(
#     email: str = Form(...), 
#     new_password: str = Form(...),
#     confirm_password: str = Form(...),
#     token: str = Form(None),
#     db: Session = Depends(get_db)
# ):
#     """Reset admin password"""
#     # For development: allow reset without token if token is provided
#     if token:
#         # Validate token
#         if not hasattr(forgot_password, 'reset_tokens') or token not in forgot_password.reset_tokens:
#             raise HTTPException(status_code=400, detail="Invalid or expired reset token")
        
#         token_data = forgot_password.reset_tokens[token]
        
#         # Check if token is for the correct email
#         if token_data['email'] != email:
#             raise HTTPException(status_code=400, detail="Token does not match email")
        
#         # Check if token is not too old (1 hour expiration)
#         if (datetime.now() - token_data['created_at']).total_seconds() > 3600:
#             del forgot_password.reset_tokens[token]
#             raise HTTPException(status_code=400, detail="Reset token has expired")
    
#     if new_password != confirm_password:
#         raise HTTPException(status_code=400, detail="Passwords do not match")
    
#     if len(new_password) < 6:
#         raise HTTPException(status_code=400, detail="Password must be at least 6 characters long")
    
#     admin = db.query(AdminUser).filter(AdminUser.email == email).first()
#     if not admin:
#         raise HTTPException(status_code=404, detail="Admin not found")
    
#     # Hash the new password using the same method as auth.py
#     hashed_password = get_password_hash(new_password)
    
#     # Update password in database
#     admin.password = hashed_password
#     db.commit()
    
#     # Remove used token if it exists
#     if token and hasattr(forgot_password, 'reset_tokens') and token in forgot_password.reset_tokens:
#         del forgot_password.reset_tokens[token]
    
#     return {"message": "Password reset successfully. You can now login with your new password."}

# @router.post("/google-login")
# def google_login(google_token: str = Form(...), db: Session = Depends(get_db)):
#     """Login with Google OAuth token"""
#     try:
#         # In a real application, you would verify the Google token
#         # For now, we'll simulate this functionality
        
#         # Extract email from token (this is simulated)
#         # You would use Google's token verification service
#         email = extract_email_from_google_token(google_token)
        
#         admin = db.query(AdminUser).filter(AdminUser.email == email).first()
#         if not admin:
#             raise HTTPException(status_code=404, detail="Admin not found with this Google account")
        
#         token = create_access_token({
#             "sub": admin.email,
#             "admin_id": admin.admin_id,
#             "role": admin.role.value
#         })
        
#         return {
#             "access_token": token,
#             "token_type": "bearer",
#             "admin": {
#                 "id": admin.admin_id,
#                 "name": admin.name,
#                 "email": admin.email,
#                 "role": admin.role.value
#             }
#         }
#     except Exception as e:
#         raise HTTPException(status_code=401, detail="Invalid Google token")

# def send_reset_email(email: str, name: str, reset_token: str):
#     """Send password reset email (simulation)"""
#     # This is a simulation - in production you need to configure SMTP
#     print(f"📧 Sending reset email to {email}")
#     print(f"Reset token: {reset_token}")
#     print(f"Reset link: http://localhost:8080/forgot_password.html?token={reset_token}")
    
#     # In production, configure your SMTP settings and send actual email
#     # smtp_server = "smtp.gmail.com"
#     # smtp_port = 587
#     # sender_email = "your-email@gmail.com"
#     # sender_password = "your-app-password"
    
# @router.get("/profile")
# def get_admin_profile(db: Session = Depends(get_db)):
#     """Get admin profile information"""
#     # For demo, get the first admin user
#     admin = db.query(AdminUser).first()
#     if not admin:
#         raise HTTPException(status_code=404, detail="Admin not found")
    
#     return {
#         "admin_id": admin.admin_id,
#         "name": admin.name,
#         "email": admin.email,
#         "role": admin.role.value,
#         "profile_picture": getattr(admin, 'profile_picture', None),
#         "created_at": getattr(admin, 'created_at', None),
#         "settings": {
#             "theme": "light",
#             "notifications": True,
#             "language": "en",
#             "timezone": "UTC"
#         }
#     }

# @router.put("/profile")
# def update_admin_profile(
#     name: str = Form(...),
#     profile_picture: str = Form(None),
#     db: Session = Depends(get_db)
# ):
#     """Update admin profile information"""
#     # For demo, get the first admin user
#     admin = db.query(AdminUser).first()
#     if not admin:
#         raise HTTPException(status_code=404, detail="Admin not found")
    
#     # Update profile fields
#     admin.name = name
#     if profile_picture:
#         # In a real app, you'd handle file upload properly
#         admin.profile_picture = profile_picture
    
#     db.commit()
    
#     return {
#         "message": "Profile updated successfully",
#         "admin": {
#             "admin_id": admin.admin_id,
#             "name": admin.name,
#             "email": admin.email,
#             "role": admin.role.value,
#             "profile_picture": getattr(admin, 'profile_picture', None)
#         }
#     }

# @router.put("/settings")
# def update_admin_settings(
#     theme: str = Form("light"),
#     notifications: bool = Form(True),
#     language: str = Form("en"),
#     timezone: str = Form("UTC"),
#     db: Session = Depends(get_db)
# ):
#     """Update admin settings"""
#     # For demo, we'll store settings in a simple way
#     # In production, you might have a separate settings table
    
#     settings = {
#         "theme": theme,
#         "notifications": notifications,
#         "language": language,
#         "timezone": timezone,
#         "updated_at": datetime.now().isoformat()
#     }
    
#     return {
#         "message": "Settings updated successfully",
#         "settings": settings
#     }

# def extract_email_from_google_token(token: str):
#     """Extract email from Google OAuth token (simulation)"""
#     # This is a simulation - in production use Google's token verification
#     # You would use google.oauth2.id_token.verify_oauth2_token()
    
#     # For demo purposes, if token contains "admin@example.com", return it
#     if "admin" in token:
#         return "admin@example.com"
    
#     raise ValueError("Invalid token")


# new code
"""
Admin Login Route
File location: Backend/routers/login.py
(matches your main.py -> from routers import login)
"""
from fastapi import APIRouter, HTTPException, Form, Depends, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr, field_validator

from database import get_db
from models.admin import AdminUser
from auth import verify_password, create_access_token

router = APIRouter(prefix="/admin", tags=["Admin Auth"])


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