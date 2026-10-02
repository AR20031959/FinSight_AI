import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base, get_db
from app.main import app
from app.models import User, Transaction, Enterprise, EnterpriseMember, AuditLog
from app.auth import get_password_hash, create_access_token

TEST_DB_FILE = "./test_security.db"
SQLALCHEMY_DATABASE_URL = f"sqlite:///{TEST_DB_FILE}"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="module")
def db_setup():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    
    # User A (Regular User)
    user_a = User(email="usera@finsight.ai", full_name="User A", role="user", hashed_password=get_password_hash("passA"))
    # User B (Regular User)
    user_b = User(email="userb@finsight.ai", full_name="User B", role="user", hashed_password=get_password_hash("passB"))
    # Enterprise Admin A
    ent_admin_a = User(email="admin_a@corp.com", full_name="Enterprise Admin A", role="enterprise", hashed_password=get_password_hash("passEntA"))
    # Enterprise Admin B
    ent_admin_b = User(email="admin_b@corp.com", full_name="Enterprise Admin B", role="enterprise", hashed_password=get_password_hash("passEntB"))

    db.add_all([user_a, user_b, ent_admin_a, ent_admin_b])
    db.commit()

    # User A transactions
    tx_a = Transaction(user_id=user_a.id, title="User A Income", amount=50000.0, type="income", category="Salary", date="2026-10-01")
    # User B transactions
    tx_b = Transaction(user_id=user_b.id, title="User B Secret Expense", amount=9999.0, type="expense", category="Secret", date="2026-10-02")
    db.add_all([tx_a, tx_b])
    db.commit()

    yield db
    
    db.close()
    Base.metadata.drop_all(bind=engine)
    if os.path.exists(TEST_DB_FILE):
        try:
            os.remove(TEST_DB_FILE)
        except Exception:
            pass

@pytest.fixture
def client(db_setup):
    def _override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()
            
    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()

def test_unauthenticated_requests_rejected(client):
    # PDF report without token
    res = client.get("/api/reports/pdf")
    assert res.status_code == 401

    # Transactions list without token
    res = client.get("/api/transactions/")
    assert res.status_code == 401

    # AI chat without token
    res = client.post("/api/ai/chat", json={"prompt": "Hello"})
    assert res.status_code == 401

def test_invalid_or_expired_tokens_rejected(client):
    headers = {"Authorization": "Bearer invalid.jwt.token"}
    res = client.get("/api/transactions/", headers=headers)
    assert res.status_code == 401

def test_user_data_isolation(client):
    token_a = create_access_token({"sub": "usera@finsight.ai", "role": "user"})
    token_b = create_access_token({"sub": "userb@finsight.ai", "role": "user"})

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A listing transactions only sees User A's data
    res_a = client.get("/api/transactions/", headers=headers_a)
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert len(data_a) == 1
    assert data_a[0]["title"] == "User A Income"

    # User B listing transactions only sees User B's data
    res_b = client.get("/api/transactions/", headers=headers_b)
    assert res_b.status_code == 200
    data_b = res_b.json()
    assert len(data_b) == 1
    assert data_b[0]["title"] == "User B Secret Expense"

def test_rbac_user_cannot_access_enterprise_dashboard(client):
    token_user = create_access_token({"sub": "usera@finsight.ai", "role": "user"})
    headers = {"Authorization": f"Bearer {token_user}"}

    res = client.get("/api/enterprise/dashboard", headers=headers)
    assert res.status_code == 403
    assert "Access forbidden" in res.json()["detail"]

def test_enterprise_role_can_access_enterprise_dashboard(client):
    token_ent = create_access_token({"sub": "admin_a@corp.com", "role": "enterprise"})
    headers = {"Authorization": f"Bearer {token_ent}"}

    res = client.get("/api/enterprise/dashboard", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "enterprise_id" in data
    assert data["privacy_compliance_notice"].startswith("Privacy Mode Active")

def test_gemini_api_key_not_exposed_to_client(client):
    token_user = create_access_token({"sub": "usera@finsight.ai", "role": "user"})
    headers = {"Authorization": f"Bearer {token_user}"}

    res = client.post("/api/ai/chat", json={"prompt": "How to save money?"}, headers=headers)
    assert res.status_code == 200
    res_text = res.text.lower()
    assert "gemini_api_key" not in res_text
    assert "secret_key" not in res_text

def test_audit_logs_recorded(client):
    token_user = create_access_token({"sub": "usera@finsight.ai", "role": "user"})
    headers = {"Authorization": f"Bearer {token_user}"}

    client.get("/api/reports/pdf?start_date=2026-10-01&end_date=2026-10-02", headers=headers)

    db = TestingSessionLocal()
    logs = db.query(AuditLog).filter(AuditLog.action == "GENERATE_REPORT_PDF").all()
    assert len(logs) >= 1
    assert logs[0].resource == "pdf"
    db.close()
