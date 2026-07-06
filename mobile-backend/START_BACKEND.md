# 🚀 How to Start the Backend Server

## Quick Start

### Option 1: Use the Batch File (Windows)
1. Double-click `backend/start_server.bat`
2. Wait for the server to start
3. You should see: `✅ /login endpoint found` and `✅ /register endpoint found`

### Option 2: Manual Start
1. Open a terminal/command prompt
2. Navigate to the backend folder:
   ```bash
   cd backend
   ```
3. Start the server:
   ```bash
   py -m uvicorn main:app --reload --host localhost --port 8000
   ```

## ✅ Verify Backend is Running

1. Open your browser and go to: `http://localhost:8000/`
   - You should see: `{"message": "Backend running successfully 🚀"}`

2. Check API documentation: `http://localhost:8000/docs`
   - You should see `/login` and `/register` endpoints listed

3. Test health endpoint: `http://localhost:8000/health`
   - Should return: `{"status": "healthy"}`

## 🔧 Troubleshooting

### Backend Not Starting?
- Make sure Python is installed: `py --version`
- Make sure you're in the `backend` directory
- Check if port 8000 is already in use

### Getting 404 Errors?
- **Make sure the backend is running!** The frontend cannot connect if the backend is not started.
- Check the backend terminal for any error messages
- Verify endpoints at `http://localhost:8000/docs`

### Connection Errors?
- Ensure backend is running on `localhost:8000`
- Check firewall settings
- Try restarting the backend server

## 📝 Important Notes

- **Keep the backend terminal open** while using the frontend
- The backend must be running before you can login or register
- If you see "Backend server is not running" error in the frontend, start the backend first

## 🎯 Next Steps

Once the backend is running:
1. Start your Flutter frontend: `flutter run -d chrome --web-port=5000`
2. Navigate to: `http://localhost:5000/#/login`
3. Try logging in or registering!

