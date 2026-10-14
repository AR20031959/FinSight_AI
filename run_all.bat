@echo off
setlocal enabledelayedexpansion
title FinSight AI - Full Stack Launcher

echo ========================================================
echo        FinSight AI - Full Stack Launcher
echo        (FastAPI Backend + Flutter Frontend)
echo ========================================================
echo.

set "ROOT=%~dp0"
set "PYTHON_EXE=%ROOT%.venv\Scripts\python.exe"

if not exist "%PYTHON_EXE%" (
    echo [ERROR] Virtual environment python not found at %PYTHON_EXE%
    echo Falling back to system python...
    set "PYTHON_EXE=python"
)

echo [1/3] Ensuring FastAPI Backend is running on port 8000...
netstat -ano | findstr :8000 | findstr LISTENING >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Starting FastAPI server in background window...
    start "FinSight AI Backend Server (Port 8000)" /MIN cmd /c "cd /d "%ROOT%backend" && "%PYTHON_EXE%" -m uvicorn app.main:app --host 0.0.0.0 --port 8000"
    timeout /t 3 /nobreak >nul
    echo Backend server started on http://127.0.0.1:8000
) else (
    echo FastAPI backend is already running on port 8000.
)

echo.
echo [2/3] Checking connected devices...
where adb >nul 2>nul
if %ERRORLEVEL% equ 0 (
    adb reverse tcp:8000 tcp:8000 >nul 2>nul
)

echo.
echo [3/3] Launching Flutter Application...
echo ========================================================
cd /d "%ROOT%frontend"
flutter run

echo.
echo [FinSight] Flutter session closed.
pause
