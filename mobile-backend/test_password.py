from auth import hash_password, verify_password

# Example long password
pw = "geer2022" * 2

# Hash the password
hashed = hash_password(pw)
print("Hashed password:", hashed)

# Verify
if verify_password(pw, hashed):
    print("Password hash and verify working correctly!")
else:
    print("Verification failed!")
