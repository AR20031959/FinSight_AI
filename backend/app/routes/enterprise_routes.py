# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status, Query, Response
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
from app.database import get_db
from app.models import User, Enterprise, EnterpriseMember, Transaction, AuditLog, InvestmentGoal
from app.auth import get_current_user, require_role, log_audit_event, get_password_hash
from app.schemas import (
    EnterpriseDashboardResponse, 
    EnterpriseClientCreate, 
    TransactionCreate, 
    InvestmentGoalCreate
)
from app.services.finance_engine import get_monthly_financial_summary, add_transaction, get_user_transactions
from app.services.report_engine import generate_pdf_report, generate_excel_report, generate_image_report

router = APIRouter(prefix="/api/enterprise", tags=["Enterprise Client & Wealth Management"])

def _get_user_enterprise(db: Session, user: User) -> EnterpriseMember:
    membership = db.query(EnterpriseMember).filter(EnterpriseMember.user_id == user.id).first()
    if not membership:
        ent = Enterprise(name=f"{user.full_name}'s Financial Practice", tax_id="ENT-2026-REG")
        db.add(ent)
        db.commit()
        db.refresh(ent)

        membership = EnterpriseMember(
            enterprise_id=ent.id,
            user_id=user.id,
            member_role="admin",
            status="active"
        )
        db.add(membership)
        db.commit()
        db.refresh(membership)
    return membership

@router.get("/dashboard", response_model=EnterpriseDashboardResponse)
def get_enterprise_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    log_audit_event(db, current_user.id, "VIEW_ENTERPRISE_DASHBOARD", resource="enterprise_dashboard")
    membership = _get_user_enterprise(db, current_user)
    ent_id = membership.enterprise_id
    enterprise = db.query(Enterprise).filter(Enterprise.id == ent_id).first()

    memberships = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == ent_id,
        EnterpriseMember.status == "active"
    ).all()

    member_user_ids = [m.user_id for m in memberships]
    txs = db.query(Transaction).filter(Transaction.user_id.in_(member_user_ids)).all()

    tot_income = sum(t.amount for t in txs if t.type == "income")
    tot_expense = sum(t.amount for t in txs if t.type == "expense")
    tot_investment = sum(t.amount for t in txs if t.type == "investment")

    cat_breakdown: Dict[str, float] = {}
    for t in txs:
        if t.type == "expense":
            cat_breakdown[t.category] = cat_breakdown.get(t.category, 0.0) + t.amount

    ai_queries_count = db.query(AuditLog).filter(
        AuditLog.user_id.in_(member_user_ids),
        AuditLog.action == "AI_QUERY"
    ).count()

    if txs and tot_income > 0:
        savings = max(0.0, tot_income - tot_expense - tot_investment)
        savings_ratio = ((savings + tot_investment) / tot_income * 100.0)
        health_score = round(min(100.0, max(0.0, 45.0 + (savings_ratio * 0.6))), 1)
    else:
        health_score = 0.0

    return EnterpriseDashboardResponse(
        enterprise_id=enterprise.id,
        enterprise_name=enterprise.name,
        total_members=len(memberships),
        active_members=len([m for m in memberships if m.status == "active"]),
        aggregated_metrics={
            "total_income": round(tot_income, 2),
            "total_expense": round(tot_expense, 2),
            "total_investments": round(tot_investment, 2),
            "net_surplus": round(tot_income - tot_expense - tot_investment, 2),
            "category_spending_distribution": cat_breakdown,
            "average_member_health_score": health_score
        },
        usage_statistics={
            "total_transactions_tracked": len(txs),
            "total_ai_advisory_queries": ai_queries_count,
            "reports_generated_count": db.query(AuditLog).filter(
                AuditLog.user_id.in_(member_user_ids),
                AuditLog.action.like("GENERATE_REPORT%")
            ).count()
        },
        privacy_compliance_notice="Privacy Mode Active: Professional Advisory Portal - Client portfolios managed directly."
    )

@router.get("/clients")
@router.get("/members")
def get_enterprise_clients(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    log_audit_event(db, current_user.id, "VIEW_ENTERPRISE_CLIENTS", resource="enterprise_clients")
    membership = _get_user_enterprise(db, current_user)

    members = db.query(EnterpriseMember, User).join(
        User, EnterpriseMember.user_id == User.id
    ).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id
    ).all()

    client_list = []
    for m, u in members:
        # Calculate dynamic summary for client
        summary = get_monthly_financial_summary(db, u.id)
        client_list.append({
            "client_id": u.id,
            "member_id": u.id,
            "full_name": u.full_name,
            "email": u.email,
            "passcode": m.client_passcode or "••••••••",
            "member_role": m.member_role,
            "status": m.status,
            "joined_at": m.joined_at.strftime("%Y-%m-%d"),
            "financial_summary": {
                "monthly_income": summary.get("monthly_income", 0.0),
                "monthly_expense": summary.get("monthly_expense", 0.0),
                "total_investments": summary.get("total_investments", 0.0),
                "savings": summary.get("savings", 0.0),
                "health_score": summary.get("health_score", 0.0),
                "transaction_count": summary.get("transaction_count", 0)
            }
        })

    return client_list

