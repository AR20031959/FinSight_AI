from typing import Dict, Any, List

def get_business_analytics(filter_period: str = "Monthly") -> Dict[str, Any]:
    period_type = filter_period.title()

    if period_type == "Weekly":
        metrics = [
            {"period": "Week 1", "revenue": 145000, "profit": 52000, "expenses": 93000, "growth": 4.2},
            {"period": "Week 2", "revenue": 162000, "profit": 61000, "expenses": 101000, "growth": 5.8},
            {"period": "Week 3", "revenue": 158000, "profit": 57000, "expenses": 101000, "growth": -2.1},
            {"period": "Week 4", "revenue": 179000, "profit": 74000, "expenses": 105000, "growth": 10.4},
        ]
        total_rev = 644000
        total_prof = 244000
        total_exp = 400000
        avg_growth = 4.58
    elif period_type == "Quarterly":
        metrics = [
            {"period": "Q1 2025", "revenue": 1420000, "profit": 480000, "expenses": 940000, "growth": 8.5},
            {"period": "Q2 2025", "revenue": 1580000, "profit": 560000, "expenses": 1020000, "growth": 11.2},
            {"period": "Q3 2025", "revenue": 1650000, "profit": 590000, "expenses": 1060000, "growth": 4.4},
            {"period": "Q4 2025", "revenue": 1890000, "profit": 710000, "expenses": 1180000, "growth": 14.5},
            {"period": "Q1 2026", "revenue": 1950000, "profit": 760000, "expenses": 1190000, "growth": 3.17},
            {"period": "Q2 2026", "revenue": 2100000, "profit": 840000, "expenses": 1260000, "growth": 7.69},
        ]
        total_rev = 10590000
        total_prof = 3940000
        total_exp = 6650000
        avg_growth = 8.24
    elif period_type == "Yearly":
        metrics = [
            {"period": "2023", "revenue": 4500000, "profit": 1350000, "expenses": 3150000, "growth": 15.0},
            {"period": "2024", "revenue": 5800000, "profit": 1920000, "expenses": 3880000, "growth": 28.8},
            {"period": "2025", "revenue": 6540000, "profit": 2340000, "expenses": 4200000, "growth": 12.7},
            {"period": "2026 (YTD)", "revenue": 4050000, "profit": 1600000, "expenses": 2450000, "growth": 18.2},
        ]
        total_rev = 20890000
        total_prof = 7210000
        total_exp = 13680000
        avg_growth = 18.67
    else:  # Monthly (Default)
        metrics = [
            {"period": "Jan 2026", "revenue": 520000, "profit": 185000, "expenses": 335000, "growth": 6.2},
            {"period": "Feb 2026", "revenue": 545000, "profit": 198000, "expenses": 347000, "growth": 4.8},
            {"period": "Mar 2026", "revenue": 580000, "profit": 215000, "expenses": 365000, "growth": 6.4},
            {"period": "Apr 2026", "revenue": 570000, "profit": 204000, "expenses": 366000, "growth": -1.7},
            {"period": "May 2026", "revenue": 615000, "profit": 232000, "expenses": 383000, "growth": 7.8},
            {"period": "Jun 2026", "revenue": 640000, "profit": 248000, "expenses": 392000, "growth": 4.06},
            {"period": "Jul 2026", "revenue": 680000, "profit": 270000, "expenses": 410000, "growth": 6.25},
        ]
        total_rev = 4150000
        total_prof = 1552000
        total_exp = 2598000
        avg_growth = 4.8

    profit_margin = round((total_prof / total_rev * 100) if total_rev > 0 else 0, 1)

    kpis = {
        "net_profit_margin": f"{profit_margin}%",
        "customer_acquisition_cost": "₹1,450",
        "lifetime_value": "₹38,500",
        "run_rate": "₹8.16 Cr",
        "burn_rate": "₹4.10 L/mo"
    }

    return {
        "filter_period": period_type,
        "total_revenue": total_rev,
        "total_profit": total_prof,
        "total_expenses": total_exp,
        "average_growth_rate": round(avg_growth, 2),
        "profit_margin_percent": profit_margin,
        "kpis": kpis,
        "metrics_breakdown": metrics
    }
