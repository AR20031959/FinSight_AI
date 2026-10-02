import os
import sys
import datetime
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

# Setup backend directory in sys.path FIRST
backend_dir = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "backend"))
if backend_dir in sys.path:
    sys.path.remove(backend_dir)
sys.path.insert(0, backend_dir)

# pyrefly: ignore [missing-import]
from app.database import SessionLocal, engine, Base
# pyrefly: ignore [missing-import]
from app.models import User, Transaction, InvestmentGoal, BusinessMetric, RecurringBill
# pyrefly: ignore [missing-import]
from app.services.health_engine import calculate_health_score
# pyrefly: ignore [missing-import]
from app.services.forecast_engine import generate_cash_flow_forecast
# pyrefly: ignore [missing-import]
from app.services.ai_engine import ask_gemini_financial_advisor
# pyrefly: ignore [missing-import]
from app.services.finance_engine import calculate_dashboard_summary

def query_financial_advisor(db_session, user_id: int, user_prompt: str) -> str:
    context = calculate_dashboard_summary(db_session, user_id)
    res = ask_gemini_financial_advisor(user_prompt, context)
    return res.get("reply", "")

# Page Configuration
st.set_page_config(
    page_title="FinSight AI - Financial Decision Intelligence Platform",
    page_icon="⚡",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom Styling
st.markdown("""
<style>
    .main {
        background-color: #0f172a;
        color: #f8fafc;
    }
    .stMetric {
        background: linear-gradient(135deg, rgba(30, 41, 59, 0.7) 0%, rgba(15, 23, 42, 0.8) 100%);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 12px;
        padding: 16px;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }
    .stMetricLabel {
        color: #94a3b8 !important;
        font-size: 0.9rem !important;
        font-weight: 600 !important;
    }
    .stMetricValue {
        color: #38bdf8 !important;
        font-size: 1.8rem !important;
        font-weight: 700 !important;
    }
    .badge-income {
        background-color: rgba(34, 197, 94, 0.2);
        color: #4ade80;
        padding: 4px 10px;
        border-radius: 6px;
        font-weight: 600;
    }
    .badge-expense {
        background-color: rgba(239, 68, 68, 0.2);
        color: #f87171;
        padding: 4px 10px;
        border-radius: 6px;
        font-weight: 600;
    }
    .css-1d371kg {
        background-color: #1e293b;
    }
    div[data-testid="stSidebarHeader"] {
        padding-top: 1rem;
    }
</style>
""", unsafe_allow_html=True)

# Database Helper
def get_db_session():
    return SessionLocal()

# Sidebar Setup
st.sidebar.image("https://img.icons8.com/isometric/96/financial-growth-analysis.png", width=70)
st.sidebar.title("FinSight AI")
st.sidebar.caption("Understand Your Money. Predict Your Future.")

st.sidebar.markdown("---")

menu = st.sidebar.radio(
    "Navigation Modules",
    [
        "📊 Dashboard Overview",
        "💸 Expense Tracker",
        "📑 Statement Analyzer & OCR",
        "🤖 AI Financial Advisor",
        "🎯 Investment Planner",
        "📈 Business Analytics",
        "🔮 Cash Flow Forecast",
        "💚 Financial Health Score",
        "📄 Reports & Export"
    ],
    key="main_nav_sidebar_radio"
)

st.sidebar.markdown("---")
st.sidebar.info("💡 **Demo User:** demo@finsight.ai\n🔒 Encrypted 256-bit Connection")

db = get_db_session()
demo_user = db.query(User).filter(User.email == "demo@finsight.ai").first()
user_id = demo_user.id if demo_user else 1

# ==========================================
# 1. DASHBOARD OVERVIEW
# ==========================================
if menu == "📊 Dashboard Overview":
    st.title("📊 Financial Decision Intelligence Dashboard")
    st.write(f"Welcome back, **{demo_user.full_name if demo_user else 'User'}**! Here is your real-time financial summary.")

    txs = db.query(Transaction).filter(Transaction.user_id == user_id).all()
    
    total_income = sum(t.amount for t in txs if t.type == "income")
    total_expenses = sum(t.amount for t in txs if t.type == "expense")
    net_savings = total_income - total_expenses
    savings_rate = round((net_savings / total_income * 100), 1) if total_income > 0 else 0.0

    health_data = calculate_health_score(db, user_id)
    health_score = health_data["overall_score"]

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Total Monthly Income", f"₹{total_income:,.2f}", "+12% vs last mo")
    col2.metric("Total Monthly Expenses", f"₹{total_expenses:,.2f}", "-4% vs target")
    col3.metric("Net Monthly Savings", f"₹{net_savings:,.2f}", f"{savings_rate}% Savings Rate")
    col4.metric("Financial Health Index", f"{health_score} / 100", "Strong Buffer")

    st.markdown("---")

    col_chart1, col_chart2 = st.columns([3, 2])

    with col_chart1:
        st.subheader("Monthly Income vs Expense Trend")
        df_txs = pd.DataFrame([
            {"Date": t.date, "Amount": t.amount, "Type": t.type.capitalize(), "Category": t.category}
            for t in txs
        ])
        if not df_txs.empty:
            fig_bar = px.bar(
                df_txs, x="Date", y="Amount", color="Type",
                barmode="group",
                color_discrete_map={"Income": "#22c55e", "Expense": "#ef4444"},
                title="Transactions Ledger Breakdown"
            )
            fig_bar.update_layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1")
            st.plotly_chart(fig_bar, use_container_width=True)
        else:
            st.info("No transaction data available yet.")

    with col_chart2:
        st.subheader("Expense Categories")
        exp_txs = [t for t in txs if t.type == "expense"]
        if exp_txs:
            df_exp = pd.DataFrame([{"Category": t.category, "Amount": t.amount} for t in exp_txs])
            cat_grouped = df_exp.groupby("Category").sum().reset_index()
            fig_pie = px.pie(
                cat_grouped, values="Amount", names="Category",
                hole=0.4,
                title="Expense Distribution"
            )
            fig_pie.update_layout(paper_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1")
            st.plotly_chart(fig_pie, use_container_width=True)
        else:
            st.info("No expenses recorded yet.")

    st.subheader("Recent Transactions")
    if txs:
        df_display = pd.DataFrame([
            {
                "Title": t.title,
                "Merchant": t.merchant or "N/A",
                "Category": t.category,
                "Type": t.type.upper(),
                "Amount (₹)": f"₹{t.amount:,.2f}",
                "Date": t.date,
                "Recurring": "Yes" if t.is_recurring else "No"
            }
            for t in reversed(txs[-8:])
        ])
        st.dataframe(df_display, use_container_width=True)

# ==========================================
# 2. EXPENSE TRACKER
# ==========================================
elif menu == "💸 Expense Tracker":
    st.title("💸 Expense & Income Manager")
    
    tab1, tab2 = st.tabs(["📋 View & Filter Transactions", "➕ Add New Transaction"])

    with tab1:
        st.subheader("Transaction History")
        txs = db.query(Transaction).filter(Transaction.user_id == user_id).all()
        if txs:
            df = pd.DataFrame([
                {
                    "ID": t.id,
                    "Title": t.title,
                    "Amount": t.amount,
                    "Type": t.type,
                    "Category": t.category,
                    "Merchant": t.merchant or "-",
                    "Date": t.date,
                    "Note": t.note or "-",
                    "Is Recurring": t.is_recurring
                }
                for t in txs
            ])

            col_f1, col_f2 = st.columns(2)
            with col_f1:
                filter_type = st.multiselect("Filter by Type", options=["income", "expense"], default=["income", "expense"], key="exp_tracker_filter_type")
            with col_f2:
                categories = list(df["Category"].unique())
                filter_cat = st.multiselect("Filter by Category", options=categories, default=categories, key="exp_tracker_filter_cat")

            filtered_df = df[(df["Type"].isin(filter_type)) & (df["Category"].isin(filter_cat))]
            st.dataframe(filtered_df, use_container_width=True)
        else:
            st.info("No transactions registered.")

    with tab2:
        st.subheader("Record New Entry")
        with st.form("new_tx_form"):
            col_a, col_b = st.columns(2)
            with col_a:
                title = st.text_input("Title / Description", placeholder="e.g. Salary, Grocery, Internet", key="form_tx_title")
                amount = st.number_input("Amount (₹)", min_value=1.0, value=1000.0, step=100.0, key="form_tx_amount")
                tx_type = st.selectbox("Type", ["expense", "income", "investment", "savings"], key="form_tx_type")
            with col_b:
                category = st.selectbox("Category", [
                    "Food", "Travel", "Shopping", "EMI", "Entertainment", 
                    "Investments", "Utilities", "Medical", "Salary", "Business"
                ], key="form_tx_category")
                merchant = st.text_input("Merchant / Source", placeholder="e.g. Swiggy, Amazon, HDFC", key="form_tx_merchant")
                tx_date = st.date_input("Date", value=datetime.date.today(), key="form_tx_date")
            
            note = st.text_area("Notes", placeholder="Optional details...", key="form_tx_note")
            is_recurring = st.checkbox("Mark as Recurring Bill / Subscription", key="form_tx_recurring")

            submitted = st.form_submit_button("Save Transaction")
            if submitted:
                new_t = Transaction(
                    user_id=user_id,
                    title=title,
                    amount=float(amount),
                    type=tx_type,
                    category=category,
                    date=str(tx_date),
                    merchant=merchant,
                    note=note,
                    is_recurring=is_recurring
                )
                db.add(new_t)
                db.commit()
                st.success(f"Successfully recorded transaction: '{title}' (₹{amount:,.2f})")
                st.rerun()

# ==========================================
# 3. STATEMENT ANALYZER & OCR
# ==========================================
elif menu == "📑 Statement Analyzer & OCR":
    st.title("📑 Smart Statement Analyzer & Intelligent OCR")
    st.write("Upload bank statements (PDF/CSV/XLSX) or receipt images to parse transactions, extract text, and flag anomalies.")

    uploaded_file = st.file_uploader("Upload Bank Statement or Receipt", type=["pdf", "csv", "xlsx", "png", "jpg", "jpeg"], key="ocr_statement_file_uploader")
    
    if uploaded_file is not None:
        st.success(f"Uploaded `{uploaded_file.name}` successfully!")
        
        st.subheader("Processing Highlights")
        col_s1, col_s2, col_s3 = st.columns(3)
        col_s1.metric("Extracted Entries", "14 Items", "+100% confidence")
        col_s2.metric("Detected Subscriptions", "3 Found", "Netflix, Spotify, Airtel")
        col_s3.metric("Duplicate Charges Alert", "0 Detected", "Clean Ledger")

        st.markdown("### Parsed Output Preview")
        mock_parsed = pd.DataFrame([
            {"Date": "2026-07-25", "Description": "STARBUCKS COFFEE", "Amount": "₹450.00", "Category": "Food", "Confidence": "98%"},
            {"Date": "2026-07-26", "Description": "AIRTEL FIBER AUTOPAY", "Amount": "₹1,179.00", "Category": "Utilities", "Confidence": "99%"},
            {"Date": "2026-07-28", "Description": "AMAZON RETAIL INDIA", "Amount": "₹2,499.00", "Category": "Shopping", "Confidence": "96%"},
        ])
        st.table(mock_parsed)

        if st.button("Import Parsed Transactions to Ledger", key="import_parsed_tx_btn"):
            st.success("14 extracted transactions added to your expense manager!")

# ==========================================
# 4. AI FINANCIAL ADVISOR
# ==========================================
elif menu == "🤖 AI Financial Advisor":
    st.title("🤖 FinSight Conversational AI Advisor")
    st.write("Powered by Google Gemini. Ask any query about budgeting, investment advice, tax planning, or expense optimization.")

    if "messages" not in st.session_state:
        st.session_state.messages = [
            {"role": "assistant", "content": "Hello Alex! I am your FinSight AI Advisor. How can I help optimize your finances today?"}
        ]

    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"])

    if user_prompt := st.chat_input("Ask a question (e.g., 'How can I save ₹20,000 extra this month?')...", key="ai_advisor_chat_input"):
        st.session_state.messages.append({"role": "user", "content": user_prompt})
        with st.chat_message("user"):
            st.markdown(user_prompt)

        with st.chat_message("assistant"):
            with st.spinner("Analyzing financial context..."):
                response_text = query_financial_advisor(db, user_id, user_prompt)
                st.markdown(response_text)
                st.session_state.messages.append({"role": "assistant", "content": response_text})

# ==========================================
# 5. INVESTMENT PLANNER
# ==========================================
elif menu == "🎯 Investment Planner":
    st.title("🎯 Goal-Based Investment Planner & SIP Calculator")

    st.subheader("SIP & Wealth Growth Calculator")
    
    col_i1, col_i2, col_i3 = st.columns(3)
    with col_i1:
        monthly_sip = st.slider("Monthly SIP Investment (₹)", 1000, 100000, 20000, 1000, key="inv_monthly_sip_slider")
    with col_i2:
        expected_rate = st.slider("Expected Annual Return (%)", 5.0, 25.0, 12.0, 0.5, key="inv_expected_rate_slider")
    with col_i3:
        years = st.slider("Investment Duration (Years)", 1, 30, 10, 1, key="inv_years_slider")

    # Calculation logic
    i = expected_rate / 12 / 100
    n = years * 12
    invested = monthly_sip * n
    total_wealth = monthly_sip * (((1 + i)**n - 1) / i) * (1 + i)
    est_returns = total_wealth - invested

    col_m1, col_m2, col_m3 = st.columns(3)
    col_m1.metric("Total Amount Invested", f"₹{invested:,.0f}")
    col_m2.metric("Estimated Returns", f"₹{est_returns:,.0f}")
    col_m3.metric("Target Wealth Created", f"₹{total_wealth:,.0f}", f"+{(est_returns/invested)*100:.1f}% Growth")

    # SIP Growth Chart
    months_arr = list(range(1, n + 1))
    growth_data = []
    for m in months_arr:
        inv = monthly_sip * m
        w = monthly_sip * (((1 + i)**m - 1) / i) * (1 + i)
        growth_data.append({"Month": m, "Invested Amount": inv, "Wealth Value": w})
    
    df_growth = pd.DataFrame(growth_data)
    fig_sip = px.line(df_growth, x="Month", y=["Invested Amount", "Wealth Value"], title="SIP Growth Projection")
    fig_sip.update_layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1")
    st.plotly_chart(fig_sip, use_container_width=True)

    st.markdown("---")
    st.subheader("Current Financial Goals")
    goals = db.query(InvestmentGoal).filter(InvestmentGoal.user_id == user_id).all()
    for g in goals:
        pct = min(100.0, (g.current_amount / g.target_amount) * 100)
        st.write(f"**{g.name}** ({g.risk_level} Risk) — Target: ₹{g.target_amount:,.0f} in {g.target_years} yrs")
        st.progress(pct / 100.0, text=f"Saved ₹{g.current_amount:,.0f} ({pct:.1f}%) | Monthly SIP: ₹{g.monthly_sip:,.0f}")

# ==========================================
# 6. BUSINESS ANALYTICS
# ==========================================
elif menu == "📈 Business Analytics":
    st.title("📈 Business Decision Intelligence")

    col_b1, col_b2, col_b3, col_b4 = st.columns(4)
    col_b1.metric("Monthly Revenue", "₹4,85,000", "+18.4% vs Q1")
    col_b2.metric("Net Profit Margin", "34.2%", "+3.1% YoY")
    col_b3.metric("Customer Acq. Cost (CAC)", "₹1,450", "-12% Efficiency")
    col_b4.metric("LTV / CAC Ratio", "4.8x", "Healthy (>3x)")

    st.subheader("Quarterly Financial Performance")
    mock_biz = pd.DataFrame([
        {"Quarter": "2025-Q3", "Revenue": 380000, "Expenses": 260000, "Profit": 120000},
        {"Quarter": "2025-Q4", "Revenue": 420000, "Expenses": 280000, "Profit": 140000},
        {"Quarter": "2026-Q1", "Revenue": 450000, "Expenses": 295000, "Profit": 155000},
        {"Quarter": "2026-Q2", "Revenue": 485000, "Expenses": 319000, "Profit": 166000},
    ])

    fig_biz = px.bar(mock_biz, x="Quarter", y=["Revenue", "Expenses", "Profit"], barmode="group", title="Revenue vs Expenses vs Profit")
    fig_biz.update_layout(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1")
    st.plotly_chart(fig_biz, use_container_width=True)

# ==========================================
# 7. CASH FLOW FORECAST
# ==========================================
elif menu == "🔮 Cash Flow Forecast":
    st.title("🔮 Predictive ML Cash Flow Forecast")
    st.write("Machine learning predictive engine with 95% confidence intervals and multi-scenario simulations.")

    timeframe = st.selectbox("Forecast Horizon", ["1 Month", "3 Months", "6 Months", "12 Months"], index=2, key="forecast_horizon_selectbox")
    scenario = st.radio("Simulation Scenario", ["Realistic", "Pessimistic", "Optimistic"], horizontal=True, key="forecast_scenario_radio")

    forecast_res = generate_cash_flow_forecast(timeframe)
    points = forecast_res["scenarios"][scenario]

    df_fc = pd.DataFrame(points)
    
    fig_fc = go.Figure()

    # Upper and Lower Bounds
    fig_fc.add_trace(go.Scatter(
        x=df_fc["period"], y=df_fc["upper_bound"],
        mode='lines', line=dict(width=0), showlegend=False
    ))
    fig_fc.add_trace(go.Scatter(
        x=df_fc["period"], y=df_fc["lower_bound"],
        mode='lines', line=dict(width=0), fill='tonexty',
        fillcolor='rgba(56, 189, 248, 0.2)', name='95% Confidence Interval'
    ))
    fig_fc.add_trace(go.Scatter(
        x=df_fc["period"], y=df_fc["predicted_balance"],
        mode='lines+markers', line=dict(color='#38bdf8', width=3),
        name=f'{scenario} Predicted Balance'
    ))

    fig_fc.update_layout(
        title=f"Projected Account Balance ({scenario} Scenario - {timeframe})",
        paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1"
    )

    st.plotly_chart(fig_fc, use_container_width=True)
    st.dataframe(df_fc, use_container_width=True)

# ==========================================
# 8. FINANCIAL HEALTH SCORE
# ==========================================
elif menu == "💚 Financial Health Score":
    st.title("💚 Comprehensive Financial Health Diagnostic")

    health_data = calculate_health_score(db, user_id)
    score = health_data["overall_score"]

    fig_gauge = go.Figure(go.Indicator(
        mode="gauge+number",
        value=score,
        domain={'x': [0, 1], 'y': [0, 1]},
        title={'text': "FinSight Health Score", 'font': {'size': 24, 'color': "#cbd5e1"}},
        gauge={
            'axis': {'range': [None, 100], 'tickwidth': 1, 'tickcolor': "#cbd5e1"},
            'bar': {'color': "#38bdf8"},
            'bgcolor': "rgba(30, 41, 59, 0.8)",
            'steps': [
                {'range': [0, 50], 'color': 'rgba(239, 68, 68, 0.4)'},
                {'range': [50, 75], 'color': 'rgba(234, 179, 8, 0.4)'},
                {'range': [75, 100], 'color': 'rgba(34, 197, 94, 0.4)'}
            ]
        }
    ))
    fig_gauge.update_layout(paper_bgcolor="rgba(0,0,0,0)", font_color="#cbd5e1")
    st.plotly_chart(fig_gauge, use_container_width=True)

    col_h1, col_h2, col_h3, col_h4 = st.columns(4)
    col_h1.metric("Savings Ratio", f"{health_data['savings_ratio']}%", "Target: ≥30%")
    col_h2.metric("Debt Ratio", f"{health_data['debt_ratio']}%", "Target: ≤30%")
    col_h3.metric("Investment Ratio", f"{health_data['investment_ratio']}%", "Target: ≥20%")
    col_h4.metric("Emergency Runway", f"{health_data['emergency_fund_coverage_months']} mos", "Target: ≥6 mos")

    st.subheader("💡 Actionable Recommendations")
    for sug in health_data["suggestions"]:
        st.info(f"👉 {sug}")

# ==========================================
# 9. REPORTS & EXPORT
# ==========================================
elif menu == "📄 Reports & Export":
    st.title("📄 Executive Report Generator")
    st.write("Generate and export full PDF summaries or Excel transaction ledgers.")

    rep_type = st.selectbox("Select Report Type", [
        "Monthly Executive Summary (PDF)",
        "Detailed Transaction Ledger (Excel)",
        "Tax Deductions & Audit Statement (PDF)"
    ], key="report_type_selectbox")

    if st.button("Generate & Download Report", key="generate_download_report_btn"):
        st.success(f"Generated `{rep_type}` successfully!")
        st.download_button(
            label="Click Here to Download Document",
            data=b"FinSight AI Financial Report Content",
            file_name=f"FinSight_Report_{datetime.date.today()}.pdf",
            mime="application/pdf",
            key="download_doc_btn"
        )

db.close()
