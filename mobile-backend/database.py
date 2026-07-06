from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# ---------------------------
# DATABASE CONFIGURATION
# ---------------------------
DB_USER = "postgres"
DB_PASSWORD = "1234"
DB_HOST = "127.0.0.1"
DB_PORT = "5432"
DB_NAME = "Dreamroute"

DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# ---------------------------
# ENGINE AND SESSION
# ---------------------------
engine = create_engine(DATABASE_URL, echo=True)  # echo=True helps for debugging queries
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ---------------------------
# BASE MODEL
# ---------------------------
Base = declarative_base()

# ---------------------------
# DEPENDENCY FOR FASTAPI
# ---------------------------
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# from sqlalchemy import create_engine
# from sqlalchemy.ext.declarative import declarative_base
# from sqlalchemy.orm import sessionmaker

# DB_USER = "postgres"
# DB_PASSWORD = "1234"
# DB_HOST = "127.0.0.1"
# DB_PORT = "5432"
# DB_NAME = "Dreamroute"

# DATABASE_URL = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# engine = create_engine(DATABASE_URL)
# SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
# Base = declarative_base()  # <-- define Base here

# def get_db():
#     db = SessionLocal()
#     try:
#         yield db
#     finally:
#         db.close()
