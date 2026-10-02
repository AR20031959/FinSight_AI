import datetime
from typing import List, Dict, Any, Optional
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.models import Transaction, RecurringBill
from app.schemas import TransactionCreate

def add_transaction(db: Session, user_id: int, tx: TransactionCreate) -> Transaction:
    db_tx = Transaction(
        user_id=user_id,
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
    db.commit()
    db.refresh(db_tx)
    return db_tx

def get_user_transactions(
    db: Session, 
    user_id: int, 
    search: Optional[str] = None, 
    category: Optional[str] = None, 
    start_date: Optional[str] = None, 
    end_date: Optional[str] = None
) -> List[Transaction]:
    query = db.query(Transaction).filter(Transaction.user_id == user_id)
    if search:
        query = query.filter(
            (Transaction.title.ilike(f"%{search}%")) | 
            (Transaction.merchant.ilike(f"%{search}%")) |
            (Transaction.category.ilike(f"%{search}%"))
        )
    if category and category != "All":
        query = query.filter(Transaction.category == category)
    if start_date:
        query = query.filter(Transaction.date >= start_date)
    if end_date:
        query = query.filter(Transaction.date <= end_date)
    
    return query.order_by(Transaction.date.desc()).all()

def update_transaction(db: Session, user_id: int, tx_id: int, tx_data) -> Transaction:
    tx = db.query(Transaction).filter(Transaction.id == tx_id, Transaction.user_id == user_id).first()
    if not tx:
        return None
    
    update_dict = tx_data.dict(exclude_unset=True)
    for key, val in update_dict.items():
        if val is not None:
            if key == "type":
                setattr(tx, key, val.lower())
            else:
                setattr(tx, key, val)
    
    db.commit()
    db.refresh(tx)
    return tx

def delete_transaction(db: Session, user_id: int, tx_id: int) -> bool:
    tx = db.query(Transaction).filter(Transaction.id == tx_id, Transaction.user_id == user_id).first()
    if tx:
        db.delete(tx)
        db.commit()
        return True
    return False

def clear_all_user_transactions(db: Session, user_id: int) -> int:
    deleted = db.query(Transaction).filter(Transaction.user_id == user_id).delete()
    db.commit()
    return deleted

from app.services.health_engine import calculate_health_score

def get_monthly_financial_summary(
    db: Session, 
    user_id: int, 
    year: Optional[int] = None, 
    month: Optional[int] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    period_type: Optional[str] = "monthly"
) -> Dict[str, Any]:
    """
    Single Source of Truth analytics service for Dashboard UI, Analytics, Reports, and AI Assistant.
    Calculates precise, non-fabricated financial metrics directly from actual user transactions.
    """
    period_label = "All Months"
    
    if period_type == "yearly":
        if year:
            start_date = f"{year:04d}-01-01"
            end_date = f"{year:04d}-12-31"
            period_label = f"Year {year}"
        else:
            period_label = "All Years"
    else:
        if year and month:
            start_date = f"{year:04d}-{month:02d}-01"
            if month == 12:
                next_month = datetime.date(year + 1, 1, 1)
            else:
                next_month = datetime.date(year, month + 1, 1)
            last_day = next_month - datetime.timedelta(days=1)
            end_date = last_day.strftime("%Y-%m-%d")
            try:
                dt_label = datetime.date(year, month, 1)
                period_label = dt_label.strftime("%B %Y")
            except Exception:
                period_label = f"{year:04d}-{month:02d}"
        elif year:
            start_date = f"{year:04d}-01-01"
            end_date = f"{year:04d}-12-31"
            period_label = f"All Months ({year})"

    transactions = get_user_transactions(db, user_id, start_date=start_date, end_date=end_date)
    all_user_txs = get_user_transactions(db, user_id)

    total_income = sum(t.amount for t in transactions if t.type.lower() == "income")
    total_expense = sum(t.amount for t in transactions if t.type.lower() == "expense")
    total_investments = sum(t.amount for t in transactions if t.type.lower() in ("investment", "savings"))
    
    total_balance = total_income - total_expense - total_investments
    savings = max(0.0, total_income - total_expense - total_investments)
    savings_rate = (savings / total_income * 100.0) if total_income > 0 else 0.0

    # Category breakdown for Expenses & Investments
    category_breakdown: Dict[str, float] = {}
    investment_breakdown: Dict[str, float] = {}
    
    largest_expense = None
    max_exp_amount = 0.0
    recurring_expenses_list = []
    total_recurring_amount = 0.0

    for t in transactions:
        t_type = t.type.lower()
        if t_type == "expense":
            category_breakdown[t.category] = category_breakdown.get(t.category, 0.0) + t.amount
            if t.amount > max_exp_amount:
                max_exp_amount = t.amount
                largest_expense = {
                    "title": t.title,
                    "amount": t.amount,
                    "category": t.category,
                    "merchant": t.merchant,
                    "date": t.date
                }
            if t.is_recurring:
                recurring_expenses_list.append({"title": t.title, "amount": t.amount, "category": t.category})
                total_recurring_amount += t.amount
        elif t_type in ("investment", "savings"):
            investment_breakdown[t.category] = investment_breakdown.get(t.category, 0.0) + t.amount
            if t.is_recurring:
                recurring_expenses_list.append({"title": t.title, "amount": t.amount, "category": t.category})
                total_recurring_amount += t.amount

    # Dynamic available years from user transactions
    year_set = set()
    for t in all_user_txs:
        if len(t.date) >= 4 and t.date[:4].isdigit():
            year_set.add(int(t.date[:4]))
    if not year_set:
        year_set.add(datetime.date.today().year)
    available_years = sorted(list(year_set))

    # Month-over-month and Year-over-Year trend analysis computed dynamically
    monthly_trend_map: Dict[str, Dict[str, float]] = {}
    yearly_trend_map: Dict[str, Dict[str, float]] = {}

    for t in all_user_txs:
        if len(t.date) >= 7:
            ym_key = t.date[:7] # YYYY-MM
            y_key = t.date[:4]  # YYYY

            if ym_key not in monthly_trend_map:
                monthly_trend_map[ym_key] = {"income": 0.0, "expense": 0.0, "investment": 0.0}
            if y_key not in yearly_trend_map:
                yearly_trend_map[y_key] = {"income": 0.0, "expense": 0.0, "investment": 0.0}

            t_type = t.type.lower()
            if t_type == "income":
                monthly_trend_map[ym_key]["income"] += t.amount
                yearly_trend_map[y_key]["income"] += t.amount
            elif t_type == "expense":
                monthly_trend_map[ym_key]["expense"] += t.amount
                yearly_trend_map[y_key]["expense"] += t.amount
            elif t_type in ("investment", "savings"):
                monthly_trend_map[ym_key]["investment"] += t.amount
                yearly_trend_map[y_key]["investment"] += t.amount

    # Ensure all 12 months of target year exist in monthly_trend for timeline continuity when year is specified
    target_year_for_trend = year or datetime.date.today().year
    for m_idx in range(1, 13):
        m_ym = f"{target_year_for_trend:04d}-{m_idx:02d}"
        if m_ym not in monthly_trend_map:
            monthly_trend_map[m_ym] = {"income": 0.0, "expense": 0.0, "investment": 0.0}

    # Ensure all available years exist in yearly_trend_map
    for yr_num in available_years:
        yr_str = f"{yr_num}"
        if yr_str not in yearly_trend_map:
            yearly_trend_map[yr_str] = {"income": 0.0, "expense": 0.0, "investment": 0.0}

    # Sort trend chronological for target year (all 12 months)
    target_year_prefix = f"{target_year_for_trend:04d}-"
    target_months = [ym for ym in sorted(monthly_trend_map.keys()) if ym.startswith(target_year_prefix)]
    if not target_months:
        target_months = sorted(monthly_trend_map.keys())[-12:]

    monthly_trend = []
    for ym in target_months:
        try:
            dt = datetime.datetime.strptime(ym, "%Y-%m").date()
            m_label = dt.strftime("%b")
        except Exception:
            m_label = ym
        data = monthly_trend_map[ym]
        monthly_trend.append({
            "month": m_label,
            "year_month": ym,
            "income": round(data["income"], 2),
            "expense": round(data["expense"], 2),
            "investment": round(data["investment"], 2)
        })


    if not monthly_trend:
        curr_m = datetime.date.today().strftime("%b")
        monthly_trend = [{
            "month": curr_m,
            "year_month": datetime.date.today().strftime("%Y-%m"),
            "income": total_income,
            "expense": total_expense,
            "investment": total_investments
        }]

    # Build yearly trend list
    sorted_years = sorted(yearly_trend_map.keys())
    yearly_trend = []
    for y_str in sorted_years:
        data = yearly_trend_map[y_str]
        y_savings = max(0.0, data["income"] - data["expense"] - data["investment"])
        yearly_trend.append({
            "year": y_str,
            "income": round(data["income"], 2),
            "expense": round(data["expense"], 2),
            "investment": round(data["investment"], 2),
            "savings": round(y_savings, 2),
            "net_cash_flow": round(data["income"] - data["expense"] - data["investment"], 2)
        })

    if not yearly_trend:
        curr_y = str(datetime.date.today().year)
        yearly_trend = [{
            "year": curr_y,
            "income": total_income,
            "expense": total_expense,
            "investment": total_investments,
            "savings": savings,
            "net_cash_flow": total_balance
        }]

    # Month-over-month change calculation relative to requested selected month
    mom_change = {"income_change_pct": 0.0, "expense_change_pct": 0.0}
    sorted_months = sorted(monthly_trend_map.keys())
    target_ym = f"{year:04d}-{month:02d}" if (year and month) else (sorted_months[-1] if sorted_months else None)

    if target_ym and target_ym in monthly_trend_map:
        try:
            t_dt = datetime.datetime.strptime(target_ym, "%Y-%m").date()
            prev_dt = (t_dt.replace(day=1) - datetime.timedelta(days=1)).replace(day=1)
            prev_ym = prev_dt.strftime("%Y-%m")
            if prev_ym in monthly_trend_map:
                prev_exp = monthly_trend_map[prev_ym]["expense"]
                curr_exp = monthly_trend_map[target_ym]["expense"]
                prev_inc = monthly_trend_map[prev_ym]["income"]
                curr_inc = monthly_trend_map[target_ym]["income"]
                if prev_exp > 0:
                    mom_change["expense_change_pct"] = round(((curr_exp - prev_exp) / prev_exp) * 100.0, 1)
                if prev_inc > 0:
                    mom_change["income_change_pct"] = round(((curr_inc - prev_inc) / prev_inc) * 100.0, 1)
        except Exception:
            pass

    # SINGLE SOURCE OF TRUTH: Health score calculated dynamically from health_engine
    health_data = calculate_health_score(db, user_id)
    health_score = health_data.get("overall_score", 0.0)

    # Upcoming bills
    upcoming_bills_query = db.query(RecurringBill).filter(
        RecurringBill.user_id == user_id, 
        RecurringBill.is_paid == False
    ).limit(5).all()
    
    upcoming_bills = [
        {
            "id": b.id,
            "biller_name": b.biller_name,
            "amount": b.amount,
            "due_date": b.due_date,
            "category": b.category
        }
        for b in upcoming_bills_query
    ]

    # AI quick insights
    insights = []
    if total_expense > 0 and total_income > 0:
        ratio = (total_expense / total_income) * 100
        if ratio > 80:
            insights.append(f"High Spending Alert: You spent {ratio:.1f}% of your income.")
        else:
            insights.append(f"Great Job! Your monthly spending ratio is healthy at {ratio:.1f}%.")
    
    if total_investments > 0 and total_income > 0:
        inv_ratio = (total_investments / total_income) * 100
        insights.append(f"Wealth Building: You invested {inv_ratio:.1f}% of your income (INR {total_investments:,.0f}).")
    
    top_cat = max(category_breakdown, key=category_breakdown.get) if category_breakdown else "None"
    if top_cat != "None":
        insights.append(f"Top Expense Category: '{top_cat}' accounts for INR {category_breakdown[top_cat]:,.2f}.")
    
    if not insights:
        insights.append("No financial data available for this period.")

    recent = sorted(transactions, key=lambda x: x.date, reverse=True)[:10]

    return {
        "period": period_label,
        "period_type": period_type or "monthly",
        "available_years": available_years,
        "total_balance": round(total_balance, 2),
        "monthly_income": round(total_income, 2),
        "monthly_expense": round(total_expense, 2),
        "total_investments": round(total_investments, 2),
        "savings": round(savings, 2),
        "savings_rate": round(savings_rate, 1),
        "health_score": round(health_score, 1),
        "transaction_count": len(transactions),
        "category_breakdown": category_breakdown,
        "investment_breakdown": investment_breakdown,
        "largest_expense": largest_expense,
        "recurring_expenses": recurring_expenses_list,
        "total_recurring_amount": round(total_recurring_amount, 2),
        "month_over_month_changes": mom_change,
        "monthly_trend": monthly_trend,
        "yearly_trend": yearly_trend,
        "recent_transactions": recent,
        "upcoming_bills": upcoming_bills,
        "ai_insights": insights
    }

def calculate_dashboard_summary(db: Session, user_id: int, start_date: Optional[str] = None, end_date: Optional[str] = None) -> Dict[str, Any]:
    return get_monthly_financial_summary(db, user_id, start_date=start_date, end_date=end_date)


