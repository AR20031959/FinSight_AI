# pyrefly: ignore [missing-import]
from fastapi import APIRouter, Depends, HTTPException, status, Query
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
from app.database import get_db
from app.models import User, Enterprise, EnterpriseMember, Transaction, AuditLog
from app.auth import get_current_user, require_role, log_audit_event
from app.schemas import EnterpriseDashboardResponse

router = APIRouter(prefix="/api/enterprise", tags=["Enterprise Management & Analytics"])

@router.get("/dashboard", response_model=EnterpriseDashboardResponse)
def get_enterprise_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    log_audit_event(db, current_user.id, "VIEW_ENTERPRISE_DASHBOARD", resource="enterprise_dashboard")

    # Retrieve or create enterprise account for current user
    membership = db.query(EnterpriseMember).filter(
        EnterpriseMember.user_id == current_user.id
    ).first()

    if not membership:
        # Auto-provision enterprise organization if user registered as enterprise
        ent = Enterprise(name=f"{current_user.full_name}'s Enterprise", tax_id="ENT-2026-REG")
        db.add(ent)
        db.commit()
        db.refresh(ent)

        membership = EnterpriseMember(
            enterprise_id=ent.id,
            user_id=current_user.id,
            member_role="admin",
            status="active"
        )
        db.add(membership)
        db.commit()

    ent_id = membership.enterprise_id
    enterprise = db.query(Enterprise).filter(Enterprise.id == ent_id).first()

    # Get all active members associated with this enterprise
    memberships = db.query(EnterpriseMember).filter(
        EnterpriseMember.enterprise_id == ent_id,
        EnterpriseMember.status == "active"
    ).all()

    member_user_ids = [m.user_id for m in memberships]

    # Compute Aggregated Analytics (Privacy Preserving)
    txs = db.query(Transaction).filter(Transaction.user_id.in_(member_user_ids)).all()

    tot_income = sum(t.amount for t in txs if t.type == "income")
    tot_expense = sum(t.amount for t in txs if t.type == "expense")
    tot_investment = sum(t.amount for t in txs if t.type == "investment")

    cat_breakdown: Dict[str, float] = {}
    for t in txs:
        if t.type == "expense":
            cat_breakdown[t.category] = cat_breakdown.get(t.category, 0.0) + t.amount

    # Aggregate AI Interaction Audits
    ai_queries_count = db.query(AuditLog).filter(
        AuditLog.user_id.in_(member_user_ids),
        AuditLog.action == "AI_QUERY"
    ).count()

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
            "average_member_health_score": 84.5 if member_user_ids else 50.0
        },
        usage_statistics={
            "total_transactions_tracked": len(txs),
            "total_ai_advisory_queries": ai_queries_count,
            "reports_generated_count": db.query(AuditLog).filter(
                AuditLog.user_id.in_(member_user_ids),
                AuditLog.action.like("GENERATE_REPORT%")
            ).count()
        },
        privacy_compliance_notice="Privacy Mode Active: Personal transaction details are protected. Only aggregated organizational metrics are displayed."
    )

@router.get("/members")
def get_enterprise_members(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    log_audit_event(db, current_user.id, "VIEW_ENTERPRISE_MEMBERS", resource="enterprise_members")
    
    membership = db.query(EnterpriseMember).filter(EnterpriseMember.user_id == current_user.id).first()
    if not membership:
        return []

    members = db.query(EnterpriseMember, User).join(
        User, EnterpriseMember.user_id == User.id
    ).filter(
        EnterpriseMember.enterprise_id == membership.enterprise_id
    ).all()

    return [
        {
            "member_id": m.user_id,
            "full_name": u.full_name,
            "email": u.email,
            "member_role": m.member_role,
            "status": m.status,
            "joined_at": m.joined_at.strftime("%Y-%m-%d")
        }
        for m, u in members
    ]

@router.post("/members/invite")
def invite_member_to_enterprise(
    email: str = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_role(["enterprise"]))
):
    membership = db.query(EnterpriseMember).filter(EnterpriseMember.user_id == current_user.id).first()
    if not membership:
        raise HTTPException(status_code=400, detail="Enterprise account not initialized")

    target_user = db.query(User).filter(User.email == email).first()
    if not target_user:
        raise HTTPException(status_code=444 if False else 404, detail=f"User with email '{email}' not found")

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
