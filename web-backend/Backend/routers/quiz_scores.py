from fastapi import APIRouter
import psycopg2
import os

router = APIRouter(prefix="/quiz-scores", tags=["QuizScores"])

def get_db_connection():
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_NAME = os.getenv("DB_NAME", "Dreamroute")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASS = os.getenv("DB_PASSWORD", "1234")
    
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

@router.get("/")
def get_quiz_scores():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Join quizscoreanalysis with users and quizzes tables to get names and titles
        query = """
        SELECT 
            qsa.analysis_id,
            qsa.user_id,
            u.name as user_name,
            qsa.quiz_id,
            q.title as quiz_title,
            qsa.score as quiz_score,
            qsa.type as result,
            qsa.created_at
        FROM quizscoreanalysis qsa
        LEFT JOIN users u ON qsa.user_id = u.user_id
        LEFT JOIN quizzes q ON qsa.quiz_id = q.quiz_id
        ORDER BY qsa.created_at DESC
        """
        
        cur.execute(query)
        rows = cur.fetchall()
        
        scores = []
        for row in rows:
            scores.append({
                "analysis_id": row[0],
                "user_id": row[1],
                "user_name": row[2] or "Unknown User",
                "quiz_id": row[3],
                "quiz_title": row[4] or "Unknown Quiz",
                "quiz_score": row[5],
                "result": row[6],
                "created_at": row[7].isoformat() if row[7] else None
            })
        
        cur.close()
        conn.close()
        return scores
        
    except Exception as e:
        print(f"Database error: {e}")
        return []
