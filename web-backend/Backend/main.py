# from fastapi import FastAPI
# from fastapi.middleware.cors import CORSMiddleware
# from database import Base, engine
# from routers.admin import login

# app = FastAPI(title="DreamRoute Backend")

# # Create tables
# Base.metadata.create_all(bind=engine)

# @app.get("/")
# def root():
#     return {"message": "Welcome to the API"}

# # Allowed frontend origins
# origins = [
#     "http://127.0.0.1:5500",
#     "http://localhost:5500",
#     "http://localhost:8080",
#     "http://127.0.0.1:8080"
# ]

# # Add CORS middleware
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=origins,
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # Include routers
# app.include_router(login.router)

"""
DreamRoute Backend - Main Application Entry Point
FastAPI application for managing users, quizzes, resumes, and admin functions
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# Import database
from database import Base, engine

# Import routers
from routers import login, users, resumes, quiz_scores, quizzes, files, user_quiz_attempts, industries

# Create FastAPI app
app = FastAPI(
    title="DreamRoute Backend API",
    description="Backend API for DreamRoute - Career Management Platform",
    version="1.0.0"
)

# Create all database tables
Base.metadata.create_all(bind=engine)

# Configure CORS - Allow frontend to access the API
origins = [
    "http://127.0.0.1:5500",
    "http://localhost:5500",
    "http://127.0.0.1:8080",
    "http://localhost:8080",
    "http://127.0.0.1:3000",
    "http://localhost:3000",
    "*"  # Allow all origins for development - restrict in production
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers
app.include_router(login.router)
app.include_router(users.router)
app.include_router(resumes.router)
app.include_router(quiz_scores.router)
app.include_router(quizzes.router)
app.include_router(files.router)
app.include_router(user_quiz_attempts.router)
app.include_router(industries.router)

@app.get("/")
def root():
    """Root endpoint - API health check"""
    return {
        "message": "Welcome to DreamRoute API",
        "status": "online",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}

# Run the application
if __name__ == "__main__":
    import uvicorn
    
    # Get configuration from environment
    host = os.getenv("BACKEND_HOST", "127.0.0.1")
    port = int(os.getenv("BACKEND_PORT", "8000"))
    
    print(f"🚀 Starting DreamRoute Backend API on http://{host}:{port}")
    print(f"📚 API Documentation: http://{host}:{port}/docs")
    print(f"🔄 Alternative Docs: http://{host}:{port}/redoc")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=True,  # Auto-reload on code changes
        log_level="info"
    )
