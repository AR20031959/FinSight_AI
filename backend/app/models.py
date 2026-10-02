import datetime
# pyrefly: ignore [missing-import]
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean, Text
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import relationship
from app.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(String, default="user", nullable=False)  # 'user' or 'enterprise'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    is_active = Column(Boolean, default=True)

    transactions = relationship("Transaction", back_populates="owner")
    investment_goals = relationship("InvestmentGoal", back_populates="owner")
    business_metrics = relationship("BusinessMetric", back_populates="owner")
    recurring_bills = relationship("RecurringBill", back_populates="owner")
    enterprise_memberships = relationship("EnterpriseMember", back_populates="user")
    audit_logs = relationship("AuditLog", back_populates="user")

class Enterprise(Base):
    __tablename__ = "enterprises"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    tax_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    members = relationship("EnterpriseMember", back_populates="enterprise")

class EnterpriseMember(Base):
    __tablename__ = "enterprise_members"

    id = Column(Integer, primary_key=True, index=True)
    enterprise_id = Column(Integer, ForeignKey("enterprises.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    member_role = Column(String, default="member")  # 'admin', 'manager', 'member'
    status = Column(String, default="active")  # 'active', 'pending', 'suspended'
    joined_at = Column(DateTime, default=datetime.datetime.utcnow)

    enterprise = relationship("Enterprise", back_populates="members")
    user = relationship("User", back_populates="enterprise_memberships")

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String, nullable=False)  # e.g., 'LOGIN', 'FAILED_LOGIN', 'GENERATE_REPORT', 'UPDATE_TX'
    resource = Column(String, nullable=True)
    ip_address = Column(String, nullable=True)
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="audit_logs")

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    type = Column(String, nullable=False)  # 'income', 'expense', 'investment', 'savings'
    category = Column(String, nullable=False)
    date = Column(String, nullable=False)  # YYYY-MM-DD
    merchant = Column(String, nullable=True)
    note = Column(Text, nullable=True)
    is_recurring = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="transactions")

class InvestmentGoal(Base):
    __tablename__ = "investment_goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String, nullable=False)
    target_amount = Column(Float, nullable=False)
    current_amount = Column(Float, default=0.0)
    target_years = Column(Integer, nullable=False)
    risk_level = Column(String, default="Moderate")
    monthly_sip = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="investment_goals")

class BusinessMetric(Base):
    __tablename__ = "business_metrics"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    period = Column(String, nullable=False)
    period_type = Column(String, nullable=False)
    revenue = Column(Float, nullable=False)
    profit = Column(Float, nullable=False)
    expenses = Column(Float, nullable=False)
    kpi_growth_rate = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    owner = relationship("User", back_populates="business_metrics")

class RecurringBill(Base):
    __tablename__ = "recurring_bills"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    biller_name = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    due_date = Column(String, nullable=False)
    category = Column(String, nullable=False)
    is_paid = Column(Boolean, default=False)

    owner = relationship("User", back_populates="recurring_bills")
