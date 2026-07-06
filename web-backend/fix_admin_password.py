"""
Fix admin password - hash the plain text password for the admin account
"""
import sys

sys.path.append('Backend')

from Backend.database import SessionLocal
from Backend.models.admin import AdminUser
from Backend.auth import get_password_hash

# Create session
db = SessionLocal()

try:
    # Find admin user with plaintext password
    admin = db.query(AdminUser).filter(AdminUser.email == 'admin@example.com').first()
    
    if admin:
        print(f"Found admin user: {admin.email}")
        print(f"Current password (first 20 chars): {admin.password[:20]}...")  # type: ignore

        # Check if password is already hashed (argon2 hashes start with $argon2)
        if admin.password.startswith('$argon2'):  # type: ignore
            print("\n✅ Password is already hashed!")
        else:
            print("\n⚠️ Password is in plaintext. Hashing now...")
            
            hashed_password = get_password_hash('password123')
            print(f"New hashed password: {hashed_password[:50]}...")
            
            admin.password = hashed_password  # type: ignore
            db.commit()
            
            print("\n✅ Password updated successfully!")
            
        print("\n🎉 You can now login with:")
        print("   Email: admin@example.com")
        print("   Password: password123")
    else:
        print("❌ Admin user not found!")
        
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    db.rollback()
finally:
    db.close()