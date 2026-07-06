@echo off
echo ========================================
echo Starting DreamRoute Backend Server...
echo ========================================
echo.
cd /d %~dp0

REM Try py first (Windows Python Launcher - most common on Windows)
echo Starting server with 'py' command...
echo.
py -m uvicorn main:app --reload --host localhost --port 8000
if %ERRORLEVEL% == 0 goto :end

echo.
echo ERROR: Failed to start server with 'py' command.
echo Trying alternative Python commands...
echo.

where python3 >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using 'python3' command...
    python3 -m uvicorn main:app --reload --host localhost --port 8000
    goto :end
)

where python >nul 2>&1
if %ERRORLEVEL% == 0 (
    echo Using 'python' command...
    python -m uvicorn main:app --reload --host localhost --port 8000
    goto :end
)

echo.
echo ========================================
echo ERROR: Python not found!
echo ========================================
echo.
echo Please install Python or add it to your PATH.
echo.
echo You can also run manually:
echo   py -m uvicorn main:app --reload --host localhost --port 8000
echo   OR
echo   python -m uvicorn main:app --reload --host localhost --port 8000
echo.
pause
exit /b 1

:end
pause

