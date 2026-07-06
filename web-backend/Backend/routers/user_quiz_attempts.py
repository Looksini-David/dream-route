from fastapi import APIRouter
import psycopg2
from psycopg2.extras import RealDictCursor
import os

router = APIRouter(prefix="/user-quiz-attempts", tags=["UserQuizAttempts"])

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
def get_user_quiz_attempts():
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    try:
        # Query based on actual database structure: attempt_id, user_id, quiz_id, score, readiness_level, taken_on, best_domain, and domain scores
        query = """
            SELECT 
                ua.attempt_id,
                ua.user_id,
                ua.quiz_id,
                ua.score,
                ua.readiness_level,
                ua.taken_on,
                ua.best_domain,
                ua.ai_data_science,
                ua.data_analytics,
                ua.it_management,
                ua.database,
                ua.cloud_devops,
                ua.software_development,
                ua.networking,
                ua.mobile_development,
                ua.design,
                ua.cybersecurity,
                ua.web_development,
                COALESCE(u.name, 'Unknown User') as user_name,
                COALESCE(q.title, 'Unknown Quiz') as quiz_title
            FROM userquizattempts ua
            LEFT JOIN users u ON ua.user_id = u.user_id
            LEFT JOIN quizzes q ON ua.quiz_id = q.quiz_id
            ORDER BY ua.taken_on DESC NULLS LAST, ua.attempt_id DESC
        """
        
        print(f"Executing query: {query}")  # Debug log
        cur.execute(query)
        rows = cur.fetchall()
        
        print(f"Fetched {len(rows)} rows from userquizattempts")  # Debug log
        
        # Convert to list of dictionaries
        result = []
        for row in rows:
            attempt_data = {
                'attempt_id': str(row.get('attempt_id', '')),
                'user_id': str(row.get('user_id', '')),
                'user_name': str(row.get('user_name', 'Unknown User')),
                'quiz_id': str(row.get('quiz_id', '')),
                'quiz_title': str(row.get('quiz_title', 'Unknown Quiz')),
                'score': float(row['score']) if row.get('score') is not None else None,
                'readiness_level': str(row.get('readiness_level', '')),
                'best_domain': str(row.get('best_domain', '')) if row.get('best_domain') else None,
                'taken_on': row.get('taken_on').isoformat() if row.get('taken_on') else None,
                # Domain scores
                'ai_data_science': float(row['ai_data_science']) if row.get('ai_data_science') is not None else None,
                'data_analytics': float(row['data_analytics']) if row.get('data_analytics') is not None else None,
                'it_management': float(row['it_management']) if row.get('it_management') is not None else None,
                'database': float(row['database']) if row.get('database') is not None else None,
                'cloud_devops': float(row['cloud_devops']) if row.get('cloud_devops') is not None else None,
                'software_development': float(row['software_development']) if row.get('software_development') is not None else None,
                'networking': float(row['networking']) if row.get('networking') is not None else None,
                'mobile_development': float(row['mobile_development']) if row.get('mobile_development') is not None else None,
                'design': float(row['design']) if row.get('design') is not None else None,
                'cybersecurity': float(row['cybersecurity']) if row.get('cybersecurity') is not None else None,
                'web_development': float(row['web_development']) if row.get('web_development') is not None else None
            }
            result.append(attempt_data)
        
        print(f"Returning {len(result)} user quiz attempt records")  # Debug log
        if result:
            print(f"Sample record: {result[0]}")  # Debug log
        return result
        
    except Exception as e:
        print(f"Database error in get_user_quiz_attempts: {e}")
        import traceback
        traceback.print_exc()
        return []
        
    finally:
        cur.close()
        conn.close()

