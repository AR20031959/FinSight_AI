from typing import Optional
# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, Response, Query
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import get_current_user, log_audit_event
from app.services.finance_engine import get_user_transactions, calculate_dashboard_summary
from app.services.report_engine import generate_pdf_report, generate_excel_report, generate_image_report

router = APIRouter(prefix="/api/reports", tags=["Financial Reports"])

@router.get("/pdf")
def download_pdf_report(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log_audit_event(db, current_user.id, "GENERATE_REPORT_PDF", resource="pdf", details=f"Range: {start_date} to {end_date}")
    txs = get_user_transactions(db, current_user.id, start_date=start_date, end_date=end_date)
    tx_dicts = [
        {
            "id": t.id,
            "date": t.date,
            "title": t.title,
            "category": t.category,
            "type": t.type,
            "amount": t.amount,
            "merchant": t.merchant
        } for t in txs
    ]
    summary = calculate_dashboard_summary(db, current_user.id, start_date=start_date, end_date=end_date)
    pdf_bytes = generate_pdf_report(
        user_name=current_user.full_name, 
        transactions=tx_dicts, 
        summary=summary,
        start_date=start_date,
        end_date=end_date
    )
    
    filename = f"finsight_report_{start_date or 'all'}_to_{end_date or 'time'}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/excel")
def download_excel_report(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log_audit_event(db, current_user.id, "GENERATE_REPORT_EXCEL", resource="excel", details=f"Range: {start_date} to {end_date}")
    txs = get_user_transactions(db, current_user.id, start_date=start_date, end_date=end_date)
    tx_dicts = [
        {
            "id": t.id,
            "date": t.date,
            "title": t.title,
            "category": t.category,
            "type": t.type,
            "amount": t.amount,
            "merchant": t.merchant
        } for t in txs
    ]
    summary = calculate_dashboard_summary(db, current_user.id, start_date=start_date, end_date=end_date)
    excel_bytes = generate_excel_report(
        user_name=current_user.full_name, 
        transactions=tx_dicts, 
        summary=summary,
        start_date=start_date,
        end_date=end_date
    )
    
    filename = f"finsight_report_{start_date or 'all'}_to_{end_date or 'time'}.xlsx"
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/image")
def download_image_report(
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log_audit_event(db, current_user.id, "GENERATE_REPORT_IMAGE", resource="image", details=f"Range: {start_date} to {end_date}")
    txs = get_user_transactions(db, current_user.id, start_date=start_date, end_date=end_date)
    tx_dicts = [
        {
            "id": t.id,
            "date": t.date,
            "title": t.title,
            "category": t.category,
            "type": t.type,
            "amount": t.amount,
            "merchant": t.merchant
        } for t in txs
    ]
    summary = calculate_dashboard_summary(db, current_user.id, start_date=start_date, end_date=end_date)
    img_bytes = generate_image_report(
        user_name=current_user.full_name, 
        transactions=tx_dicts, 
        summary=summary,
        start_date=start_date,
        end_date=end_date
    )
    
    filename = f"finsight_infographic_{start_date or 'all'}_to_{end_date or 'time'}.png"
    return Response(
        content=img_bytes,
        media_type="image/png",
        headers={"Content-Disposition": f"inline; filename={filename}"}
    )



