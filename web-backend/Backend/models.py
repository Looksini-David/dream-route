from sqlalchemy import TIMESTAMP, Column, String, Enum
from database import Base  # <-- import Base from database.py
import enum

class RoleEnum(str, enum.Enum):
    student = "student"
    fresher = "fresher"

class User(Base):
    __tablename__ = "users"

    user_id = Column(String(5), primary_key=True)  # Generated in Python
    name = Column(String(50), nullable=False)
    email = Column(String(50), unique=True, nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(Enum(RoleEnum), nullable=False)
    qualification = Column(String(50), nullable=True)
    location = Column(String(100), nullable=True)

class AdminRoleEnum(str, enum.Enum):
    superadmin = "superadmin"
    subadmin = "subadmin"

class AdminUsers(Base):
    __tablename__ = "AdminUsers"

    admin_id = Column(String(10), primary_key=True)
    name = Column(String(255))
    email = Column(String(255), unique=True)
    password = Column(String(255))
    role = Column(Enum(AdminRoleEnum))
    created_at = Column(TIMESTAMP)