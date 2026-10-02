# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Query, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user
from app.services.business_engine import get_business_analytics

router = APIRouter(prefix="/api/business", tags=["Business Analytics Dashboard"])

@router.get("/metrics")
def get_metrics(
    period: str = Query("Monthly", description="Weekly, Monthly, Quarterly, Yearly"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return get_business_analytics(period)
