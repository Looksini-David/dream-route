from dotenv import load_dotenv
import os
import psycopg2

load_dotenv()

conn = psycopg2.connect(
    dbname=os.getenv('DB_NAME'),
    user=os.getenv('DB_USER'), 
    password=os.getenv('DB_PASSWORD'),
    host=os.getenv('DB_HOST'),
    port=os.getenv('DB_PORT')
)
cur = conn.cursor()


# Check users table columns
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'users' 
    ORDER BY ordinal_position
""")
print("\n=== USERS TABLE COLUMNS ===")
for col in cur.fetchall():
    print(f"  {col[0]}: {col[1]}")

# Check questions table columns  
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'questions' 
    ORDER BY ordinal_position
""")
print("\n=== QUESTIONS TABLE COLUMNS ===")
for col in cur.fetchall():
    print(f"  {col[0]}: {col[1]}")

# Check quizzes table columns
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'quizzes' 
    ORDER BY ordinal_position
""")
print("\n=== QUIZZES TABLE COLUMNS ===")
for col in cur.fetchall():
    print(f"  {col[0]}: {col[1]}")

cur.close()
conn.close()
