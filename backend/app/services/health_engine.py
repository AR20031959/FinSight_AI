from typing import Dict, Any
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from app.models import Transaction

def calculate_health_score(db: Session, user_id: int) -> Dict[str, Any]:
    transactions = db.query(Transaction).filter(Transaction.user_id == user_id).all()

    if not transactions:
        return {
            "overall_score": 0.0,
            "savings_ratio": 0.0,
            "debt_ratio": 0.0,
            "investment_ratio": 0.0,
            "emergency_fund_coverage_months": 0.0,
            "expense_stability_score": 0.0,
            "suggestions": ["No financial activity recorded yet. Add income, expenses, or investments to generate a dynamic health report."]
        }

    income = sum(t.amount for t in transactions if t.type.lower() == "income")
    expenses = sum(t.amount for t in transactions if t.type.lower() == "expense" and t.category != "EMI")
    emi_payments = sum(t.amount for t in transactions if t.category == "EMI")
    investments = sum(t.amount for t in transactions if t.type.lower() in ("investment", "savings"))
    
    net_savings = max(0.0, income - (expenses + emi_payments + investments))

    if income == 0.0:
        # User recorded expenses/investments but no income yet
        return {
            "overall_score": 25.0 if investments > 0 else 10.0,
            "savings_ratio": 0.0,
            "debt_ratio": 100.0 if emi_payments > 0 else 0.0,
            "investment_ratio": 0.0,
            "emergency_fund_coverage_months": 0.0,
            "expense_stability_score": 50.0,
            "suggestions": ["Record your monthly salary or income source to unlock your complete health score analysis."]
        }

    # 1. Savings Ratio (Weight: 25%) - ideal >= 30%
    savings_ratio = max(0.0, (net_savings / income) * 100.0)
    savings_score = min(100.0, (savings_ratio / 30.0) * 100.0)

    # 2. Debt Ratio (Weight: 25%) - ideal EMI <= 30% of income
    debt_ratio = (emi_payments / income) * 100.0
    debt_score = max(0.0, 100.0 - (debt_ratio * 2.0))

    # 3. Investment Ratio (Weight: 20%) - ideal >= 20% of income
    investment_ratio = (investments / income) * 100.0
    investment_score = min(100.0, (investment_ratio / 20.0) * 100.0)

    # 4. Emergency Fund Coverage (Weight: 15%) - ideal >= 6 months
    total_essential = max(1.0, expenses + emi_payments)
    liquid_cash = max(0.0, net_savings + investments)
    emergency_months = liquid_cash / total_essential
    emergency_score = min(100.0, (emergency_months / 6.0) * 100.0)

    # 5. Expense Stability Score (Weight: 15%) - dynamic calculated ratio
    exp_ratio = (expenses / income) * 100.0
    expense_stability_score = max(0.0, min(100.0, 100.0 - abs(exp_ratio - 50.0)))

    # Overall Composite Score (0–100)
    overall_score = (
        (savings_score * 0.25) +
        (debt_score * 0.25) +
        (investment_score * 0.20) +
        (emergency_score * 0.15) +
        (expense_stability_score * 0.15)
    )

    overall_score = round(min(100.0, max(0.0, overall_score)), 1)

    # Actionable recommendations generated dynamically
    suggestions = []
    if savings_ratio < 20:
        suggestions.append("Increase your monthly savings ratio to at least 20% by cutting discretionary expenses.")
    if debt_ratio > 35:
        suggestions.append("Your EMI obligations exceed 35% of monthly income. Consider prepaying high-interest debt.")
    if investment_ratio < 15:
        suggestions.append("Automate an additional 5% SIP into equity index mutual funds to build long-term wealth.")
    if emergency_months < 6:
        suggestions.append(f"Your emergency fund currently covers {emergency_months:.1f} months. Build up to 6 months of essential expenses.")
    else:
        suggestions.append("Excellent emergency fund buffer maintained! You have over 6 months of liquid runway.")

    suggestions.append("Maintain consistent bill payments to preserve your high financial health score.")

    return {
        "overall_score": overall_score,
        "savings_ratio": round(savings_ratio, 1),
        "debt_ratio": round(debt_ratio, 1),
        "investment_ratio": round(investment_ratio, 1),
        "emergency_fund_coverage_months": round(emergency_months, 1),
        "expense_stability_score": round(expense_stability_score, 1),
        "suggestions": suggestions
    }
