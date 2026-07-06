# from passlib.context import CryptContext
# from datetime import datetime, timedelta
# from jose import jwt

# SECRET_KEY = "kD9$2j4@!mL8#zP0qW7vU1eR6xY5bC3f"
# ALGORITHM = "HS256"
# ACCESS_TOKEN_EXPIRE_MINUTES = 5000

# pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

# def hash_password(password: str):
#     return pwd_context.hash(password)

# def verify_password(plain_password, hashed_password):
#     return pwd_context.verify(plain_password, hashed_password)

# def create_access_token(data: dict):
#     to_encode = data.copy()
#     expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
#     to_encode.update({"exp": expire})
#     return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

"""
Authentication and Authorization Module
Handles password hashing, verification, and JWT token generation
"""
from passlib.context import CryptContext
from datetime import datetime, timedelta
from jose import jwt
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# JWT Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "kD9$2j4@!mL8#zP0qW7vU1eR6xY5bC3f")
ALGORITHM = os.getenv("ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

# Password hashing context using argon2
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against a hashed password
    
    Args:
        plain_password: The plain text password to verify
        hashed_password: The hashed password to compare against
        
    Returns:
        bool: True if password matches, False otherwise
    """
    # Handle None or empty hashed_password
    if not hashed_password or not plain_password:
        return False
    
    try:
        # Check if the hashed_password is actually a valid hash
        # If it starts with $argon2, it's a proper hash
        if hashed_password.startswith('$argon2'):
            return pwd_context.verify(plain_password, hashed_password)
        else:
            # If it's not a hash (plain text), compare directly
            # This is for backward compatibility during migration
            # In production, all passwords should be hashed
            return plain_password == hashed_password
    except Exception as e:
        # Handle UnknownHashError or any other verification errors
        # Log the error for debugging but don't expose it
        print(f"Password verification error: {type(e).__name__}")
        return False

def get_password_hash(password: str) -> str:
    """
    Hash a plain password using argon2
    
    Args:
        password: The plain text password to hash
        
    Returns:
        str: The hashed password
    """
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None) -> str:
    """
    Create a JWT access token
    
    Args:
        data: Dictionary containing the claims to encode in the token
        expires_delta: Optional custom expiration time
        
    Returns:
        str: The encoded JWT token
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt
