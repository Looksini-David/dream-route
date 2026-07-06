from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from typing import Optional
from pydantic import BaseModel

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])

# Database connection function
def get_db_connection():
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASS = os.getenv("DB_PASSWORD", "1234")
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_NAME = os.getenv("DB_NAME", "Dreamroute")
    
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST,
        port=DB_PORT
    )
    return conn

# Pydantic models
class QuizCreate(BaseModel):
    domain: str
    title: str

class QuestionCreate(BaseModel):
    quiz_id: str
    question_text: str
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_option: str  # 'A', 'B', 'C', or 'D'
    question_type: str = "creativity"

class QuestionUpdate(BaseModel):
    question_text: Optional[str] = None
    option_a: Optional[str] = None
    option_b: Optional[str] = None
    option_c: Optional[str] = None
    option_d: Optional[str] = None
    correct_option: Optional[str] = None
    question_type: Optional[str] = None

# Get all quizzes
@router.get("/")
def get_quizzes():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT quiz_id, domain, title, created_at 
            FROM quizzes 
            ORDER BY created_at DESC
        """)
        quizzes = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return {"quizzes": quizzes}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Get questions for a specific quiz with pagination
@router.get("/{quiz_id}/questions")
def get_quiz_questions(quiz_id: str, page: int = 1, limit: int = 10):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Calculate offset
        offset = (page - 1) * limit
        
        # Get total count
        cur.execute("SELECT COUNT(*) FROM questions WHERE quiz_id = %s", (quiz_id,))
        total_count = cur.fetchone()['count']
        
        # Get paginated questions
        cur.execute("""
            SELECT question_id, quiz_id, question_text, option_a, option_b, 
                   option_c, option_d, correct_option, type, created_at
            FROM questions 
            WHERE quiz_id = %s
            ORDER BY created_at ASC
            LIMIT %s OFFSET %s
        """, (quiz_id, limit, offset))
        
        questions = cur.fetchall()
        
        cur.close()
        conn.close()
        
        total_pages = (total_count + limit - 1) // limit
        
        return {
            "questions": questions,
            "pagination": {
                "current_page": page,
                "total_pages": total_pages,
                "total_count": total_count,
                "limit": limit
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Get all questions for quiz editor (without pagination)
@router.get("/{quiz_id}/questions/all")
def get_all_quiz_questions(quiz_id: str):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("""
            SELECT question_id, quiz_id, question_text, option_a, option_b, 
                   option_c, option_d, correct_option, type, created_at
            FROM questions 
            WHERE quiz_id = %s
            ORDER BY created_at ASC
        """, (quiz_id,))
        
        questions = cur.fetchall()
        
        cur.close()
        conn.close()
        
        return {"questions": questions}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Create a new quiz
@router.post("/")
def create_quiz(quiz: QuizCreate):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Generate quiz ID
        cur.execute("SELECT COUNT(*) FROM quizzes")
        count = cur.fetchone()['count']
        quiz_id = f"Q{str(count + 1).zfill(4)}"
        
        # Insert new quiz
        cur.execute("""
            INSERT INTO quizzes (quiz_id, domain, title, created_at)
            VALUES (%s, %s, %s, NOW())
            RETURNING quiz_id, domain, title, created_at
        """, (quiz_id, quiz.domain, quiz.title))
        
        new_quiz = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {"quiz": new_quiz, "message": "Quiz created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Create a new question
@router.post("/{quiz_id}/questions")
def create_question(quiz_id: str, question: QuestionCreate):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Verify quiz exists
        cur.execute("SELECT quiz_id FROM quizzes WHERE quiz_id = %s", (quiz_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Quiz not found")
        
        # Generate question ID - get the highest existing ID number
        cur.execute("SELECT question_id FROM questions ORDER BY question_id DESC LIMIT 1")
        result = cur.fetchone()
        if result:
            # Extract number from last ID (e.g., "Qu00554" -> 554) and increment
            last_num = int(result['question_id'][2:])
            question_id = f"Qu{str(last_num + 1).zfill(5)}"
        else:
            # No questions yet, start from 1
            question_id = "Qu00001"
        
        # Clean up correct_option - extract just the letter (A, B, C, or D)
        correct_opt = question.correct_option.strip().upper()
        if correct_opt.startswith("OPTION "):
            correct_opt = correct_opt.replace("OPTION ", "")
        # Take only first character if it's A, B, C, or D
        if len(correct_opt) > 0 and correct_opt[0] in ['A', 'B', 'C', 'D']:
            correct_opt = correct_opt[0]
        else:
            raise HTTPException(status_code=400, detail="Invalid correct_option. Must be A, B, C, or D")
        
        # Clean up question_type - ensure it matches enum values
        question_type = question.question_type.lower().strip()
        valid_types = ['creativity', 'logical_thinking', 'communication', 'technical', 'situational', 'softskill']
        if question_type not in valid_types:
            question_type = 'creativity'  # Default to creativity if invalid
        
        # Insert new question
        cur.execute("""
            INSERT INTO questions (question_id, quiz_id, question_text, option_a, 
                                 option_b, option_c, option_d, correct_option, type, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s::option_enum, %s::question_type_enum, NOW())
            RETURNING question_id, quiz_id, question_text, option_a, option_b, 
                     option_c, option_d, correct_option, type, created_at
        """, (question_id, quiz_id, question.question_text, question.option_a,
              question.option_b, question.option_c, question.option_d, 
              correct_opt, question_type))
        
        new_question = cur.fetchone()
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {"question": new_question, "message": "Question created successfully"}
    except HTTPException as he:
        raise he
    except Exception as e:
        import traceback
        error_detail = f"Database error: {str(e)}\n{traceback.format_exc()}"
        print(f"ERROR creating question: {error_detail}")  # Log to console
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Update a question
@router.put("/questions/{question_id}")
def update_question(question_id: str, question: QuestionUpdate):
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Build update query dynamically
        update_fields = []
        values = []
        
        if question.question_text is not None:
            update_fields.append("question_text = %s")
            values.append(question.question_text)
        if question.option_a is not None:
            update_fields.append("option_a = %s")
            values.append(question.option_a)
        if question.option_b is not None:
            update_fields.append("option_b = %s")
            values.append(question.option_b)
        if question.option_c is not None:
            update_fields.append("option_c = %s")
            values.append(question.option_c)
        if question.option_d is not None:
            update_fields.append("option_d = %s")
            values.append(question.option_d)
        if question.correct_option is not None:
            # Clean up correct_option
            correct_opt = question.correct_option.strip().upper()
            if correct_opt.startswith("OPTION "):
                correct_opt = correct_opt.replace("OPTION ", "")
            if len(correct_opt) > 0 and correct_opt[0] in ['A', 'B', 'C', 'D']:
                correct_opt = correct_opt[0]
            else:
                raise HTTPException(status_code=400, detail="Invalid correct_option. Must be A, B, C, or D")
            update_fields.append("correct_option = %s::option_enum")
            values.append(correct_opt)
        if question.question_type is not None:
            # Clean up question_type
            question_type = question.question_type.lower().strip()
            valid_types = ['creativity', 'logical_thinking', 'communication', 'technical', 'situational', 'softskill']
            if question_type not in valid_types:
                question_type = 'creativity'
            update_fields.append("type = %s::question_type_enum")
            values.append(question_type)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields to update")
        
        values.append(question_id)
        
        update_query = f"""
            UPDATE questions 
            SET {', '.join(update_fields)}
            WHERE question_id = %s
            RETURNING question_id, quiz_id, question_text, option_a, option_b, 
                     option_c, option_d, correct_option, type, created_at
        """
        
        cur.execute(update_query, values)
        updated_question = cur.fetchone()
        
        if not updated_question:
            raise HTTPException(status_code=404, detail="Question not found")
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {"question": updated_question, "message": "Question updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Delete a question
@router.delete("/questions/{question_id}")
def delete_question(question_id: str):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if question exists
        cur.execute("SELECT question_id FROM questions WHERE question_id = %s", (question_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Question not found")
        
        # Delete question
        cur.execute("DELETE FROM questions WHERE question_id = %s", (question_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {"message": "Question deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

# Delete a quiz and all its questions
@router.delete("/{quiz_id}")
def delete_quiz(quiz_id: str):
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Check if quiz exists
        cur.execute("SELECT quiz_id FROM quizzes WHERE quiz_id = %s", (quiz_id,))
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Quiz not found")
        
        # Delete all questions for this quiz first
        cur.execute("DELETE FROM questions WHERE quiz_id = %s", (quiz_id,))
        
        # Delete the quiz
        cur.execute("DELETE FROM quizzes WHERE quiz_id = %s", (quiz_id,))
        
        conn.commit()
        cur.close()
        conn.close()
        
        return {"message": "Quiz and all its questions deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")