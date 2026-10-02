import datetime
from typing import Dict, Any, List
# pyrefly: ignore [missing-import]
import numpy as np

def generate_cash_flow_forecast(timeframe: str = "6 Months") -> Dict[str, Any]:
    # Determine number of future months
    if "1 Month" in timeframe:
        months_count = 1
    elif "3 Months" in timeframe:
        months_count = 3
    elif "12 Months" in timeframe:
        months_count = 12
    else:
        months_count = 6

    # Historical data (last 6 months)
    historical = [
        {"period": "Feb 2026", "income": 125000, "expense": 72000, "net": 53000},
        {"period": "Mar 2026", "income": 130000, "expense": 68000, "net": 62000},
        {"period": "Apr 2026", "income": 128000, "expense": 74000, "net": 54000},
        {"period": "May 2026", "income": 140000, "expense": 71000, "net": 69000},
        {"period": "Jun 2026", "income": 145000, "expense": 69000, "net": 76000},
        {"period": "Jul 2026", "income": 150000, "expense": 75000, "net": 75000},
    ]

    base_income = 150000.0
    base_expense = 75000.0
    
    forecast_points = []
    pessimistic_points = []
    optimistic_points = []

    month_names = ["Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul"]

    current_balance = 345000.0

    for i in range(1, months_count + 1):
        m_name = month_names[(i - 1) % 12]
        yr = 2026 if (i - 1) < 5 else 2027
        period_str = f"{m_name} {yr}"

        # Projected realistic growth
        income_proj = base_income * (1 + 0.02 * i)
        expense_proj = base_expense * (1 + 0.015 * i)
        net_proj = income_proj - expense_proj
        current_balance += net_proj

        margin = current_balance * 0.05 * i

        forecast_points.append({
            "period": period_str,
            "predicted_balance": round(current_balance, 2),
            "predicted_income": round(income_proj, 2),
            "predicted_expense": round(expense_proj, 2),
            "lower_bound": round(max(0, current_balance - margin), 2),
            "upper_bound": round(current_balance + margin, 2)
        })

        # Scenarios
        pess_bal = current_balance * (1 - 0.08 * (i / months_count))
        opt_bal = current_balance * (1 + 0.12 * (i / months_count))

        pessimistic_points.append({
            "period": period_str,
            "predicted_balance": round(pess_bal, 2),
            "predicted_income": round(income_proj * 0.9, 2),
            "predicted_expense": round(expense_proj * 1.1, 2),
            "lower_bound": round(pess_bal * 0.9, 2),
            "upper_bound": round(pess_bal * 1.05, 2)
        })

        optimistic_points.append({
            "period": period_str,
            "predicted_balance": round(opt_bal, 2),
            "predicted_income": round(income_proj * 1.15, 2),
            "predicted_expense": round(expense_proj * 0.95, 2),
            "lower_bound": round(opt_bal * 0.95, 2),
            "upper_bound": round(opt_bal * 1.1, 2)
        })

    return {
        "timeframe": timeframe,
        "historical": historical,
        "forecast": forecast_points,
        "scenarios": {
            "Realistic": forecast_points,
            "Pessimistic": pessimistic_points,
            "Optimistic": optimistic_points
        }
    }
