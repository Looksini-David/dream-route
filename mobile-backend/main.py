from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import resume_analysis, users, questions
from database import Base, engine
from routers import quiz_result
from routers import career_path, growth_platforms, ai_tasks, feedback, roadmap

app = FastAPI(title="DreamRoute Backend")

# Create tables
Base.metadata.create_all(bind=engine)

# CORS for Flutter
origins = ["http://127.0.0.1:5000", "http://localhost:5000"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  #origins or ["*"] for testing only
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include router
# IMPORTANT: Register resume_analysis router BEFORE users router
# to ensure /resume/result matches before /resume/{user_id}
try:
    app.include_router(resume_analysis.router)
    app.include_router(users.router)
    app.include_router(questions.router)
    app.include_router(quiz_result.router)
    app.include_router(career_path.router)
    app.include_router(growth_platforms.router)
    app.include_router(ai_tasks.router)
    app.include_router(feedback.router)
    app.include_router(roadmap.router)
    print("✅ All routers included successfully")
    print(f"✅ Users router has {len(users.router.routes)} routes")
    for route in users.router.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            print(f"   - {list(route.methods)} {route.path}")
    
    # Check all registered routes after including routers
    print("\n" + "="*50)
    print("🔍 Checking all registered routes...")
    print("="*50)
    all_routes = []
    for route in app.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            all_routes.append(f"{list(route.methods)} {route.path}")
    
    print(f"Total routes registered: {len(all_routes)}")
    print("\nKey endpoints:")
    for route in sorted(all_routes):
        if "/login" in route or "/register" in route or "/test" in route or route.endswith("/"):
            print(f"  {route}")
    
    # Check specifically for login and register
    login_found = any("/login" in r for r in all_routes)
    register_found = any("/register" in r for r in all_routes)
    
    print("\n" + "="*50)
    if login_found:
        print("✅ /login endpoint found")
    else:
        print("❌ /login endpoint NOT found")
    
    if register_found:
        print("✅ /register endpoint found")
    else:
        print("❌ /register endpoint NOT found")
    print("="*50 + "\n")
except Exception as e:
    print(f"❌ Error including routers: {e}")
    import traceback
    traceback.print_exc()

@app.get("/")
def home():
    return {
        "message": "Backend running successfully 🚀",
        "endpoints": {
            "login": "/login",
            "register": "/register",
            "docs": "/docs"
        }
    }

# Health check endpoint
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "endpoints_available": {
            "login": True,
            "register": True
        }
    }

# Test endpoint to verify backend is working
@app.post("/test")
def test_endpoint():
    return {"message": "Test endpoint works", "status": "ok"}
