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

# List tables
cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name")
tables = cur.fetchall()
print("\nTables in database:")
for t in tables:
    print(f"  - {t[0]}")

# Check AdminUsers table
cur.execute('SELECT * FROM adminusers')
admins = cur.fetchall()
print(f"\nadminusers table has {len(admins)} records:")
for admin in admins:
    print(f"  - {admin}")

cur.close()
conn.close()
