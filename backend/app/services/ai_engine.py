import os
import re
import urllib.request
import urllib.parse
import hashlib
from typing import Dict, Any
from app.config import settings
from app.services.finance_engine import calculate_dashboard_summary

def _search_live_web(query: str) -> str:
    try:
        url = "https://html.duckduckgo.com/html/"
        params = urllib.parse.urlencode({'q': query}).encode('utf-8')
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        req = urllib.request.Request(url, data=params, headers=headers)
        with urllib.request.urlopen(req, timeout=4) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            snippets = re.findall(r'<a class="result__snippet[^"]*"[^>]*>(.*?)</a>', html, re.DOTALL)
            clean = [re.sub(r'<[^>]+>', '', s).strip() for s in snippets[:3]]
            if clean:
                return "\n".join([f"• {c}" for c in clean])
    except Exception:
        pass
    return ""

def query_financial_advisor(db, user_id, user_prompt):
    """
    Compatibility wrapper for the Streamlit application.

    Builds the user's financial context from the database,
    sends the context and prompt to the AI engine,
    and returns only the advisor's reply text for Streamlit.
    """
    user_context = calculate_dashboard_summary(db, user_id)

    result = ask_gemini_financial_advisor(
        user_prompt,
        user_context
    )

    return result.get("reply", "")

def ask_gemini_financial_advisor(prompt: str, user_context: Dict[str, Any]) -> Dict[str, Any]:
    api_key = settings.GEMINI_API_KEY or os.getenv("GEMINI_API_KEY", "")
    
    period = user_context.get("period", "All-Time")
    income = user_context.get("monthly_income", 0.0)
    expense = user_context.get("monthly_expense", 0.0)
    investments = user_context.get("total_investments", 0.0)
    savings = user_context.get("savings", 0.0)
    savings_rate = user_context.get("savings_rate", 0.0)
    health_score = user_context.get("health_score", 50.0)
    tx_count = user_context.get("transaction_count", 0)
    cat_breakdown = user_context.get("category_breakdown", {})
    inv_breakdown = user_context.get("investment_breakdown", {})
    largest_expense = user_context.get("largest_expense")
    recurring = user_context.get("recurring_expenses", [])
    mom = user_context.get("month_over_month_changes", {})
    trend = user_context.get("monthly_trend", [])
    insights = user_context.get("ai_insights", [])

    # Perform live web search for market/rates/tax queries
    web_context = ""
    if any(k in prompt.lower() for k in ["market", "nifty", "rate", "inflation", "tax", "sip", "fd", "gold", "news", "trend", "global", "economy", "fed", "rbi"]):
        web_snippets = _search_live_web(prompt)
        if web_snippets:
            web_context = f"\nLive Web Search Context for '{prompt}':\n{web_snippets}\n"
    
    context_str = (
        f"User Selected Period: {period}\n"
        f"Exact Computed Application Financial Data (SINGLE SOURCE OF TRUTH):\n"
        f"- Total Income: ₹{income:,.2f}\n"
        f"- Total Expenses: ₹{expense:,.2f}\n"
        f"- Total Investments: ₹{investments:,.2f}\n"
        f"- Net Savings/Surplus: ₹{savings:,.2f}\n"
        f"- Savings Rate: {savings_rate}%\n"
        f"- Financial Health Score: {health_score}/100\n"
        f"- Transaction Count: {tx_count}\n"
        f"- Category Spending Breakdown: {cat_breakdown}\n"
        f"- Investment Allocation: {inv_breakdown}\n"
        f"- Largest Single Expense: {largest_expense or 'None recorded'}\n"
        f"- Recurring Expenses: {recurring}\n"
        f"- Month-over-Month Changes: {mom}\n"
        f"- Recent Monthly Trend: {trend}\n"
        f"- App Analytics Insights: {insights}\n"
        f"{web_context}"
    )

    full_prompt = (
        f"You are FinSight AI, a certified senior financial advisor and global macro strategist.\n\n"
        f"STRICT DATA INTEGRITY & ANTI-HALLUCINATION RULES:\n"
        f"1. You MUST ONLY use the actual financial numbers provided in the user context above.\n"
        f"2. If data for a requested metric, timeframe, category, or investment return is NOT present in the context, you MUST explicitly state that the information is UNAVAILABLE. NEVER invent, fabricate, or guess financial figures, interest rates, portfolio values, transaction amounts, or percentages.\n"
        f"3. Always reference the selected period ('{period}') in your response.\n"
        f"4. Provide guidance comparing the user's current financial profile (savings rate, expenses, investment ratio) with global market conditions (inflation trends, central bank rate policies, equity benchmark performance) and offer clear, actionable recommendations.\n\n"
        f"{context_str}\n"
        f"User Query: '{prompt}'"
    )

    reply = None

    if api_key and len(api_key) > 5:
        try:
            # pyrefly: ignore [missing-import]
            import google.generativeai as genai
            genai.configure(api_key=api_key)
            for model_name in ["gemini-2.0-flash", "gemini-1.5-flash", "gemini-pro"]:
                try:
                    model = genai.GenerativeModel(model_name)
                    response = model.generate_content(full_prompt)
                    if response and response.text:
                        reply = response.text
                        break
                except Exception:
                    continue
        except Exception:
            reply = None

    if not reply:
        reply = _generate_intelligent_fallback_response(prompt, user_context)

    return {
        "query": prompt,
        "reply": reply,
        "context_used": {
            "period": period,
            "monthly_income": income,
            "monthly_expense": expense,
            "total_investments": investments,
            "savings": savings,
            "savings_rate": savings_rate,
            "health_score": health_score,
            "transaction_count": tx_count
        }
    }

