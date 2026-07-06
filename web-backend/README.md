# 🚀 DreamRoute - Career Management Platform

Complete setup guide to connect Frontend, Backend, and PostgreSQL Database.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8+** - [Download Python](https://www.python.org/downloads/)
- **PostgreSQL 12+** - [Download PostgreSQL](https://www.postgresql.org/download/)
- **Git** (optional) - For version control
- **VS Code** or any text editor

## 🗄️ Database Setup

### Step 1: Install PostgreSQL

1. Download and install PostgreSQL from the official website
2. During installation, remember your PostgreSQL password
3. Default settings:
   - Username: `postgres`
   - Port: `5432`
   - Host: `localhost`

### Step 2: Create Database

Open PostgreSQL command line (psql) or pgAdmin and run:

```sql
CREATE DATABASE DreamRoute;
```

### Step 3: Initialize Database Tables

Run the SQL initialization script:

**Option A: Using psql command line**
```bash
psql -U postgres -d DreamRoute -f init_database.sql
```

**Option B: Using pgAdmin**
1. Open pgAdmin
2. Connect to PostgreSQL server
3. Right-click on DreamRoute database → Query Tool
4. Open `init_database.sql` file
5. Execute the script (F5)

**Default Credentials Created:**
- Admin Email: `admin@dreamroute.com`
- Admin Password: `admin123`

## 🐍 Backend Setup

### Step 1: Create Virtual Environment

Navigate to the project root directory and create a virtual environment:

**Windows:**
```cmd
cd c:\Users\suvit\Desktop\AI_project_web
python -m venv venv
venv\Scripts\activate
```

**Linux/Mac:**
```bash
cd /path/to/AI_project_web
python3 -m venv venv
source venv/bin/activate
```

### Step 2: Install Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Configure Environment Variables

1. Open the `.env` file in the root directory
2. Update the database credentials if needed:

```env
DB_USER=postgres
DB_PASSWORD=1234
DB_HOST=localhost
DB_PORT=5432
DB_NAME=DreamRoute
```

### Step 4: Test Database Connection

```bash
cd Backend
python -c "from database import test_connection; test_connection()"
```

You should see: `✅ Database connection successful!`

### Step 5: Start Backend Server

```bash
cd Backend
python main.py
```

Or use uvicorn directly:
```bash
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

**Backend will be running at:**
- API: http://127.0.0.1:8000
- Interactive API Docs: http://127.0.0.1:8000/docs
- Alternative Docs: http://127.0.0.1:8000/redoc

## 🌐 Frontend Setup

### Step 1: Configure API Endpoint

The frontend is already configured to connect to the backend at `http://127.0.0.1:8000`.

If you need to change the API URL, edit `Frontend/js/config.js`:

```javascript
const API_BASE_URL = 'http://127.0.0.1:8000';
```

### Step 2: Serve Frontend

**Option A: Using Python HTTP Server**
```bash
cd Frontend
python -m http.server 5500
```

**Option B: Using Live Server Extension in VS Code**
1. Install "Live Server" extension in VS Code
2. Right-click on `index.html` or `login.html`
3. Select "Open with Live Server"

**Option C: Using Node.js http-server**
```bash
npm install -g http-server
cd Frontend
http-server -p 5500
```

**Frontend will be running at:**
- http://127.0.0.1:5500

## 🧪 Testing the Connection

### Test Backend API

1. Open browser and go to: http://127.0.0.1:8000/docs
2. You should see the FastAPI interactive documentation
3. Try the `/health` endpoint - it should return `{"status": "healthy"}`

### Test Frontend-Backend Connection

1. Open: http://127.0.0.1:5500/login.html
2. Login with default admin credentials:
   - Email: `admin@dreamroute.com`
   - Password: `admin123`
3. You should be redirected to the dashboard

## 📁 Project Structure

```
AI_project_web/
├── Backend/
│   ├── main.py                 # Main FastAPI application
│   ├── database.py            # Database configuration
│   ├── auth.py                # Authentication utilities
│   ├── models.py              # Database models
│   ├── schemas.py             # Pydantic schemas
│   ├── routers/               # API route handlers
│   │   ├── login.py
│   │   ├── users.py
│   │   ├── resumes.py
│   │   ├── quizzes.py
│   │   └── quiz_scores.py
│   └── models/                # Additional models
│       └── admin.py
├── Frontend/
│   ├── index.html
│   ├── login.html
│   ├── admin_dashboard.html
│   ├── js/
│   │   ├── config.js          # API configuration
│   │   ├── login.js
│   │   ├── dashboard.js
│   │   └── ...
│   └── css/
│       └── ...
├── .env                       # Environment variables
├── requirements.txt           # Python dependencies
├── init_database.sql          # Database initialization script
└── README.md                  # This file
```

## 🔧 Common Issues and Solutions

### Issue 1: Database Connection Failed

**Error:** `❌ Database connection failed`

**Solution:**
1. Check if PostgreSQL service is running
2. Verify database credentials in `.env` file
3. Ensure database `DreamRoute` exists
4. Check if PostgreSQL is listening on port 5432

### Issue 2: Module Not Found

**Error:** `ModuleNotFoundError: No module named 'fastapi'`

**Solution:**
```bash
pip install -r requirements.txt
```

### Issue 3: CORS Error in Browser

**Error:** `Access to fetch at 'http://127.0.0.1:8000/...' has been blocked by CORS policy`

**Solution:**
- Make sure backend is running
- Check that CORS middleware is properly configured in `main.py`
- Frontend URL must match one of the allowed origins

### Issue 4: Port Already in Use

**Error:** `OSError: [Errno 98] Address already in use`

**Solution:**

**Windows:**
```cmd
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

**Linux/Mac:**
```bash
lsof -ti:8000 | xargs kill -9
```

## 🔐 Security Notes

⚠️ **Important for Production:**

1. **Change default passwords** in `init_database.sql`
2. **Generate a new SECRET_KEY** in `.env` file:
   ```python
   import secrets
   print(secrets.token_urlsafe(32))
   ```
3. **Update CORS origins** in `main.py` to only allow your frontend domain
4. **Use environment variables** for all sensitive data
5. **Enable HTTPS** for production deployment
6. **Use password requirements** and rate limiting

## 📚 API Documentation

Once the backend is running, access the interactive API documentation:

- **Swagger UI:** http://127.0.0.1:8000/docs
- **ReDoc:** http://127.0.0.1:8000/redoc

## 🛠️ Development Workflow

### Starting Development

1. **Start PostgreSQL** service
2. **Activate virtual environment:**
   ```bash
   venv\Scripts\activate  # Windows
   source venv/bin/activate  # Linux/Mac
   ```
3. **Start Backend:**
   ```bash
   cd Backend
   python main.py
   ```
4. **Start Frontend:**
   ```bash
   cd Frontend
   python -m http.server 5500
   ```

### Making Changes

- **Backend changes:** The server will auto-reload (using `--reload` flag)
- **Frontend changes:** Refresh browser to see changes
- **Database schema changes:** 
  1. Update models in `models.py`
  2. Create migration or update `init_database.sql`
  3. Restart backend

## 📞 Support

If you encounter any issues:

1. Check the console/terminal for error messages
2. Verify all services are running
3. Check the logs in the terminal
4. Ensure all dependencies are installed

## 🎉 Success!

If everything is set up correctly:

✅ PostgreSQL is running and database is created  
✅ Backend API is running on http://127.0.0.1:8000  
✅ Frontend is accessible at http://127.0.0.1:5500  
✅ You can login to the admin dashboard  
✅ API documentation is available  

**You're ready to start developing!** 🚀
