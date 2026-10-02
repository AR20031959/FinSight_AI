# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user
from app.schemas import HealthScoreBreakdown
from app.services.health_engine import calculate_health_score

router = APIRouter(prefix="/api/health", tags=["Financial Health Score"])

@router.get("/score", response_model=HealthScoreBreakdown)
def get_score(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return calculate_health_score(db, current_user.id)
