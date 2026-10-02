# pyrefly: ignore [missing-import]
from fastapi import APIRouter, UploadFile, File, Depends
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, Transaction
from app.auth import get_current_user
from app.schemas import StatementParseResponse, StatementImportRequest, StatementImportResponse
from app.services.statement_engine import parse_statement_file

router = APIRouter(prefix="/api/statement", tags=["Statement Analyzer & OCR"])

@router.post("/analyze", response_model=StatementParseResponse)
async def analyze_statement(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    content = await file.read()
    res = parse_statement_file(content, file.filename)
    return res

@router.post("/import", response_model=StatementImportResponse)
def import_statement_transactions(
    req: StatementImportRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    count = 0
    for tx in req.transactions:
        db_tx = Transaction(
            user_id=current_user.id,
            title=tx.title,
            amount=tx.amount,
            type=tx.type.lower(),
            category=tx.category,
            date=tx.date,
            merchant=tx.merchant,
            note=tx.note,
            is_recurring=tx.is_recurring
        )
        db.add(db_tx)
        count += 1
    db.commit()
    return StatementImportResponse(
        imported_count=count,
        message=f"Successfully imported {count} transactions from bank statement into your account."
    )

