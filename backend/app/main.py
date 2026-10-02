# pyrefly: ignore [missing-import]
from fastapi import FastAPI
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.database import engine, Base
from app.routes import (
    auth_routes,
    transaction_routes,
    statement_routes,
    ai_routes,
    investment_routes,
    business_routes,
    forecast_routes,
    health_routes,
    report_routes,
    enterprise_routes
)

# Initialize Database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    description="FinSight AI - AI-Powered Financial Decision Intelligence Engine API",
    version="1.0.0"
)

# CORS Middleware setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth_routes.router)
app.include_router(transaction_routes.router)
app.include_router(statement_routes.router)
app.include_router(ai_routes.router)
app.include_router(investment_routes.router)
app.include_router(business_routes.router)
app.include_router(forecast_routes.router)
app.include_router(health_routes.router)
app.include_router(report_routes.router)
app.include_router(enterprise_routes.router)

@app.get("/")
def root():
    return {
        "status": "online",
        "app": settings.APP_NAME,
        "tagline": "Understand Your Money. Predict Your Future.",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    # pyrefly: ignore [missing-import]
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
