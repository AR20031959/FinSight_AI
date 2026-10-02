from typing import List, Optional
# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, Query
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.schemas import TransactionCreate, TransactionUpdate, TransactionResponse, DashboardSummaryResponse
from app.auth import get_current_user
from app.services.finance_engine import (
    add_transaction, 
    update_transaction,
    get_user_transactions, 
    delete_transaction, 
    clear_all_user_transactions,
    calculate_dashboard_summary
)

router = APIRouter(prefix="/api/transactions", tags=["Expense & Income Manager"])

@router.post("/", response_model=TransactionResponse)
def create_tx(
    tx: TransactionCreate, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    return add_transaction(db, current_user.id, tx)

@router.get("/", response_model=List[TransactionResponse])
def list_tx(
    search: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    year: Optional[int] = Query(None),
    month: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    import datetime
    if year and month and not start_date and not end_date:
        start_date = f"{year:04d}-{month:02d}-01"
        if month == 12:
            next_m = datetime.date(year + 1, 1, 1)
        else:
            next_m = datetime.date(year, month + 1, 1)
        last_d = next_m - datetime.timedelta(days=1)
        end_date = last_d.strftime("%Y-%m-%d")
    return get_user_transactions(db, current_user.id, search, category, start_date, end_date)

@router.put("/{tx_id}", response_model=TransactionResponse)
def edit_tx(
    tx_id: int,
    tx_update: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    updated = update_transaction(db, current_user.id, tx_id, tx_update)
    if not updated:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return updated

@router.delete("/clear-all")
def clear_all_tx(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    count = clear_all_user_transactions(db, current_user.id)
    return {"message": f"Successfully deleted all {count} transactions from your account"}

@router.delete("/{tx_id}")
def remove_tx(
    tx_id: int, 
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    success = delete_transaction(db, current_user.id, tx_id)
    if not success:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return {"message": "Transaction deleted successfully"}

@router.get("/summary", response_model=DashboardSummaryResponse)
def get_summary(
    period_type: Optional[str] = Query("monthly"),
    year: Optional[int] = Query(None),
    month: Optional[int] = Query(None),
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    from app.services.finance_engine import get_monthly_financial_summary
    return get_monthly_financial_summary(db, current_user.id, year=year, month=month, period_type=period_type)


