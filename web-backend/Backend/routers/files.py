"""
File Serving Router
Handles serving user profile images and resume PDFs
"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import Response, FileResponse
import psycopg2
from psycopg2.extras import DictCursor
import os
import base64
from io import BytesIO

router = APIRouter(prefix="/files", tags=["Files"])

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

@router.get("/user/{user_id}/image")
def get_user_image(user_id: str):
    """
    Serve user profile image from database
    Returns image with proper content-type headers
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=DictCursor)
    
    try:
        # Use profile_image directly (as per actual database schema)
        cur.execute("""
            SELECT profile_image
            FROM users 
            WHERE user_id = %s
        """, (user_id,))
        
        row = cur.fetchone()
        
        if not row or not row.get("profile_image"):
            # Return 404 - frontend should handle with fallback image
            raise HTTPException(status_code=404, detail="Image not found")
        
        profile_image = row["profile_image"]
        
        # Handle different data types
        image_data = None
        if isinstance(profile_image, memoryview):
            image_data = profile_image.tobytes()
        elif isinstance(profile_image, bytes):
            image_data = profile_image
        elif isinstance(profile_image, str):
            # If it's a file path, try to read from file system
            # Try various possible paths
            possible_paths = [
                profile_image,
                f"uploads/images/{profile_image}",
                f"Backend/uploads/images/{profile_image}",
                f"Frontend/assets/images/{profile_image}",
                f"assets/images/{profile_image}"
            ]
            
            for path in possible_paths:
                if os.path.exists(path) and os.path.isfile(path):
                    # Determine content type from file extension
                    ext = os.path.splitext(path)[1].lower()
                    media_type = "image/jpeg"
                    if ext == ".png":
                        media_type = "image/png"
                    elif ext == ".gif":
                        media_type = "image/gif"
                    elif ext in [".jpg", ".jpeg"]:
                        media_type = "image/jpeg"
                    return FileResponse(path, media_type=media_type)
            
            # If it's a base64 string
            try:
                image_data = base64.b64decode(profile_image)
            except:
                # If it's a URL, try to return it
                if profile_image.startswith(('http://', 'https://')):
                    # For external URLs, we could redirect or fetch
                    raise HTTPException(status_code=404, detail="External image URLs not supported directly")
                # If it's a relative path that doesn't exist
                raise HTTPException(status_code=404, detail="Image path not found")
        else:
            raise HTTPException(status_code=404, detail="Invalid image format")
        
        if not image_data:
            raise HTTPException(status_code=404, detail="Image data is empty")
        
        # Determine content type (default to jpeg, could be improved with detection)
        content_type = "image/jpeg"
        if len(image_data) > 0:
            if image_data.startswith(b'\x89PNG'):
                content_type = "image/png"
            elif image_data.startswith(b'GIF'):
                content_type = "image/gif"
            elif image_data.startswith(b'\xff\xd8\xff'):
                content_type = "image/jpeg"
        
        return Response(content=image_data, media_type=content_type)
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error serving user image: {e}")
        raise HTTPException(status_code=500, detail="Error serving image")
    finally:
        cur.close()
        conn.close()

@router.get("/user/{user_id}/resume")
def get_user_resume(user_id: str):
    """
    Serve user resume PDF from users table (resume_blob) or file system
    Returns PDF with proper content-type headers
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=DictCursor)
    
    try:
        # Check if resume_blob column exists in users table
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            AND column_name = 'resume_blob'
            LIMIT 1
        """)
        resume_blob_exists = cur.fetchone() is not None
        
        if resume_blob_exists:
            # Get resume binary data from users table
            cur.execute("""
                SELECT resume_blob 
                FROM users 
                WHERE user_id = %s
            """, (user_id,))
            
            row = cur.fetchone()
            
            if not row or not row.get("resume_blob"):
                raise HTTPException(status_code=404, detail="Resume not found")
            
            resume_blob = row["resume_blob"]
            
            # Handle binary data
            pdf_data = None
            if isinstance(resume_blob, memoryview):
                pdf_data = resume_blob.tobytes()
            elif isinstance(resume_blob, bytes):
                pdf_data = resume_blob
            else:
                raise HTTPException(status_code=404, detail="Invalid resume format")
            
            if not pdf_data:
                raise HTTPException(status_code=404, detail="Resume data is empty")
            
            # Return PDF as binary response
            return Response(
                content=pdf_data,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f'inline; filename="resume_{user_id}.pdf"',
                    "Content-Length": str(len(pdf_data))
                }
            )
        else:
            # Fallback: try to get from resumerules table or file system
            cur.execute("""
                SELECT column_name 
                FROM information_schema.columns 
                WHERE table_name = 'resumerules' 
                AND column_name IN ('uploaded_at', 'created_at')
                LIMIT 1
            """)
            timestamp_col_result = cur.fetchone()
            timestamp_column = timestamp_col_result[0] if timestamp_col_result else 'created_at'
            
            cur.execute(f"""
                SELECT resume_url 
                FROM resumerules 
                WHERE user_id = %s 
                ORDER BY {timestamp_column} DESC 
                LIMIT 1
            """, (user_id,))
            
            row = cur.fetchone()
            
            if not row or not row.get("resume_url"):
                raise HTTPException(status_code=404, detail="Resume not found")
            
            resume_url = row["resume_url"]
            
            # Handle file path
            if os.path.exists(resume_url):
                return FileResponse(
                    resume_url,
                    media_type="application/pdf",
                    filename=f"resume_{user_id}.pdf",
                    headers={"Content-Disposition": f'inline; filename="resume_{user_id}.pdf"'}
                )
            
            # Try common upload directories
            upload_paths = [
                f"uploads/resumes/{resume_url}",
                f"Backend/uploads/resumes/{resume_url}",
                resume_url
            ]
            
            for path in upload_paths:
                if os.path.exists(path):
                    return FileResponse(
                        path,
                        media_type="application/pdf",
                        filename=f"resume_{user_id}.pdf",
                        headers={"Content-Disposition": f'inline; filename="resume_{user_id}.pdf"'}
                    )
            
            # If it's a URL
            if resume_url.startswith(('http://', 'https://')):
                raise HTTPException(
                    status_code=302,
                    detail=f"Resume available at: {resume_url}",
                    headers={"Location": resume_url}
                )
            
            raise HTTPException(status_code=404, detail="Resume file not found")
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error serving resume: {e}")
        raise HTTPException(status_code=500, detail="Error serving resume")
    finally:
        cur.close()
        conn.close()

