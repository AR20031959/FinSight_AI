import pytest
import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models import User, Transaction
from app.services.finance_engine import add_transaction, get_monthly_financial_summary, get_user_transactions
from app.services.ai_engine import ask_gemini_financial_advisor
from app.services.report_engine import generate_pdf_report, generate_excel_report, generate_image_report
from app.schemas import TransactionCreate

# Setup in-memory SQLite test database
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db_session():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    
    # Create test user
    user = User(email="test@finsight.ai", full_name="Test User", hashed_password="hashed_pw")
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Seed real database records across specific dates
    txs = [
        TransactionCreate(title="Salary Credit", amount=100000.0, type="income", category="Salary", date="2026-10-01"),
        TransactionCreate(title="Apartment Rent", amount=30000.0, type="expense", category="Rent & Housing", date="2026-10-02", is_recurring=True),
        TransactionCreate(title="Grocery Shopping", amount=5000.0, type="expense", category="Food & Dining", date="2026-10-05"),
        TransactionCreate(title="SIP Index Fund", amount=20000.0, type="investment", category="Mutual Funds / SIP", date="2026-10-10", is_recurring=True),
        TransactionCreate(title="September Salary", amount=100000.0, type="income", category="Salary", date="2026-09-01"),
        TransactionCreate(title="September Rent", amount=30000.0, type="expense", category="Rent & Housing", date="2026-09-02", is_recurring=True),
    ]
    for tx in txs:
        add_transaction(db, user.id, tx)

    yield db
    
    db.close()
    Base.metadata.drop_all(bind=engine)

def test_monthly_financial_summary_calculations(db_session):
    # Test summary for October 2026
    summary = get_monthly_financial_summary(db_session, user_id=1, year=2026, month=10)
    
    assert summary["monthly_income"] == 100000.0
    assert summary["monthly_expense"] == 35000.0
    assert summary["total_investments"] == 20000.0
    assert summary["savings"] == 45000.0
    assert summary["savings_rate"] == 45.0
    assert summary["transaction_count"] == 4
    assert summary["category_breakdown"]["Rent & Housing"] == 30000.0
    assert summary["category_breakdown"]["Food & Dining"] == 5000.0
    assert summary["largest_expense"]["amount"] == 30000.0

def test_date_filtering_strict_bounds(db_session):
    # Test strict range Oct 1 to Oct 3
    txs_filtered = get_user_transactions(db_session, user_id=1, start_date="2026-10-01", end_date="2026-10-03")
    assert len(txs_filtered) == 2
    dates = [t.date for t in txs_filtered]
    assert "2026-10-01" in dates
    assert "2026-10-02" in dates

    # Test empty range (e.g. 2026-10-20 to 2026-10-25)
    empty_txs = get_user_transactions(db_session, user_id=1, start_date="2026-10-20", end_date="2026-10-25")
    assert len(empty_txs) == 0

def test_ai_context_generation_and_anti_hallucination(db_session):
    summary = get_monthly_financial_summary(db_session, user_id=1, year=2026, month=10)
    res = ask_gemini_financial_advisor("What were my expenses in October 2026?", summary)
    
    assert "query" in res
    assert "reply" in res
    assert res["context_used"]["monthly_income"] == 100000.0
    assert res["context_used"]["monthly_expense"] == 35000.0
    assert res["context_used"]["total_investments"] == 20000.0

def test_report_generation(db_session):
    txs = get_user_transactions(db_session, user_id=1, start_date="2026-10-01", end_date="2026-10-31")
    tx_dicts = [
        {"id": t.id, "date": t.date, "title": t.title, "category": t.category, "type": t.type, "amount": t.amount, "merchant": t.merchant}
        for t in txs
    ]
    summary = get_monthly_financial_summary(db_session, user_id=1, start_date="2026-10-01", end_date="2026-10-31")
    
    pdf_bytes = generate_pdf_report("Test User", tx_dicts, summary, "2026-10-01", "2026-10-31")
    assert pdf_bytes and len(pdf_bytes) > 100
    assert pdf_bytes[:4] == b"%PDF"

    excel_bytes = generate_excel_report("Test User", tx_dicts, summary, "2026-10-01", "2026-10-31")
    assert excel_bytes and len(excel_bytes) > 100

    img_bytes = generate_image_report("Test User", tx_dicts, summary, "2026-10-01", "2026-10-31")
    assert img_bytes and len(img_bytes) > 100

def test_filename_generation_single_extension():
    s_str = "2026-10-01"
    e_str = "2026-10-31"
    ext = "png"
    
    clean_ext = ext.replaceAll('.', '') if hasattr(ext, 'replaceAll') else ext.replace('.', '')
    filename = f"FinSight_Report_{s_str}_to_{e_str}.{clean_ext}"
    
    assert filename.count(".png") == 1
    assert filename == "FinSight_Report_2026-10-01_to_2026-10-31.png"
    assert not filename.endswith(".png.png")
