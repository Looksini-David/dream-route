from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor, DictCursor
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, Float
from sqlalchemy.orm import declarative_base, sessionmaker
import os

# ---------------------------
# FastAPI app & CORS
# ---------------------------
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace "*" with frontend URL in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------
# Environment / DB Config
# ---------------------------
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "1234")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "Dreamroute")

# ---------------------------
# psycopg2 connection (users & resumes)
# ---------------------------
def get_db_connection():
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )
    return conn

# ---------------------------
# SQLAlchemy setup (quiz scores)
# ---------------------------
SQLALCHEMY_DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ---------------------------
# QuizScore model (updated table)
# ---------------------------
class QuizScore(Base):
    __tablename__ = "quiz_scores_analysis"  # updated table name
    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(String)
    user_id = Column(String)
    user_name = Column(String)
    quiz_title = Column(String)
    quiz_score = Column(Float)
    result = Column(String)

# Create tables if not exists
Base.metadata.create_all(bind=engine)

# ---------------------------
# Routes
# ---------------------------

# --- Users ---
@app.get("/users")
def get_users():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=DictCursor)
    cur.execute("""
        SELECT user_id, name, email, resume_url, role, status, join_date, profile_image
        FROM users
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    users = []
    for row in rows:
        users.append({
            "user_id": row["user_id"],
            "name": row["name"],
            "email": row["email"],
            "resume": row["resume_url"],
            "role": row["role"],
            "status": row["status"],
            "joined_date": row["join_date"].strftime("%Y-%m-%d") if row["join_date"] else "",
            "image_url": row["profile_image"] or "path_to_default_image.jpg"
        })
    return users

# --- Resumes (updated for resumes_rules) ---
@app.get("/resumes")
def get_resumes():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM resumes_rules ORDER BY resume_id ASC")  # updated table name
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows

# --- Quiz Scores (updated for quiz_scores_analysis) ---
@app.get("/quiz-scores")
def get_quiz_scores():
    db = SessionLocal()
    scores = db.query(QuizScore).all()
    db.close()
    return [
        {
            "quiz_id": s.quiz_id,
            "user_id": s.user_id,
            "user_name": s.user_name,
            "quiz_title": s.quiz_title,
            "quiz_score": s.quiz_score,
            "result": s.result,
        }
        for s in scores
    ]

# ---------------------------
# Run locally
# ---------------------------
# if __name__ == "__main__":
#     import uvicorn
#     uvicorn.run(app, host="127.0.0.1", port=8000, reload=True)
