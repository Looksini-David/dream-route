from pydantic import BaseModel, EmailStr
from models import RoleEnum  # ensure path correct relative to where this file lives
from typing import List, Optional

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: str
    school: str | None = None
    education_level: str | None = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    role: str

class UserRegisterSchema(BaseModel):
    name: str
    email: EmailStr
    password: str
    role: RoleEnum
    qualification: Optional[str] = None
    location: Optional[str] = None
    resume_url: Optional[str] = None
    skills: Optional[List[str]] = None  # allows passing list of skills
    
class AnalysisOut(BaseModel):
    score: int
    matched_skills: List[str]
    missing_skills: List[str]
    domain: Optional[str]
    tips: List[str]
    matched_percent: float

class UploadResponse(BaseModel):
    detail: str
    resume_url: str
    resumerule_id: str