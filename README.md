# FinSight AI - AI-Powered Financial Decision Intelligence Platform

> **Tagline:** *Understand Your Money. Predict Your Future.*

FinSight AI is a cross-platform Financial Decision Intelligence Application built with Flutter 3.x (Material Design 3) and Python FastAPI (SQLAlchemy, Pandas, NumPy, Scikit-learn, ReportLab, Google Gemini API).

---

## Key Features & 10 Core Modules

1. **Module 1 – Authentication**: Login, Register, Forgot Password, Biometric Security, OTP Verification.
2. **Module 2 – Expense Manager**: Income & Expense tracking, Categories (Food, Travel, Shopping, EMI, Entertainment, Investments, Utilities, Medical, Salary, Business), Search & Filters, Receipt Upload.
3. **Module 3 – Statement Analyzer & OCR**: Upload PDF, CSV, Excel, or Receipt Images to automatically parse transactions, detect merchants, highlight recurring subscriptions, and flag duplicate charges.
4. **Module 4 – AI Financial Advisor**: Conversational intelligence backed by Google Gemini API with context-aware financial guidance.
5. **Module 5 – Investment Planner**: Goal-based planning, SIP Calculator, Lumpsum Calculator, Risk Assessment, and Asset Allocation pie charts.
6. **Module 6 – Business Analytics Dashboard**: Revenue, Profit, Expenses, KPIs (CAC, LTV, ARR, Burn rate), Weekly/Monthly/Quarterly/Yearly filters.
7. **Module 7 – Cash Flow Forecast**: Predictive machine learning engine for 1m, 3m, 6m, and 12m forecasts with 95% confidence bounds and Realistic, Pessimistic, and Optimistic scenario simulations.
8. **Module 8 – Financial Health Score**: 0–100 radial score gauge evaluating Savings Ratio, Debt Ratio, Investment Ratio, Emergency Reserve Runway, and Expense Stability.
9. **Module 9 – Reports**: PDF & Excel document generator for executive summaries and detailed transaction ledgers.
10. **Module 10 – Smart Voice Assistant**: Speech-to-Text command recognition and voice audio response synthesis via Flutter TTS.

---

## Technology Stack

- **Frontend**: Flutter 3.x, Material Design 3, Riverpod, GoRouter, FL Chart, Google Fonts.
- **Backend**: Python 3.12, FastAPI, SQLAlchemy, Pandas, NumPy, Scikit-Learn, PDFPlumber, OpenPyXL, ReportLab, Google Gemini API.
- **Database**: SQLite (Dev) / PostgreSQL (Production).

---

## Quick Start Guide

### 1. Running the FastAPI Backend
```bash
cd backend
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```
API Documentation will be available live at `http://127.0.0.1:8000/docs`.

### 2. Running the Flutter App (Windows Desktop)
```bash
cd frontend
flutter config --enable-windows-desktop
flutter run -d windows
```

### 3. Building for Release

**Windows Executable**:
```bash
cd frontend
flutter build windows
```
Output: `build/windows/x64/runner/Release/`

**Android Release APK**:
```bash
cd frontend
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`
