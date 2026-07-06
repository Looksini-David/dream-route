from fastapi import APIRouter
from fastapi.responses import JSONResponse
import psycopg2
from psycopg2.extras import DictCursor
import os

router = APIRouter(prefix="/users", tags=["Users"])

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "1234")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "Dreamroute")

def get_db_connection():
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )
    return conn

@router.get("/")
def get_users():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=DictCursor)
    
    # Get user information with resume from resumerules table
    # Check which timestamp column exists in resumerules table
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'resumerules' 
        AND column_name IN ('uploaded_at', 'created_at')
        LIMIT 1
    """)
    timestamp_col_result = cur.fetchone()
    timestamp_column = timestamp_col_result[0] if timestamp_col_result else 'created_at'
    
    # Use profile_image directly (as per actual database schema)
    # Check if join_date or created_at exists
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name IN ('join_date', 'created_at')
        LIMIT 1
    """)
    date_col_result = cur.fetchone()
    date_column = date_col_result[0] if date_col_result else 'created_at'
    
    # Check if resume_blob column exists in users table
    cur.execute("""
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'users' 
        AND column_name = 'resume_blob'
        LIMIT 1
    """)
    resume_blob_exists = cur.fetchone() is not None
    
    # Build query based on available columns
    if resume_blob_exists:
        cur.execute(f"""
            SELECT 
                u.user_id, 
                u.name, 
                u.email, 
                u.role, 
                u.qualification, 
                u.location, 
                u.{date_column} as join_date,
                u.status,
                u.resume_score,
                u.profile_image,
                u.resume_blob
            FROM users u
            ORDER BY u.{date_column} DESC
        """)
    else:
        # Fallback: try to get from resumerules if resume_blob doesn't exist
        cur.execute(f"""
            SELECT 
                u.user_id, 
                u.name, 
                u.email, 
                u.role, 
                u.qualification, 
                u.location, 
                u.{date_column} as join_date,
                u.status,
                u.resume_score,
                u.profile_image,
                (SELECT resume_url FROM resumerules WHERE user_id = u.user_id ORDER BY {timestamp_column} DESC LIMIT 1) as resume_url
            FROM users u
            ORDER BY u.{date_column} DESC
        """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    users = []
    for row in rows:
        # Generate API endpoint URLs for image and resume
        # Use environment variable or default to localhost
        api_base_url = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
        user_id = row["user_id"]
        
        # Check if resume_blob exists (binary data) or resume_url (file path)
        has_resume_blob = "resume_blob" in row and row["resume_blob"] is not None
        has_resume_url = "resume_url" in row and row["resume_url"]
        
        # Generate resume API URL if resume exists (either as blob or URL)
        resume_api_url = None
        resume_url = ""
        if has_resume_blob:
            # Resume is stored as binary blob
            resume_api_url = f"{api_base_url}/files/user/{user_id}/resume"
            resume_url = resume_api_url  # Use API endpoint as the URL
        elif has_resume_url:
            # Resume is stored as file path/URL
            resume_url = row["resume_url"]
            if resume_url and not resume_url.startswith(('http://', 'https://', '/')):
                resume_url = f"/uploads/resumes/{resume_url}"
            resume_api_url = f"{api_base_url}/files/user/{user_id}/resume" if resume_url else None
        
        # Generate image API URL if profile_image exists
        image_url = f"{api_base_url}/files/user/{user_id}/image" if row.get("profile_image") else None
        
        users.append({
            "id": row["user_id"],
            "user_id": row["user_id"],
            "name": row["name"],
            "full_name": row["name"],
            "email": row["email"],
            "resume": resume_url,
            "resume_path": resume_url,
            "resume_url": resume_url,
            "resume_api_url": resume_api_url,  # API endpoint for PDF viewing
            "role": row["role"],
            "status": row["status"] if row["status"] else "Active",
            "joined_date": row["join_date"].strftime("%Y-%m-%d") if row["join_date"] else "",
            "created_at": row["join_date"].isoformat() if row["join_date"] else "",
            "image_url": image_url,  # API endpoint for image
            "profile_picture": image_url,  # Use API endpoint
            "qualification": row["qualification"] or "",
            "location": row["location"] or "",
            "resume_status": "Analyzed" if row["resume_score"] else ("Uploaded" if resume_url else "No Resume"),
            "resume_score": row["resume_score"] if row["resume_score"] else None
        })
    return JSONResponse(content=users)
