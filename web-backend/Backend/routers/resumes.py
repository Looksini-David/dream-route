from fastapi import APIRouter, HTTPException
import psycopg2
from psycopg2.extras import RealDictCursor
import os

router = APIRouter(prefix="/resumes", tags=["Resumes"])

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
def get_resumes():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Query based on actual database structure: rule_id, user_id, resume_url, analysis_status, score, missing_skills, created_at, resume_blob
        # Note: We check for resume_blob existence but don't return the binary data in JSON
        query = """
            SELECT 
                r.rule_id as resume_id,
                r.user_id,
                COALESCE(u.name, 'Unknown User') as user_name,
                r.resume_url,
                CASE WHEN r.resume_blob IS NOT NULL THEN 1 ELSE 0 END as has_resume_blob,
                r.analysis_status as status,
                r.score,
                COALESCE(r.missing_skills, 'No analysis available') as missing_rules,
                r.created_at
            FROM resumerules r
            LEFT JOIN users u ON r.user_id = u.user_id
            ORDER BY r.created_at DESC NULLS LAST
        """
        
        print(f"Executing query: {query}")  # Debug log
        cur.execute(query)
        rows = cur.fetchall()
        
        print(f"Fetched {len(rows)} rows from resumerules")  # Debug log
        
        # Generate API base URL
        api_base_url = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
        
        # Convert to list of dictionaries for JSON serialization
        result = []
        for row in rows:
            try:
                resume_id = row.get('resume_id')
                if not resume_id:
                    print(f"Skipping row with no resume_id: {row}")
                    continue  # Skip rows without ID
                
                # Check if resume_blob exists (using the has_resume_blob flag from query)
                has_blob = row.get('has_resume_blob', 0) == 1
                
                # Determine resume file/URL
                resume_file = None
                if has_blob:
                    # Resume is stored as binary blob - use API endpoint
                    resume_file = f"{api_base_url}/files/resume/{resume_id}"
                elif row.get('resume_url'):
                    # Resume is stored as file path/URL
                    resume_url = row['resume_url']
                    if resume_url and resume_url.strip():
                        if resume_url.startswith(('http://', 'https://')):
                            # External URL
                            resume_file = resume_url
                        else:
                            # File path - use API endpoint to serve it
                            resume_file = f"{api_base_url}/files/resume/{resume_id}"
                
                result.append({
                    'resume_id': str(resume_id),
                    'user_id': str(row.get('user_id')) if row.get('user_id') else '-',
                    'user_name': str(row.get('user_name', 'Unknown User')),
                    'resume_file': resume_file,
                    'status': str(row.get('status', 'Pending')),
                    'score': float(row['score']) if row.get('score') is not None else None,
                    'missing_rules': str(row.get('missing_rules', 'Not analyzed')),
                    'created_at': row.get('created_at').isoformat() if row.get('created_at') else None
                })
            except Exception as e:
                print(f"Error processing row: {e}")
                print(f"Row data: {dict(row)}")
                continue
        
        print(f"Returning {len(result)} resume records")  # Debug log
        if result:
            print(f"Sample record: {result[0]}")  # Debug log
        return result

    except Exception as e:
        print(f"Database error in get_resumes: {e}")
        import traceback
        traceback.print_exc()
        # Return empty list if there's a database error
        return []
        
    finally:
        cur.close()
        conn.close()

@router.post("/")
def create_resume_rule(user_id: str, resume_url: str):
    """Create a new resume rule entry"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Generate rule_id
        cur.execute("SELECT COUNT(*) FROM resumerules")
        count = cur.fetchone()['count']
        rule_id = f"R{str(count + 1).zfill(4)}"
        
        # Insert new resume rule
        cur.execute("""
            INSERT INTO resumerules (rule_id, user_id, resume_url, analysis_status, created_at)
            VALUES (%s, %s, %s, 'pending', NOW())
            RETURNING *
        """, (rule_id, user_id, resume_url))
        
        new_rule = cur.fetchone()
        conn.commit()
        
    except Exception as e:
        print(f"Database error: {e}")
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        
    finally:
        cur.close()
        conn.close()
    
    return {"message": "Resume rule created successfully", "data": dict(new_rule)}

@router.put("/{rule_id}")
def update_resume_rule(rule_id: str, analysis_status: str = None, score: int = None, missing_skills: str = None):
    """Update resume analysis results"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Build dynamic update query
        update_fields = []
        values = []
        
        if analysis_status:
            update_fields.append("analysis_status = %s")
            values.append(analysis_status)
        if score is not None:
            update_fields.append("score = %s")
            values.append(score)
        if missing_skills:
            update_fields.append("missing_skills = %s")
            values.append(missing_skills)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        values.append(rule_id)
        
        update_query = f"""
            UPDATE resumerules 
            SET {', '.join(update_fields)}
            WHERE rule_id = %s
            RETURNING *
        """
        
        cur.execute(update_query, values)
        updated_rule = cur.fetchone()
        
        if not updated_rule:
            raise HTTPException(status_code=404, detail="Resume rule not found")
        
        conn.commit()
        
    except Exception as e:
        print(f"Database error: {e}")
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        
    finally:
        cur.close()
        conn.close()
    
    return {"message": "Resume rule updated successfully", "data": dict(updated_rule)}

@router.delete("/{rule_id}")
def delete_resume_rule(rule_id: str):
    """Delete a resume rule entry"""
    conn = get_db_connection()
    cur = conn.cursor()
    
    try:
        # Check if rule exists
        cur.execute("SELECT rule_id FROM resumerules WHERE rule_id = %s", (rule_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Resume rule not found")
        
        # Delete the rule
        cur.execute("DELETE FROM resumerules WHERE rule_id = %s", (rule_id,))
        conn.commit()
        
    except Exception as e:
        print(f"Database error: {e}")
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
        
    finally:
        cur.close()
        conn.close()
    
    return {"message": "Resume rule deleted successfully"}
