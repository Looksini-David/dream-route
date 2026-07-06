from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form, Body
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from database import get_db
from models import User, RoleEnum, ResumeRules
from auth import hash_password, verify_password, create_access_token, get_current_user
from fastapi.responses import Response
from fastapi import UploadFile, File, HTTPException
from datetime import datetime

router = APIRouter(tags=["users"])


# ---------------- TOKEN MODEL ---------------- #
class Token(BaseModel):
    access_token: str
    token_type: str
    role: str


# ---------------- LOGIN REQUEST MODEL ---------------- #
class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# ---------------- RESUME DOWNLOAD ---------------- #
@router.get("/resume/{user_id}")
def get_resume(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user or user.resume_blob is None:
        raise HTTPException(status_code=404, detail="Resume not found")

    return Response(content=user.resume_blob, media_type="application/pdf")


# ---------------- REGISTER ---------------- #
@router.post("/register")
async def register_user(
    name: str = Form(...),
    email: EmailStr = Form(...),
    password: str = Form(...),
    role: RoleEnum = Form(...),
    qualification: str | None = Form(None),
    location: str | None = Form(None),
    resume: UploadFile | None = File(None),
    db: Session = Depends(get_db),
):
    existing = db.query(User).filter(User.email == email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pw = hash_password(password)

    # initialize before usage
    resume_blob = None
    resume_content = None

    if resume:
        resume_content = await resume.read()
        resume_blob = resume_content

    new_user = User(
        name=name,
        email=email,
        password=hashed_pw,
        role=role,
        qualification=qualification,
        location=location,
        resume_blob=resume_blob,
        join_date=datetime.now(),
        status="active"
    )

    db.add(new_user)
    try:
        db.commit()
        db.refresh(new_user)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Error saving user: {e}")

    # If resume was provided, save to disk and create a ResumeRules record
    if resume and resume_content:
        import os
        uploads_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "resumes")
        os.makedirs(uploads_dir, exist_ok=True)
        safe_name = resume.filename.replace(" ", "_") if resume.filename else "resume.pdf"
        saved_filename = f"{new_user.user_id}_{safe_name}"
        saved_path = os.path.join(uploads_dir, saved_filename)
        try:
            with open(saved_path, "wb") as f:
                f.write(resume_content)
        except Exception as e:
            print(f"Error saving resume to disk: {e}")

        # store relative path/URL in ResumeRules with pending status
        relative_url = f"uploads/resumes/{saved_filename}"
        rr = ResumeRules(
            user_id=new_user.user_id,
            resume_url=relative_url,
            resume_blob=resume_content,
            analysis_status="pending"  # Will be analyzed after quiz domain is determined
        )
        db.add(rr)
        try:
            db.commit()
            db.refresh(rr)
        except Exception as e:
            db.rollback()
            print(f"Error saving ResumeRules entry: {e}")

    return {
        "message": "User registered successfully",
        "user_id": new_user.user_id,
        "resume_uploaded": resume is not None
    }


# ---------------- LOGIN ---------------- #
@router.post("/login", response_model=Token)
def login_user(request: LoginRequest, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == request.email).first()
    if not db_user:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    # Ensure password is treated as a string (prevents Pylance Column[str] warning)
    hashed_pw: str = str(db_user.password)

    if not verify_password(request.password, hashed_pw):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    role_value = db_user.role.value if hasattr(db_user.role, "value") else str(db_user.role)

    token = create_access_token({
        "sub": db_user.email,
        "role": role_value
    })

    return {
        "access_token": token,
        "token_type": "bearer",
        "role": role_value
    }

# ---------------- UPLOAD PROFILE IMAGE ---------------- #
ALLOWED_IMAGE_TYPES = ["image/png", "image/jpeg", "image/jpg", "image/gif", "image/webp"]

@router.post("/profile-image/upload/")
async def upload_profile_image(
    image: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # Read image content
        content = await image.read()
        if not content:
            raise HTTPException(status_code=400, detail="Image file is empty")
        
        print(f"[DEBUG] Uploading image for user {current_user.user_id}, size: {len(content)} bytes, content_type: {image.content_type}")
        
        # Fetch fresh user from database to avoid detached instance errors
        fresh_user = db.query(User).filter(User.user_id == current_user.user_id).first()
        if not fresh_user:
            raise HTTPException(status_code=404, detail="User not found")
        
        fresh_user.profile_image = content
        db.add(fresh_user)
        db.commit()
        db.refresh(fresh_user)
        
        print(f"[DEBUG] Image uploaded successfully for user {current_user.user_id}")
        return {"message": "Profile image updated successfully", "size": len(content)}
    except HTTPException:
        raise
    except Exception as e:
        print(f"[DEBUG] Image upload error: {str(e)}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to upload image: {str(e)}")

# ---------------- GET PROFILE IMAGE ---------------- #
@router.get("/profile-image/{user_id}/")
def get_profile_image(user_id: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.user_id == user_id).first()

    if user and user.profile_image:
        return Response(content=user.profile_image, media_type="image/png")

    raise HTTPException(status_code=404, detail="Image not found")

#---------------FRESHER PROFILE----------------------
@router.get("/fresher/profile/")
def get_fresher_profile(current_user: User = Depends(get_current_user)):
    if current_user.role != RoleEnum.fresher:
        raise HTTPException(status_code=403, detail="Access denied")
    
    resume_link = None
    if current_user.resume_blob is not None:
        resume_link = f"/resume/{current_user.user_id}"

    return {
        "user_id": current_user.user_id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role.value,
        "qualification": current_user.qualification,
        "location": current_user.location,
        "resume_url": resume_link,
        "skills": current_user.skills.split(",") if current_user.skills else [],
        "join_date": current_user.join_date,
    }
    
#----------------STUDENT PROFILE------------------------------------
@router.get("/student/profile/")
def get_student_profile(current_user: User = Depends(get_current_user)):
    if current_user.role != RoleEnum.student:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Students don't have resume
    return {
        "user_id": current_user.user_id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role.value,
        "qualification": current_user.qualification,
        "location": current_user.location,
        "skills": current_user.skills.split(",") if current_user.skills else [],
        "join_date": current_user.join_date,
    }

# ------------------ UPDATE FRESHER PROFILE ------------------
@router.put("/fresher/profile/update/")
def update_fresher_profile(
    data: dict = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != RoleEnum.fresher:
        raise HTTPException(status_code=403, detail="Access denied")
    # Update fields if provided in JSON body
    name = data.get("name")
    email = data.get("email")
    qualification = data.get("qualification")
    location = data.get("location")
    skills = data.get("skills")
    join_date = data.get("join_date")

    if name is not None:
        current_user.name = name
    if email is not None:
        current_user.email = email
    if qualification is not None:
        current_user.qualification = qualification
    if location is not None:
        current_user.location = location
    if skills is not None:
        # accept list or comma-separated string
        if isinstance(skills, list):
            current_user.skills = ",".join(skills)
        else:
            current_user.skills = skills
    if join_date is not None:
        current_user.join_date = join_date

    db.commit()
    db.refresh(current_user)
    return {"message": "Profile updated successfully"}

# ------------------ UPDATE STUDENT PROFILE ------------------
@router.put("/student/profile/update/")
def update_student_profile(
    data: dict = Body(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.role != RoleEnum.student:
        raise HTTPException(status_code=403, detail="Access denied")
    # Update fields if provided in JSON body
    name = data.get("name")
    email = data.get("email")
    qualification = data.get("qualification")
    location = data.get("location")
    skills = data.get("skills")
    join_date = data.get("join_date")

    if name is not None:
        current_user.name = name
    if email is not None:
        current_user.email = email
    if qualification is not None:
        current_user.qualification = qualification
    if location is not None:
        current_user.location = location
    if skills is not None:
        if isinstance(skills, list):
            current_user.skills = ",".join(skills)
        else:
            current_user.skills = skills
    if join_date is not None:
        current_user.join_date = join_date

    db.commit()
    db.refresh(current_user)
    return {"message": "Profile updated successfully"}
