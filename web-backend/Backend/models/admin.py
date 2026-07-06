# from sqlalchemy import Column, String, Enum, TIMESTAMP, func
# from database import Base
# import enum

# class AdminRole(enum.Enum):
#     superadmin = "superadmin"
#     subadmin = "subadmin"

# class AdminUser(Base):
#     __tablename__ = "adminusers"

#     admin_id = Column(String(10), primary_key=True)
#     name = Column(String(255), nullable=False)
#     email = Column(String(255), unique=True, nullable=False)
#     password = Column(String(255), nullable=False)
#     role = Column(Enum(AdminRole), nullable=False)
#     created_at = Column(TIMESTAMP, server_default=func.now())

"""
Admin User Model
Database model for admin users with roles and authentication
"""
from sqlalchemy import Column, String, Enum, TIMESTAMP, func
from database import Base
import enum

class AdminRoleEnum(str, enum.Enum):
    """Admin role enumeration"""
    superadmin = "superadmin"
    subadmin = "subadmin"

class AdminUser(Base):
    """
    AdminUser model for managing admin authentication and roles
    """
    __tablename__ = "adminusers"  # Match the table name in database

    admin_id = Column(String(10), primary_key=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password = Column(String(255), nullable=False)
    role = Column(Enum(AdminRoleEnum), nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