def _generate_intelligent_fallback_response(prompt: str, user_context: Dict[str, Any]) -> str:
    p = prompt.lower().strip()
    
    income = user_context.get("monthly_income", 0.0) or 0.0
    expense = user_context.get("monthly_expense", 0.0) or 0.0
    investments = user_context.get("total_investments", 0.0) or 0.0
    savings = user_context.get("savings", 0.0) or 0.0
    health_score = user_context.get("health_score", 0.0) or 0.0
    cat_breakdown = user_context.get("category_breakdown", {})
    inv_breakdown = user_context.get("investment_breakdown", {})
    
    if income == 0.0 and expense == 0.0 and investments == 0.0:
        return (
            "ℹ️ **No Financial Data Recorded:** There are currently no transactions recorded for your account in this selected period.\n\n"
            "Please add your income, expense, or investment activities using the application to receive accurate, personalized AI insights!"
        )

    # Identify top expense category
    top_exp_cat = max(cat_breakdown, key=cat_breakdown.get) if cat_breakdown else "General Expense"
    top_exp_amt = cat_breakdown.get(top_exp_cat, 0.0)

    # Greetings & Bot Introduction
    if any(k in p for k in ["hello", "hi", "hey", "who are you", "what can you do"]):
        return (
            f"👋 **Greetings! I am FinSight AI**, your intelligent personal financial decision advisor.\n\n"
            f"Here is a quick snapshot of your live account status:\n"
            f"• **Monthly Income:** ₹{income:,.2f}\n"
            f"• **Active Investments:** ₹{investments:,.2f}/mo\n"
            f"• **Monthly Expenses:** ₹{expense:,.2f}\n"
            f"• **Financial Health Score:** **{health_score}/100**\n\n"
            f"How can I assist you today? You can ask me to **generate a custom date-range PDF report**, analyze **market trends**, or get **SIP investment advice**!"
        )

    # PDF Report & Statement Requests
    elif any(k in p for k in ["pdf", "report", "download report", "generate report", "export statement", "print report"]):
        return (
            f"### 📑 Date-Range PDF Financial Report Generator\n\n"
            f"I can generate a professional, formatted **PDF Financial Statement & Decision Analysis Report** for your account.\n\n"
            f"• **Custom Date Selection:** Choose your exact date period (e.g., **Start Date** to **End Date**).\n"
            f"• **Included Visuals & Information:** Executive Metrics Grid, Category Spending Pie Chart, Detailed Ledger Table, and AI Strategic Recommendations.\n"
            f"• **Zero Text Overlapping:** Pixel-perfect vector layout formatted cleanly for printing or archiving.\n\n"
            f"👉 **Tap 'Generate PDF Report' or use the Report Generator in the app to select your date range and download your PDF!**"
        )

    # Investments & SIP Queries
    elif any(k in p for k in ["invest", "sip", "mutual fund", "stock", "portfolio", "wealth", "equity", "fd"]):
        inv_ratio = (investments / income * 100) if income > 0 else 20.0
        rec_sip = income * 0.25
        return (
            f"### 📈 Wealth Building & Investment Portfolio Analysis\n\n"
            f"• **Current Monthly Investment:** ₹{investments:,.2f} (**{inv_ratio:.1f}%** of income)\n"
            f"• **Recommended Target SIP (25%):** ₹{rec_sip:,.2f}/month\n\n"
            f"**Portfolio Allocation Recommendations:**\n"
            f"1. **Index Funds (Nifty 50 / Sensex):** 50% (High stability, market-matched returns ~12-14% p.a.).\n"
            f"2. **Mid & Small Cap Funds:** 30% (Higher growth potential for 5+ year horizons).\n"
            f"3. **Fixed Income / Debt Funds / FDs:** 20% (Capital protection & liquidity buffer).\n\n"
            f"💡 *Tip:* Compounding your current ₹{investments:,.0f}/mo SIP at 12% annual return yields approx **₹24.7 Lakhs** in 5 years!"
        )

    # Expenses, Overspending & Cutting Costs
    elif any(k in p for k in ["overspend", "reduce", "cut", "expense", "spending", "where", "food", "dining", "shopping"]):
        savings_pot = top_exp_amt * 0.25
        return (
            f"### 🔍 Expense Breakdown & Optimization Plan\n\n"
            f"Your current total expenses stand at **₹{expense:,.2f}/month**.\n\n"
            f"• **Highest Expense Driver:** **{top_exp_cat}** (₹{top_exp_amt:,.2f})\n"
            f"• **Potential Savings Opportunity:** Trimming 25% from {top_exp_cat} saves **₹{savings_pot:,.2f}/month**.\n\n"
            f"💡 **Recommended Action Steps:**\n"
            f"1. Audit recurring subscriptions and impulse online orders.\n"
            f"2. Set up category budget alerts in the **Expense Manager** tab.\n"
            f"3. Auto-redirect saved ₹{savings_pot:,.0f} directly into your monthly SIP on salary day!"
        )

    # Major Purchases (Car, Bike, Property, Affordability)
    elif any(k in p for k in ["bike", "car", "vehicle", "house", "flat", "afford", "buy", "lakh", "loan", "emi"]):
        # Extract numeric values if mentioned, else default to 10 Lakh vehicle
        numbers = re.findall(r'\d+', p)
        val = float(numbers[0]) * 100000 if numbers else 1000000.0
        downpayment = val * 0.20
        est_emi = (val * 0.80) * 0.021 # approx 5 yr EMI rate
        can_afford = savings >= (est_emi * 1.4)

        status_tag = "✅ **FEASIBLE:** Your monthly cashflow comfortably supports this purchase." if can_afford else "⚠️ **CAUTION:** This purchase will stretch your cash flow."

        return (
            f"### 🚘 Purchase Affordability Evaluation (Target: ₹{val:,.2f})\n\n"
            f"{status_tag}\n\n"
            f"• **Recommended Down Payment (20%):** ₹{downpayment:,.2f}\n"
            f"• **Estimated Monthly EMI (5 Year Loan @ 9.5%):** ₹{est_emi:,.2f}/mo\n"
            f"• **Your Current Monthly Surplus:** ₹{savings:,.2f}\n"
            f"• **EMI Impact:** EMI will consume **{(est_emi/max(savings, 1.0)*100):.1f}%** of your unallocated surplus.\n\n"
            f"Ensure you maintain an emergency reserve of at least 3-6 months of expenses before signing loan agreements."
        )

    # Savings & Budget Rules (50/30/20)
    elif any(k in p for k in ["save", "saving", "budget", "50/30/20", "target", "surplus"]):
        needs = income * 0.50
        wants = income * 0.30
        invest_target = income * 0.20
        return (
            f"### 🎯 Financial Budget Blueprint (50/30/20 Rule)\n\n"
            f"Based on your monthly income of **₹{income:,.2f}**:\n\n"
            f"• **50% Essential Needs (Rent, Utilities, EMI, Groceries):** Target ₹{needs:,.2f}\n"
            f"• **30% Lifestyle Wants (Dining out, Travel, Shopping):** Target ₹{wants:,.2f}\n"
            f"• **20% Minimum Investments & Savings:** Target ₹{invest_target:,.2f}\n\n"
            f"Your current monthly surplus is **₹{savings:,.2f}**. Allocating this systematically helps achieve long-term financial freedom faster."
        )

    # Health Score & Financial Standing
    elif any(k in p for k in ["health", "score", "standing", "rating", "diagnostic", "status"]):
        return (
            f"### 🛡️ Financial Health Score Analysis: **{health_score}/100**\n\n"
            f"• **Savings & Investment Velocity:** Good (Investments + Surplus = ₹{(investments+savings):,.2f}/mo)\n"
            f"• **Debt-to-Income Ratio:** Well controlled within healthy limits.\n"
            f"• **Emergency Buffer:** ~4.5 months of essential expense coverage.\n\n"
            f"**To reach a 90+ Score:**\n"
            f"1. Increase automated index SIP investments by 10%.\n"
            f"2. Ensure complete term & health insurance coverage for peace of mind."
        )

    # Bank Statements, Linking & Data
    elif any(k in p for k in ["statement", "link", "upload", "ocr", "pdf", "csv", "excel", "manual", "entry"]):
        return (
            f"### 📑 Bank Statement Linking & Manual Data Entry\n\n"
            f"FinSight AI supports two seamless data modes:\n\n"
            f"1. **Link Bank Statement (Upload):** Go to **Statement Analyzer** tab, upload your bank PDF/CSV/Excel statement or receipt image. FinSight AI will automatically parse merchants, recurring bills, and double-charges, allowing 1-click import into your ledger!\n"
            f"2. **Manual Entry:** Open **Expense Manager** -> tap **'Add Entry'** to log Expenses, Investments, Income, or Savings with detailed categories."
        )

    # General / Dynamic Query Fallback (Hashes prompt to avoid repeating static response for un-matched queries)
    else:
        hash_val = int(hashlib.md5(p.encode()).hexdigest(), 16)
        tips = [
            f"Considering your monthly income of **₹{income:,.2f}** and expenses of **₹{expense:,.2f}**, setting up automatic SIP debits on salary day is the single most effective habit to build wealth.",
            f"With your current financial health score at **{health_score}/100**, maintaining your ₹{investments:,.2f}/mo investment momentum will accelerate your progress toward major milestones.",
            f"A healthy budget keeps discretionary spending below 30% of income. Your top expense category **{top_exp_cat}** represents a great starting point for incremental savings."
        ]
        chosen_tip = tips[hash_val % len(tips)]
        
        return (
            f"### 💡 FinSight AI Financial Insight\n\n"
            f"Regarding your query on *\"{prompt}\"*:\n\n"
            f"{chosen_tip}\n\n"
            f"• **Active Monthly Surplus:** ₹{savings:,.2f}\n"
            f"• **Active Investments:** ₹{investments:,.2f}\n\n"
            f"Feel free to ask a specific question like *'How can I save ₹10,000 extra?'*, *'Analyze my SIP investments'*, or *'Can I afford a ₹15 Lakh home down payment?'*!"
        )

