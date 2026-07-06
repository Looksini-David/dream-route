"""
Database Initialization Script
Creates all tables and inserts initial data without requiring psql command line
"""
import sys
import os
from pathlib import Path

# Add Backend to path
backend_path = Path(__file__).parent / 'Backend'
sys.path.insert(0, str(backend_path))

from sqlalchemy import text
from database import engine, SQLALCHEMY_DATABASE_URL, test_connection

def read_sql_file():
    """Read the SQL initialization file"""
    sql_file = Path(__file__).parent / 'init_database.sql'
    if not sql_file.exists():
        print(f"❌ SQL file not found: {sql_file}")
        return None
    
    with open(sql_file, 'r', encoding='utf-8') as f:
        return f.read()

def execute_sql_statements(sql_content):
    """Execute SQL statements from the initialization file"""
    # Split SQL file into individual statements
    # Remove comments and empty lines
    statements = []
    current_statement = []
    
    for line in sql_content.split('\n'):
        # Skip comment lines
        if line.strip().startswith('--') or line.strip().startswith('/*'):
            continue
        
        # Skip empty lines
        if not line.strip():
            continue
            
        current_statement.append(line)
        
        # Check if statement is complete (ends with semicolon)
        if line.strip().endswith(';'):
            statement = '\n'.join(current_statement)
            if statement.strip():
                statements.append(statement)
            current_statement = []
    
    return statements

def initialize_database():
    """Initialize database with tables and data"""
    print("=" * 70)
    print("  DreamRoute Database Initialization")
    print("=" * 70)
    print()
    
    # Test connection first
    print("📋 Database Configuration:")
    print(f"   {SQLALCHEMY_DATABASE_URL}")
    print()
    
    print("🔌 Testing database connection...")
    if not test_connection():
        print()
        print("❌ Cannot connect to database!")
        print()
        print("Troubleshooting:")
        print("1. Make sure PostgreSQL service is running")
        print("2. Verify credentials in .env file")
        print("3. Check if database 'DreamRoute' exists")
        print()
        print("To create the database, you can:")
        print("   - Open pgAdmin and create database 'DreamRoute'")
        print("   - Or run this in any PostgreSQL query tool:")
        print("     CREATE DATABASE DreamRoute;")
        return False
    
    print()
    print("📄 Reading SQL initialization file...")
    sql_content = read_sql_file()
    if not sql_content:
        return False
    
    print("✓ SQL file loaded")
    print()
    
    print("🔨 Creating tables and inserting data...")
    print("   This may take a moment...")
    print()
    
    try:
        with engine.connect() as connection:
            # Execute each statement separately
            statements = execute_sql_statements(sql_content)
            
            success_count = 0
            for i, statement in enumerate(statements, 1):
                try:
                    # Skip certain statements that might cause issues
                    if 'CREATE DATABASE' in statement.upper():
                        continue
                    if '\\c' in statement:
                        continue
                    if 'COMMENT ON' in statement.upper():
                        # Execute comments separately
                        pass
                    
                    connection.execute(text(statement))
                    connection.commit()
                    success_count += 1
                    
                    # Print progress
                    if 'CREATE TABLE' in statement.upper():
                        table_name = statement.split('CREATE TABLE')[1].split('(')[0].strip()
                        if 'IF NOT EXISTS' in statement.upper():
                            table_name = statement.split('IF NOT EXISTS')[1].split('(')[0].strip()
                        print(f"   ✓ Created table: {table_name}")
                    elif 'INSERT INTO' in statement.upper():
                        table_name = statement.split('INSERT INTO')[1].split('(')[0].split('VALUES')[0].strip()
                        print(f"   ✓ Inserted data into: {table_name}")
                    elif 'CREATE INDEX' in statement.upper():
                        index_name = statement.split('CREATE INDEX')[1].split('ON')[0].strip()
                        if 'IF NOT EXISTS' in statement.upper():
                            index_name = statement.split('IF NOT EXISTS')[1].split('ON')[0].strip()
                        print(f"   ✓ Created index: {index_name}")
                        
                except Exception as e:
                    # Many errors are OK (like "table already exists")
                    error_msg = str(e).lower()
                    if 'already exists' in error_msg or 'duplicate' in error_msg:
                        # This is fine, table/data already exists
                        pass
                    else:
                        print(f"   ⚠ Warning: {str(e)[:100]}")
            
            print()
            print(f"✅ Processed {success_count}/{len(statements)} SQL statements")
            
    except Exception as e:
        print(f"❌ Error initializing database: {e}")
        return False
    
    print()
    print("🔍 Verifying database setup...")
    
    try:
        with engine.connect() as connection:
            # Check tables
            result = connection.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
                ORDER BY table_name
            """))
            tables = [row[0] for row in result]
            
            print(f"📁 Tables created ({len(tables)}):")
            for table in tables:
                print(f"   ✓ {table}")
            
            print()
            
            # Check admin user
            result = connection.execute(text("""
                SELECT email FROM "AdminUsers" LIMIT 1
            """))
            admin = result.fetchone()
            if admin:
                print(f"👤 Default admin user created:")
                print(f"   Email: {admin[0]}")
                print(f"   Password: admin123")
            
    except Exception as e:
        print(f"⚠ Could not verify setup: {e}")
    
    print()
    print("=" * 70)
    print("✅ Database initialization completed successfully!")
    print("=" * 70)
    print()
    print("Next steps:")
    print("1. Start the backend: cd Backend && python main.py")
    print("2. Start the frontend: cd Frontend && python -m http.server 5500")
    print("3. Open: http://127.0.0.1:5500/login.html")
    print()
    
    return True

if __name__ == "__main__":
    try:
        success = initialize_database()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠ Interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
