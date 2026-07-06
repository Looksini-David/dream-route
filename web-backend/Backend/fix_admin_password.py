"""
Fix admin password - hash the plain text password
"""
from passlib.context import CryptContext
import psycopg2

# Connect to database
conn = psycopg2.connect(
    dbname='Dreamroute',
    user='postgres', 
    password='1234',
    host='localhost',
    port='5432'
)
cur = conn.cursor()


# Use the same hashing context as the backend
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")
hashed_password = pwd_context.hash('password123')

print(f"Original password: password123")
print(f"Hashed password: {hashed_password}")

# Update the admin user
cur.execute(
    "UPDATE adminusers SET password = %s WHERE email = %s",
    (hashed_password, 'admin@example.com')
)
conn.commit()

print(f"\n✅ Updated admin@example.com password to hashed version")

# Verify
cur.execute("SELECT email, password FROM adminusers WHERE email = 'admin@example.com'")
result = cur.fetchone()
print(f"\nVerification:")
print(f"  Email: {result[0]}")
print(f"  Password (hashed): {result[1][:50]}...")

cur.close()
conn.close()

print("\n🎉 Admin password fixed! You can now login with:")
print("   Email: admin@example.com")
print("   Password: password123")
