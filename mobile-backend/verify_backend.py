#!/usr/bin/env python3
"""Quick script to verify backend endpoints are accessible"""
import requests
import sys

BASE_URL = "http://localhost:8000"

def test_endpoint(method, path, data=None, files=None):
    """Test an endpoint"""
    url = f"{BASE_URL}{path}"
    try:
        if method == "GET":
            response = requests.get(url, timeout=5)
        elif method == "POST":
            if files:
                response = requests.post(url, data=data, files=files, timeout=5)
            else:
                response = requests.post(url, json=data, timeout=5)
        else:
            print(f"❌ Unsupported method: {method}")
            return False
        
        print(f"{method} {path}: Status {response.status_code}")
        if response.status_code == 404:
            print(f"  ❌ Not Found - Endpoint doesn't exist")
            return False
        elif response.status_code >= 200 and response.status_code < 300:
            print(f"  ✅ Success")
            return True
        else:
            print(f"  ⚠️  Status: {response.status_code}")
            print(f"  Response: {response.text[:100]}")
            return False
    except requests.exceptions.ConnectionError:
        print(f"  ❌ Connection Error - Backend is not running!")
        print(f"  Please start the backend: py -m uvicorn main:app --reload --host localhost --port 8000")
        return False
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("🔍 Verifying DreamRoute Backend Endpoints")
    print("=" * 60)
    print()
    
    # Test home endpoint
    print("1. Testing home endpoint...")
    home_ok = test_endpoint("GET", "/")
    print()
    
    # Test health endpoint
    print("2. Testing health endpoint...")
    health_ok = test_endpoint("GET", "/health")
    print()
    
    # Test login endpoint (should return 422 for missing data, but endpoint exists)
    print("3. Testing login endpoint (should exist)...")
    login_ok = test_endpoint("POST", "/login", data={})
    print()
    
    # Test register endpoint (should return 422 for missing data, but endpoint exists)
    print("4. Testing register endpoint (should exist)...")
    register_ok = test_endpoint("POST", "/register", data={})
    print()
    
    print("=" * 60)
    if home_ok and health_ok:
        print("✅ Backend is running and accessible!")
        if login_ok or register_ok:
            print("✅ Login and Register endpoints are available!")
        else:
            print("⚠️  Login/Register endpoints may have validation errors (this is normal)")
        print()
        print("You can now use the frontend application.")
    else:
        print("❌ Backend is not running or not accessible!")
        print()
        print("To start the backend:")
        print("  1. Open a terminal")
        print("  2. cd backend")
        print("  3. py -m uvicorn main:app --reload --host localhost --port 8000")
    print("=" * 60)
    
    return 0 if (home_ok and health_ok) else 1

if __name__ == "__main__":
    sys.exit(main())

