# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user, log_audit_event
from app.schemas import AIAdvisorRequest, AIAdvisorResponse
from app.services.finance_engine import get_monthly_financial_summary
from app.services.ai_engine import ask_gemini_financial_advisor

router = APIRouter(prefix="/api/ai", tags=["AI Financial Advisor"])

@router.post("/chat", response_model=AIAdvisorResponse)
def chat_with_advisor(
    req: AIAdvisorRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log_audit_event(db, current_user.id, "AI_QUERY", resource="chat", details=f"Prompt len: {len(req.prompt)}")
    context = get_monthly_financial_summary(
        db, 
        current_user.id, 
        year=req.year, 
        month=req.month, 
        start_date=req.start_date, 
        end_date=req.end_date
    )
    return ask_gemini_financial_advisor(req.prompt, context)
