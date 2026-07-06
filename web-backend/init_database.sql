-- PostgreSQL Database Initialization Script for DreamRoute
-- Run this script to create all necessary tables

-- Create database (run this separately as postgres superuser if needed)
-- CREATE DATABASE DreamRoute;

-- Connect to DreamRoute database
-- \c DreamRoute

-- ==================================================
-- 1. Users Table
-- ==================================================
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(5) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('student', 'fresher')),
    qualification VARCHAR(50),
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    profile_picture VARCHAR(255)
);

-- ==================================================
-- 2. Admin Users Table
-- ==================================================
CREATE TABLE IF NOT EXISTS "AdminUsers" (
    admin_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('superadmin', 'subadmin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    profile_picture VARCHAR(255)
);

-- ==================================================
-- 3. Resume Rules Table
-- ==================================================
CREATE TABLE IF NOT EXISTS resumerules (
    resume_id SERIAL PRIMARY KEY,
    user_id VARCHAR(5) REFERENCES users(user_id) ON DELETE CASCADE,
    resume_url VARCHAR(500),
    analysis_status VARCHAR(50) DEFAULT 'Pending',
    score FLOAT,
    feedback TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    analyzed_at TIMESTAMP
);

-- Alternative name for resume rules table
CREATE TABLE IF NOT EXISTS resumes_rules (
    resume_id SERIAL PRIMARY KEY,
    user_id VARCHAR(5) REFERENCES users(user_id) ON DELETE CASCADE,
    resume_url VARCHAR(500),
    analysis_status VARCHAR(50) DEFAULT 'Pending',
    score FLOAT,
    feedback TEXT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    analyzed_at TIMESTAMP
);

-- ==================================================
-- 4. Quiz Scores Analysis Table
-- ==================================================
CREATE TABLE IF NOT EXISTS quiz_scores_analysis (
    id SERIAL PRIMARY KEY,
    quiz_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(5) REFERENCES users(user_id) ON DELETE CASCADE,
    user_name VARCHAR(50),
    quiz_title VARCHAR(255),
    quiz_score FLOAT NOT NULL,
    result VARCHAR(50),
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- 5. Quizzes Table
-- ==================================================
CREATE TABLE IF NOT EXISTS quizzes (
    quiz_id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    total_questions INTEGER,
    duration_minutes INTEGER,
    created_by VARCHAR(10) REFERENCES "AdminUsers"(admin_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- ==================================================
-- 6. Quiz Questions Table
-- ==================================================
CREATE TABLE IF NOT EXISTS quiz_questions (
    question_id SERIAL PRIMARY KEY,
    quiz_id VARCHAR(50) REFERENCES quizzes(quiz_id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    option_a VARCHAR(500),
    option_b VARCHAR(500),
    option_c VARCHAR(500),
    option_d VARCHAR(500),
    correct_answer VARCHAR(1) CHECK (correct_answer IN ('A', 'B', 'C', 'D')),
    explanation TEXT,
    points INTEGER DEFAULT 1
);

-- ==================================================
-- INSERT SAMPLE DATA
-- ==================================================

-- Insert a default admin user (password: admin123 - hashed with argon2)
INSERT INTO "AdminUsers" (admin_id, name, email, password, role, created_at)
VALUES (
    'ADM001', 
    'System Admin', 
    'admin@dreamroute.com',
    '$argon2id$v=19$m=65536,t=3,p=4$8R5jzFmLsXYOYcw5h7B2Dg$z8P3qU5xJ2FvK6NwL9tY4mR7sV1nQ0pA3bC8dE6fG2H',
    'superadmin',
    CURRENT_TIMESTAMP
)
ON CONFLICT (email) DO NOTHING;

-- Insert sample users
INSERT INTO users (user_id, name, email, password, role, qualification, location)
VALUES 
    ('U0001', 'John Doe', 'john@example.com', '$argon2id$v=19$m=65536,t=3,p=4$8R5jzFmLsXYOYcw5h7B2Dg$z8P3qU5xJ2FvK6NwL9tY4mR7sV1nQ0pA3bC8dE6fG2H', 'student', 'Bachelor of Science', 'New York'),
    ('U0002', 'Jane Smith', 'jane@example.com', '$argon2id$v=19$m=65536,t=3,p=4$8R5jzFmLsXYOYcw5h7B2Dg$z8P3qU5xJ2FvK6NwL9tY4mR7sV1nQ0pA3bC8dE6fG2H', 'fresher', 'Bachelor of Engineering', 'California')
ON CONFLICT (email) DO NOTHING;

-- Insert sample quiz
INSERT INTO quizzes (quiz_id, title, description, category, difficulty, total_questions, duration_minutes, created_by, is_active)
VALUES 
    ('Q001', 'Python Basics', 'Test your knowledge of Python fundamentals', 'Programming', 'easy', 10, 30, 'ADM001', TRUE)
ON CONFLICT (quiz_id) DO NOTHING;

-- Insert sample quiz questions
INSERT INTO quiz_questions (quiz_id, question_text, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES 
    ('Q001', 'What is Python?', 'A snake', 'A programming language', 'A framework', 'A database', 'B', 'Python is a high-level programming language'),
    ('Q001', 'Which keyword is used to define a function in Python?', 'func', 'def', 'function', 'define', 'B', 'The def keyword is used to define functions in Python')
ON CONFLICT DO NOTHING;

-- ==================================================
-- 7. Industries Table
-- ==================================================
CREATE TABLE IF NOT EXISTS industries (
    industry_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    skills TEXT NOT NULL,
    type VARCHAR(100) NOT NULL,
    demand VARCHAR(50) NOT NULL,
    salary VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ==================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_admin_email ON "AdminUsers"(email);
CREATE INDEX IF NOT EXISTS idx_resumerules_user ON resumerules(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_scores_user ON quiz_scores_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_scores_quiz ON quiz_scores_analysis(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz ON quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_industries_name ON industries(name);

-- ==================================================
-- GRANT PERMISSIONS (Optional - adjust as needed)
-- ==================================================
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;

COMMENT ON TABLE users IS 'Stores user information for students and freshers';
COMMENT ON TABLE "AdminUsers" IS 'Stores admin user credentials and roles';
COMMENT ON TABLE resumerules IS 'Stores resume analysis data';
COMMENT ON TABLE quiz_scores_analysis IS 'Stores quiz completion scores and results';
COMMENT ON TABLE quizzes IS 'Stores quiz metadata';
COMMENT ON TABLE quiz_questions IS 'Stores individual quiz questions and answers';
COMMENT ON TABLE industries IS 'Stores industry data including skills, demand, and salary information';

SELECT 'Database tables created successfully!' AS status;
