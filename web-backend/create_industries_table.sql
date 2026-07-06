-- Migration script to create industries table
-- Run this if you already have a database but need to add the industries table

-- Create industries table
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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_industries_name ON industries(name);

-- Add comment
COMMENT ON TABLE industries IS 'Stores industry data including skills, demand, and salary information';

-- Optional: Insert sample data (uncomment if needed)
-- INSERT INTO industries (name, skills, type, demand, salary) VALUES
--     ('Information Technology', 'Programming, Cloud Computing, Cybersecurity', 'IT', 'High', '₹12LPA'),
--     ('Healthcare', 'Medical Knowledge, Patient Care, Emergency Response', 'Medical', 'Very High', '₹10LPA'),
--     ('Finance & Banking', 'Financial Analysis, Risk Management, Accounting', 'Finance', 'High', '₹15LPA')
-- ON CONFLICT DO NOTHING;

SELECT 'Industries table created successfully!' AS status;

