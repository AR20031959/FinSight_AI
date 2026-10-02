# pyrefly: ignore [missing-import]
from pydantic import BaseModel, EmailStr
from typing import List, Optional, Dict, Any

# Auth Schemas
class UserCreate(BaseModel):
    email: EmailStr
    full_name: str
    password: str
    role: Optional[str] = "user"

class UserLogin(BaseModel):
    email: EmailStr
    password: str
    role: Optional[str] = "user"

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    full_name: str
    role: str = "user"
    is_active: bool

    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class EnterpriseDashboardResponse(BaseModel):
    enterprise_id: int
    enterprise_name: str
    total_members: int
    active_members: int
    aggregated_metrics: Dict[str, Any]
    usage_statistics: Dict[str, Any]
    privacy_compliance_notice: str

# Transaction Schemas
class TransactionCreate(BaseModel):
    title: str
    amount: float
    type: str  # 'income', 'expense', 'investment', 'savings'
    category: str
    date: str
    merchant: Optional[str] = None
    note: Optional[str] = None
    is_recurring: bool = False

class TransactionUpdate(BaseModel):
    title: Optional[str] = None
    amount: Optional[float] = None
    type: Optional[str] = None
    category: Optional[str] = None
    date: Optional[str] = None
    merchant: Optional[str] = None
    note: Optional[str] = None
    is_recurring: Optional[bool] = None

class TransactionResponse(TransactionCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# Dashboard Summary Schema
class DashboardSummaryResponse(BaseModel):
    period: str = "All Months"
    period_type: str = "monthly"
    available_years: List[int] = []
    total_balance: float
    monthly_income: float
    monthly_expense: float
    total_investments: float = 0.0
    savings: float
    savings_rate: float = 0.0
    health_score: float
    transaction_count: int = 0
    category_breakdown: Dict[str, float]
    investment_breakdown: Dict[str, float] = {}
    largest_expense: Optional[Dict[str, Any]] = None
    recurring_expenses: List[Dict[str, Any]] = []
    total_recurring_amount: float = 0.0
    month_over_month_changes: Dict[str, float] = {}
    monthly_trend: List[Dict[str, Any]]
    yearly_trend: List[Dict[str, Any]] = []
    recent_transactions: List[TransactionResponse]
    upcoming_bills: List[Dict[str, Any]]
    ai_insights: List[str]


# Statement Analyzer Schemas
class StatementParseResponse(BaseModel):
    filename: str
    total_parsed: int
    detected_merchants: List[str]
    parsed_transactions: List[Dict[str, Any]]
    recurring_payments: List[Dict[str, Any]]
    duplicate_charges: List[Dict[str, Any]]

class StatementImportRequest(BaseModel):
    transactions: List[TransactionCreate]

class StatementImportResponse(BaseModel):
    imported_count: int
    message: str

# Cash Flow Forecast Schemas
class ForecastDataPoint(BaseModel):
    period: str
    predicted_balance: float
    predicted_income: float
    predicted_expense: float
    lower_bound: float
    upper_bound: float

class CashFlowForecastResponse(BaseModel):
    timeframe: str
    historical: List[Dict[str, Any]]
    forecast: List[ForecastDataPoint]
    scenarios: Dict[str, List[ForecastDataPoint]]

# Financial Health Score Schema
class HealthScoreBreakdown(BaseModel):
    overall_score: float
    savings_ratio: float
    debt_ratio: float
    investment_ratio: float
    emergency_fund_coverage_months: float
    expense_stability_score: float
    suggestions: List[str]

# Investment Planner Schemas
class SIPCalculateRequest(BaseModel):
    monthly_investment: float
    expected_return_rate: float
    tenure_years: int

class SIPCalculateResponse(BaseModel):
    invested_amount: float
    est_returns: float
    total_value: float
    yearly_growth: List[Dict[str, Any]]

class InvestmentGoalCreate(BaseModel):
    name: str
    target_amount: float
    current_amount: float = 0.0
    target_years: int
    risk_level: str = "Moderate"
    monthly_sip: float = 0.0

class InvestmentGoalResponse(InvestmentGoalCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# Business Analytics Schemas
class BusinessMetricCreate(BaseModel):
    period: str
    period_type: str
    revenue: float
    profit: float
    expenses: float
    kpi_growth_rate: float

class BusinessMetricResponse(BusinessMetricCreate):
    id: int
    user_id: int

    class Config:
        from_attributes = True

# AI Assistant Schemas
class AIAdvisorRequest(BaseModel):
    prompt: str
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    year: Optional[int] = None
    month: Optional[int] = None

class AIAdvisorResponse(BaseModel):
    query: str
    reply: str
    context_used: Dict[str, Any]
