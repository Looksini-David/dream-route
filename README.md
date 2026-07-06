# Dream Route 🎯

AI-powered Career Path Finder application - Web & Mobile

## 📁 Project Structure
- `web-frontend/` - Web app frontend
- `web-backend/` - Web app backend/API
- `mobile-frontend/` - Mobile app frontend
- `mobile-backend/` - Mobile app backend/API

## 🚀 Tech Stack
- Web Frontend: HTML, CSS, JS
- Web Backend: Python, FastAPI
- Mobile Frontend: Flutter
- Mobile Backend: Python, FastAPI

## ⚙️ Setup Instructions

### Web Frontend
```bash
cd web-frontend
# Just open index.html in browser, or use Live Server extension in VS Code
```

### Web Backend
```bash
cd web-backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

> ⚠️ Create a `.env` file in `web-backend/` with your own database credentials (see `.env.example` for reference). This file is git-ignored and won't be shared.

```bash
uvicorn main:app --reload --host localhost --port 8000
```

### Mobile Frontend
```bash
cd mobile-frontend
flutter pub get
flutter run -d chrome --web-port=5000
```

### Mobile Backend
```bash
cd mobile-backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host localhost --port 8000
```

## 👥 Team
- D. Looksini - Project Lead
- P. Geerhiga
- S. Yathuja

## 🌿 Branching Convention
- `feature/web-fe-xyz`
- `feature/web-be-xyz`
- `feature/mobile-fe-xyz`
- `feature/mobile-be-xyz`

## 🤝 Contributing
1. Create a new branch from `main`
2. Make changes and commit
3. Push and create a Pull Request
4. Get 1 approval before merging