@router.post("/clients/create")
@router.post("/members/add")
def create_enterprise_client(
    client_in: EnterpriseClientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)
    
    # Check if user with given email already exists
    user = db.query(User).filter(User.email == client_in.email).first()
    if not user:
        user = User(
            email=client_in.email,
            full_name=client_in.full_name,
            hashed_password=get_password_hash(client_in.password),
            role="user"
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    # Check existing membership
    existing_mem = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == user.id
    ).first()

    if existing_mem:
        # Update passcode if re-saved
        existing_mem.client_passcode = client_in.password
        db.commit()
    else:
        new_mem = EnterpriseMember(
            enterprise_id=membership.enterprise_id,
            user_id=user.id,
            member_role="client",
            client_passcode=client_in.password,
            status="active"
        )
        db.add(new_mem)
        db.commit()

    log_audit_event(db, current_user.id, "CREATE_ENTERPRISE_CLIENT", resource=user.email, details=f"Created client {user.email}")

    return {
        "message": f"Client '{user.full_name}' successfully added to portfolio.",
        "client": {
            "client_id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "passcode": client_in.password,
            "role": "client"
        }
    }

@router.post("/members/invite")
def invite_member_to_enterprise(
    email: str = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)

    target_user = db.query(User).filter(User.email == email).first()
    if not target_user:
        raise HTTPException(status_code=404, detail=f"User with email '{email}' not found")

    existing = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == target_user.id
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="User is already associated with this enterprise")

    new_member = EnterpriseMember(
        enterprise_id=membership.enterprise_id,
        user_id=target_user.id,
        member_role="member",
        status="active"
    )
    db.add(new_member)
    db.commit()

    log_audit_event(db, current_user.id, "INVITE_ENTERPRISE_MEMBER", resource=f"user_{target_user.id}")

    return {"message": f"Successfully associated user '{email}' with {current_user.full_name}'s Enterprise"}

@router.get("/clients/{client_id}/dashboard")
def get_client_dashboard(
    client_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)
    # Check if client belongs to enterprise
    client_mem = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == client_id
    ).first()

    if not client_mem:
        raise HTTPException(status_code=403, detail="Access denied. Client is not managed under your enterprise account.")

    log_audit_event(db, current_user.id, "ADVISOR_VIEW_CLIENT_DASHBOARD", resource=f"client_{client_id}")
    summary = get_monthly_financial_summary(db, client_id)
    goals = db.query(InvestmentGoal).filter(InvestmentGoal.user_id == client_id).all()
    
    tx_list = []
    for t in summary.get("recent_transactions", []):
        if hasattr(t, "id"):
            tx_list.append({
                "id": t.id,
                "title": t.title,
                "amount": t.amount,
                "type": t.type,
                "category": t.category,
                "date": t.date,
                "merchant": t.merchant
            })
        elif isinstance(t, dict):
            tx_list.append(t)
    summary["recent_transactions"] = tx_list

    summary["investment_goals"] = [
        {
            "id": g.id,
            "name": g.name,
            "target_amount": g.target_amount,
            "current_amount": g.current_amount,
            "target_years": g.target_years,
            "risk_level": g.risk_level,
            "monthly_sip": g.monthly_sip
        }
        for g in goals
    ]
    return summary

@router.post("/clients/{client_id}/transactions")
def add_client_transaction(
    client_id: int,
    tx_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)
    client_mem = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == client_id
    ).first()

    if not client_mem:
        raise HTTPException(status_code=403, detail="Access denied. Client is not managed under your enterprise account.")

    log_audit_event(db, current_user.id, "ADVISOR_ADD_CLIENT_TX", resource=f"client_{client_id}", details=f"Added {tx_in.type} ₹{tx_in.amount}")
    created_tx = add_transaction(db, client_id, tx_in)
    return created_tx

@router.post("/clients/{client_id}/goals")
def create_client_investment_goal(
    client_id: int,
    goal_in: InvestmentGoalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)
    client_mem = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == client_id
    ).first()

    if not client_mem:
        raise HTTPException(status_code=403, detail="Access denied. Client is not managed under your enterprise account.")

    goal = InvestmentGoal(
        user_id=client_id,
        name=goal_in.name,
        target_amount=goal_in.target_amount,
        current_amount=goal_in.current_amount,
        target_years=goal_in.target_years,
        risk_level=goal_in.risk_level,
        monthly_sip=goal_in.monthly_sip
    )
    db.add(goal)
    db.commit()
    db.refresh(goal)

    log_audit_event(db, current_user.id, "ADVISOR_ADD_CLIENT_GOAL", resource=f"client_{client_id}", details=f"Added Goal '{goal.name}'")
    return goal

@router.get("/clients/{client_id}/reports/pdf")
def download_client_pdf_report(
    client_id: int,
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = _get_user_enterprise(db, current_user)
    client_user = db.query(User).filter(User.id == client_id).first()
    client_mem = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id,
        EnterpriseMember.user_id == client_id
    ).first()

    if not client_mem or not client_user:
        raise HTTPException(status_code=403, detail="Access denied for client.")

    txs = get_user_transactions(db, client_id, start_date=start_date, end_date=end_date)
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
    summary = get_monthly_financial_summary(db, client_id, start_date=start_date, end_date=end_date)
    pdf_bytes = generate_pdf_report(
        user_name=client_user.full_name,
        transactions=tx_dicts,
        summary=summary,
        start_date=start_date,
        end_date=end_date
    )
    filename = f"client_{client_id}_report_{start_date or 'all'}_to_{end_date or 'time'}.pdf"
    return Response(content=pdf_bytes, media_type="application/pdf", headers={"Content-Disposition": f"attachment; filename={filename}"})