@router.get("/resume/{resume_id}")
def get_resume_by_id(resume_id: str):
    """
    Serve resume PDF from resumerules table by resume_id
    Returns PDF with proper content-type headers
    """
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=DictCursor)
    
    try:
        # Check if resume_blob column exists in resumerules table
        cur.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = 'resumerules' 
            AND column_name = 'resume_blob'
            LIMIT 1
        """)
        resume_blob_exists = cur.fetchone() is not None
        
        if resume_blob_exists:
            # Get resume binary data from resumerules table using rule_id
            cur.execute("""
                SELECT resume_blob 
                FROM resumerules 
                WHERE rule_id = %s
                LIMIT 1
            """, (resume_id,))
            
            row = cur.fetchone()
            
            if not row or not row.get("resume_blob"):
                raise HTTPException(status_code=404, detail="Resume not found")
            
            resume_blob = row["resume_blob"]
            
            # Handle binary data
            pdf_data = None
            if isinstance(resume_blob, memoryview):
                pdf_data = resume_blob.tobytes()
            elif isinstance(resume_blob, bytes):
                pdf_data = resume_blob
            else:
                raise HTTPException(status_code=404, detail="Invalid resume format")
            
            if not pdf_data:
                raise HTTPException(status_code=404, detail="Resume data is empty")
            
            # Return PDF as binary response
            return Response(
                content=pdf_data,
                media_type="application/pdf",
                headers={
                    "Content-Disposition": f'inline; filename="resume_{resume_id}.pdf"',
                    "Content-Length": str(len(pdf_data))
                }
            )
        else:
            # Fallback: try to get resume_url and serve from file system
            cur.execute("""
                SELECT resume_url 
                FROM resumerules 
                WHERE rule_id = %s
                LIMIT 1
            """, (resume_id,))
            
            row = cur.fetchone()
            
            if not row or not row.get("resume_url"):
                raise HTTPException(status_code=404, detail="Resume not found")
            
            resume_url = row["resume_url"]
            
            # Handle file path
            if os.path.exists(resume_url):
                return FileResponse(
                    resume_url,
                    media_type="application/pdf",
                    filename=f"resume_{resume_id}.pdf",
                    headers={"Content-Disposition": f'inline; filename="resume_{resume_id}.pdf"'}
                )
            
            # Try common upload directories
            upload_paths = [
                f"uploads/resumes/{resume_url}",
                f"Backend/uploads/resumes/{resume_url}",
                resume_url
            ]
            
            for path in upload_paths:
                if os.path.exists(path):
                    return FileResponse(
                        path,
                        media_type="application/pdf",
                        filename=f"resume_{resume_id}.pdf",
                        headers={"Content-Disposition": f'inline; filename="resume_{resume_id}.pdf"'}
                    )
            
            raise HTTPException(status_code=404, detail="Resume file not found")
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error serving resume: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail="Error serving resume")
    finally:
        cur.close()
        conn.close()

@router.get("/resume/path/{resume_path:path}")
def get_resume_by_path(resume_path: str):
    """
    Serve resume PDF by path
    Useful for serving resumes stored in uploads directory
    """
    # Security: prevent directory traversal
    if ".." in resume_path or resume_path.startswith("/"):
        raise HTTPException(status_code=400, detail="Invalid resume path")
    
    # Try common upload directories
    upload_paths = [
        f"uploads/resumes/{resume_path}",
        f"Backend/uploads/resumes/{resume_path}",
        resume_path
    ]
    
    for path in upload_paths:
        if os.path.exists(path) and os.path.isfile(path):
            return FileResponse(
                path,
                media_type="application/pdf",
                filename=os.path.basename(resume_path),
                headers={"Content-Disposition": f'inline; filename="{os.path.basename(resume_path)}"'}
            )
    
    raise HTTPException(status_code=404, detail="Resume not found")

