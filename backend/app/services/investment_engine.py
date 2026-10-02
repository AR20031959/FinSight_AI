from typing import Dict, Any, List

def calculate_sip(monthly_investment: float, rate: float, tenure_years: int) -> Dict[str, Any]:
    i = (rate / 100.0) / 12.0
    n = tenure_years * 12
    
    total_invested = monthly_investment * n
    if i > 0:
        total_value = monthly_investment * (((1 + i)**n - 1) / i) * (1 + i)
    else:
        total_value = total_invested
        
    est_returns = total_value - total_invested

    yearly_growth = []
    accumulated = 0.0
    invested_accum = 0.0
    for yr in range(1, tenure_years + 1):
        months = yr * 12
        invested_accum = monthly_investment * months
        val = monthly_investment * (((1 + i)**months - 1) / i) * (1 + i) if i > 0 else invested_accum
        yearly_growth.append({
            "year": f"Year {yr}",
            "invested": round(invested_accum, 2),
            "estimated_value": round(val, 2),
            "returns": round(val - invested_accum, 2)
        })

    return {
        "invested_amount": round(total_invested, 2),
        "est_returns": round(est_returns, 2),
        "total_value": round(total_value, 2),
        "yearly_growth": yearly_growth
    }

def get_asset_allocation_recommendation(risk_level: str) -> Dict[str, Any]:
    risk = risk_level.lower()
    if risk == "low" or risk == "conservative":
        return {
            "risk_profile": "Conservative",
            "allocation": {
                "Equity Mutual Funds": 25.0,
                "Debt / Fixed Income": 55.0,
                "Gold / Commodities": 15.0,
                "Cash / Liquid Fund": 5.0
            },
            "expected_return": "7.5% - 9.0%",
            "recommendation": "Focus on capital preservation with steady income through high-grade corporate bonds and debt mutual funds."
        }
    elif risk == "high" or risk == "aggressive":
        return {
            "risk_profile": "Aggressive",
            "allocation": {
                "Equity Mutual Funds": 70.0,
                "Small & Midcap Funds": 15.0,
                "Debt / Fixed Income": 10.0,
                "Gold / Commodities": 5.0
            },
            "expected_return": "13.5% - 16.0%",
            "recommendation": "Maximize long-term wealth compounding with high exposure to diversified equity and growth opportunities."
        }
    else:
        return {
            "risk_profile": "Moderate",
            "allocation": {
                "Equity Mutual Funds": 50.0,
                "Debt / Fixed Income": 30.0,
                "Gold / Commodities": 10.0,
                "Cash / Liquid Fund": 10.0
            },
            "expected_return": "10.5% - 12.5%",
            "recommendation": "Balanced allocation offering healthy capital appreciation while maintaining a solid protective debt shield."
        }
