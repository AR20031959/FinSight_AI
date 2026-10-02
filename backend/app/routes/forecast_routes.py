# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Query, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user
from app.schemas import CashFlowForecastResponse
from app.services.forecast_engine import generate_cash_flow_forecast

router = APIRouter(prefix="/api/forecast", tags=["Cash Flow Forecast Engine"])

@router.get("/", response_model=CashFlowForecastResponse)
def get_forecast(
    timeframe: str = Query("6 Months", description="Next Month, 3 Months, 6 Months, 12 Months"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return generate_cash_flow_forecast(timeframe)
