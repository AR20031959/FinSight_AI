import sys
import os

# Add backend directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine, Base
from app.models import User, Transaction, InvestmentGoal, BusinessMetric, RecurringBill
from app.auth import get_password_hash

def seed():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Check if demo user exists
    user = db.query(User).filter(User.email == "demo@finsight.ai").first()
    if not user:
        user = User(
            email="demo@finsight.ai",
            full_name="Alex Morgan",
            hashed_password=get_password_hash("demo123")
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"Created demo user: {user.email}")

    # Seed Transactions if empty
    if db.query(Transaction).filter(Transaction.user_id == user.id).count() == 0:
        sample_txs = [
            Transaction(user_id=user.id, title="Tech Corp Salary Credit", amount=150000.0, type="income", category="Salary", date="2026-07-01", merchant="Tech Corp Inc", note="Monthly Salary"),
            Transaction(user_id=user.id, title="Freelance Consulting Income", amount=35000.0, type="income", category="Business", date="2026-07-15", merchant="Client Direct", note="Project Milestone"),
            Transaction(user_id=user.id, title="Apartment Rent Payment", amount=32000.0, type="expense", category="EMI", date="2026-07-03", merchant="Landlord Direct", is_recurring=True),
            Transaction(user_id=user.id, title="D-Mart Monthly Grocery Shopping", amount=8450.0, type="expense", category="Food", date="2026-07-05", merchant="D-Mart", note="Household provisions"),
            Transaction(user_id=user.id, title="HDFC Car Loan EMI", amount=14200.0, type="expense", category="EMI", date="2026-07-07", merchant="HDFC Bank", is_recurring=True),
            Transaction(user_id=user.id, title="Zerodha Nifty 50 Index SIP", amount=20000.0, type="expense", category="Investments", date="2026-07-10", merchant="Zerodha", is_recurring=True),
            Transaction(user_id=user.id, title="Swiggy Gourmet Dinner", amount=1850.0, type="expense", category="Food", date="2026-07-12", merchant="Swiggy"),
            Transaction(user_id=user.id, title="Uber Intercity Cab", amount=2450.0, type="expense", category="Travel", date="2026-07-14", merchant="Uber"),
            Transaction(user_id=user.id, title="Amazon Electronics Order", amount=6890.0, type="expense", category="Shopping", date="2026-07-16", merchant="Amazon India"),
            Transaction(user_id=user.id, title="PVR IMAX Movie & Snacks", amount=1600.0, type="expense", category="Entertainment", date="2026-07-18", merchant="PVR Cinemas"),
            Transaction(user_id=user.id, title="Apollo Medical Diagnostic Test", amount=3400.0, type="expense", category="Medical", date="2026-07-20", merchant="Apollo Diagnostics"),
            Transaction(user_id=user.id, title="Electricity & Water Utility Bill", amount=2850.0, type="expense", category="Utilities", date="2026-07-22", merchant="State Utility Board", is_recurring=True),
        ]
        db.add_all(sample_txs)
        db.commit()
        print("Seeded sample transactions")

    # Seed Investment Goals
    if db.query(InvestmentGoal).filter(InvestmentGoal.user_id == user.id).count() == 0:
        sample_goals = [
            InvestmentGoal(user_id=user.id, name="Luxury SUV / Vehicle Fund", target_amount=1200000.0, current_amount=450000.0, target_years=3, risk_level="Moderate", monthly_sip=18000.0),
            InvestmentGoal(user_id=user.id, name="Dream Home Down payment", target_amount=2500000.0, current_amount=890000.0, target_years=5, risk_level="Moderate", monthly_sip=25000.0),
            InvestmentGoal(user_id=user.id, name="Early Retirement Corpus", target_amount=10000000.0, current_amount=1650000.0, target_years=15, risk_level="High", monthly_sip=35000.0),
        ]
        db.add_all(sample_goals)
        db.commit()
        print("Seeded investment goals")

    # Seed Recurring Bills
    if db.query(RecurringBill).filter(RecurringBill.user_id == user.id).count() == 0:
        sample_bills = [
            RecurringBill(user_id=user.id, biller_name="Airtel Fiber Broadband", amount=1179.0, due_date="2026-08-10", category="Utilities", is_paid=False),
            RecurringBill(user_id=user.id, biller_name="Netflix Premium UHD", amount=649.0, due_date="2026-08-12", category="Entertainment", is_paid=False),
            RecurringBill(user_id=user.id, biller_name="HDFC Credit Card Bill", amount=18450.0, due_date="2026-08-15", category="EMI", is_paid=False),
            RecurringBill(user_id=user.id, biller_name="State Electricity Board", amount=3120.0, due_date="2026-08-18", category="Utilities", is_paid=False),
        ]
        db.add_all(sample_bills)
        db.commit()
        print("Seeded recurring bills")

    db.close()

if __name__ == "__main__":
    seed()
