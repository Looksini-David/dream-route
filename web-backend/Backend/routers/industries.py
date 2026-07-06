from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
from psycopg2.extras import RealDictCursor
import psycopg2
import os
from typing import Optional
from pydantic import BaseModel

router = APIRouter(prefix="/industries", tags=["Industries"])

# Database connection parameters
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASS = os.getenv("DB_PASSWORD", "1234")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME", "Dreamroute")

def get_db_connection():
    """Create and return database connection"""
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )
    return conn

# Pydantic models for request/response
class IndustryCreate(BaseModel):
    name: str
    skills: str
    type: str
    demand: str
    salary: str

class IndustryUpdate(BaseModel):
    name: Optional[str] = None
    skills: Optional[str] = None
    type: Optional[str] = None
    demand: Optional[str] = None
    salary: Optional[str] = None

# GET all industries
@router.get("/")
def get_industries():
    """Get all industries from database"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT industry_id, name, skills, type, demand, salary, 
                   created_at, updated_at
            FROM industries
            ORDER BY created_at DESC
        """)
        
        industries = cur.fetchall()
        
        cur.close()
        conn.close()
        
        # Convert to list of dictionaries
        result = []
        for row in industries:
            result.append({
                "industry_id": row["industry_id"],
                "name": row["name"],
                "skills": row["skills"],
                "type": row["type"],
                "demand": row["demand"],
                "salary": row["salary"],
                "created_at": row["created_at"].isoformat() if row["created_at"] else None,
                "updated_at": row["updated_at"].isoformat() if row["updated_at"] else None
            })
        
        return JSONResponse(content=result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# GET single industry by ID
@router.get("/{industry_id}")
def get_industry(industry_id: int):
    """Get a single industry by ID"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT industry_id, name, skills, type, demand, salary, 
                   created_at, updated_at
            FROM industries
            WHERE industry_id = %s
        """, (industry_id,))
        
        industry = cur.fetchone()
        
        cur.close()
        conn.close()
        
        if not industry:
            raise HTTPException(status_code=404, detail="Industry not found")
        
        return {
            "industry_id": industry["industry_id"],
            "name": industry["name"],
            "skills": industry["skills"],
            "type": industry["type"],
            "demand": industry["demand"],
            "salary": industry["salary"],
            "created_at": industry["created_at"].isoformat() if industry["created_at"] else None,
            "updated_at": industry["updated_at"].isoformat() if industry["updated_at"] else None
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# POST create new industry
@router.post("/")
def create_industry(industry: IndustryCreate):
    """Create a new industry"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            INSERT INTO industries (name, skills, type, demand, salary, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            RETURNING industry_id, name, skills, type, demand, salary, created_at, updated_at
        """, (industry.name, industry.skills, industry.type, industry.demand, industry.salary))
        
        new_industry = cur.fetchone()
        conn.commit()
        
        cur.close()
        conn.close()
        
        return {
            "industry_id": new_industry["industry_id"],
            "name": new_industry["name"],
            "skills": new_industry["skills"],
            "type": new_industry["type"],
            "demand": new_industry["demand"],
            "salary": new_industry["salary"],
            "created_at": new_industry["created_at"].isoformat() if new_industry["created_at"] else None,
            "updated_at": new_industry["updated_at"].isoformat() if new_industry["updated_at"] else None,
            "message": "Industry created successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# PUT update industry
@router.put("/{industry_id}")
def update_industry(industry_id: int, industry: IndustryUpdate):
    """Update an existing industry"""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Check if industry exists
        cur.execute("SELECT industry_id FROM industries WHERE industry_id = %s", (industry_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Industry not found")
        
        # Build update query dynamically
        update_fields = []
        values = []
        
        if industry.name is not None:
            update_fields.append("name = %s")
            values.append(industry.name)
        if industry.skills is not None:
            update_fields.append("skills = %s")
            values.append(industry.skills)
        if industry.type is not None:
            update_fields.append("type = %s")
            values.append(industry.type)
        if industry.demand is not None:
            update_fields.append("demand = %s")
            values.append(industry.demand)
        if industry.salary is not None:
            update_fields.append("salary = %s")
            values.append(industry.salary)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        # Always update updated_at
        update_fields.append("updated_at = CURRENT_TIMESTAMP")
        values.append(industry_id)
        
        update_query = f"""
            UPDATE industries 
            SET {', '.join(update_fields)}
            WHERE industry_id = %s
            RETURNING industry_id, name, skills, type, demand, salary, created_at, updated_at
        """
        
        cur.execute(update_query, values)
        updated_industry = cur.fetchone()
        conn.commit()
        
        cur.close()
        conn.close()
        
        return {
            "industry_id": updated_industry["industry_id"],
            "name": updated_industry["name"],
            "skills": updated_industry["skills"],
            "type": updated_industry["type"],
            "demand": updated_industry["demand"],
            "salary": updated_industry["salary"],
            "created_at": updated_industry["created_at"].isoformat() if updated_industry["created_at"] else None,
            "updated_at": updated_industry["updated_at"].isoformat() if updated_industry["updated_at"] else None,
            "message": "Industry updated successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# DELETE industry
@router.delete("/{industry_id}")
def delete_industry(industry_id: int):
    """Delete an industry"""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if industry exists
        cur.execute("SELECT industry_id FROM industries WHERE industry_id = %s", (industry_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Industry not found")
        
        # Delete industry
        cur.execute("DELETE FROM industries WHERE industry_id = %s", (industry_id,))
        conn.commit()
        
        cur.close()
        conn.close()
        
        return {"message": "Industry deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

