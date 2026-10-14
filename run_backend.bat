@echo off
title FinSight AI Backend (FastAPI)
echo Starting FinSight AI Backend on http://127.0.0.1:8000 ...
cd /d "%~dp0backend"
"%~dp0.venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
