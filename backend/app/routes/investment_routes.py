from typing import List
# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, InvestmentGoal
from app.auth import get_current_user
from app.schemas import (
    SIPCalculateRequest, 
    SIPCalculateResponse, 
    InvestmentGoalCreate, 
    InvestmentGoalResponse
)
from app.services.investment_engine import calculate_sip, get_asset_allocation_recommendation

router = APIRouter(prefix="/api/investments", tags=["Investment Planner"])

@router.post("/calculate-sip", response_model=SIPCalculateResponse)
def sip_calculator(req: SIPCalculateRequest):
    return calculate_sip(req.monthly_investment, req.expected_return_rate, req.tenure_years)

@router.get("/asset-allocation/{risk_level}")
def get_allocation(risk_level: str):
    return get_asset_allocation_recommendation(risk_level)

@router.get("/goals", response_model=List[InvestmentGoalResponse])
def get_goals(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(InvestmentGoal).filter(InvestmentGoal.user_id == current_user.id).all()

@router.post("/goals", response_model=InvestmentGoalResponse)
def create_goal(
    goal: InvestmentGoalCreate, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    db_goal = InvestmentGoal(
        user_id=current_user.id,
        name=goal.name,
        target_amount=goal.target_amount,
        current_amount=goal.current_amount,
        target_years=goal.target_years,
        risk_level=goal.risk_level,
        monthly_sip=goal.monthly_sip
    )
    db.add(db_goal)
    db.commit()
    db.refresh(db_goal)
    return db_goal
