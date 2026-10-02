import 'transaction_model.dart';

class DashboardSummaryModel {
  final String period;
  final String periodType;
  final List<int> availableYears;
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalInvestments;
  final double savings;
  final double savingsRate;
  final double healthScore;
  final int transactionCount;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> investmentBreakdown;
  final Map<String, dynamic>? largestExpense;
  final List<Map<String, dynamic>> recurringExpenses;
  final double totalRecurringAmount;
  final Map<String, dynamic>? monthOverMonthChanges;
  final List<Map<String, dynamic>> monthlyTrend;
  final List<Map<String, dynamic>> yearlyTrend;
  final List<TransactionModel> recentTransactions;
  final List<Map<String, dynamic>> upcomingBills;
  final List<String> aiInsights;

  DashboardSummaryModel({
    this.period = "All Months",
    this.periodType = "monthly",
    this.availableYears = const [],
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.totalInvestments = 0.0,
    required this.savings,
    this.savingsRate = 0.0,
    required this.healthScore,
    this.transactionCount = 0,
    required this.categoryBreakdown,
    this.investmentBreakdown = const {},
    this.largestExpense,
    this.recurringExpenses = const [],
    this.totalRecurringAmount = 0.0,
    this.monthOverMonthChanges,
    required this.monthlyTrend,
    this.yearlyTrend = const [],
    required this.recentTransactions,
    required this.upcomingBills,
    required this.aiInsights,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> catMap = {};
    if (json['category_breakdown'] != null && json['category_breakdown'] is Map) {
      (json['category_breakdown'] as Map).forEach((key, val) {
        if (val is num) catMap[key.toString()] = val.toDouble();
      });
    }

    Map<String, double> invMap = {};
    if (json['investment_breakdown'] != null && json['investment_breakdown'] is Map) {
      (json['investment_breakdown'] as Map).forEach((key, val) {
        if (val is num) invMap[key.toString()] = val.toDouble();
      });
    }

    List<TransactionModel> txs = [];
    if (json['recent_transactions'] != null && json['recent_transactions'] is List) {
      txs = (json['recent_transactions'] as List)
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    Map<String, dynamic>? mom;
    if (json['month_over_month_changes'] != null && json['month_over_month_changes'] is Map) {
      mom = Map<String, dynamic>.from(json['month_over_month_changes']);
    }

    Map<String, dynamic>? largestExp;
    if (json['largest_expense'] != null && json['largest_expense'] is Map) {
      largestExp = Map<String, dynamic>.from(json['largest_expense']);
    }

    List<Map<String, dynamic>> recExp = [];
    if (json['recurring_expenses'] != null && json['recurring_expenses'] is List) {
      recExp = List<Map<String, dynamic>>.from(json['recurring_expenses']);
    }

    List<int> years = [];
    if (json['available_years'] != null && json['available_years'] is List) {
      years = List<int>.from(json['available_years'].map((e) => (e as num).toInt()));
    }

    return DashboardSummaryModel(
      period: json['period']?.toString() ?? "All Months",
      periodType: json['period_type']?.toString() ?? "monthly",
      availableYears: years,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0.0,
      monthlyExpense: (json['monthly_expense'] as num?)?.toDouble() ?? 0.0,
      totalInvestments: (json['total_investments'] as num?)?.toDouble() ?? 0.0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savings_rate'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['health_score'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      categoryBreakdown: catMap,
      investmentBreakdown: invMap,
      largestExpense: largestExp,
      recurringExpenses: recExp,
      totalRecurringAmount: (json['total_recurring_amount'] as num?)?.toDouble() ?? 0.0,
      monthOverMonthChanges: mom,
      monthlyTrend: json['monthly_trend'] != null && json['monthly_trend'] is List
          ? List<Map<String, dynamic>>.from(json['monthly_trend'])
          : [],
      yearlyTrend: json['yearly_trend'] != null && json['yearly_trend'] is List
          ? List<Map<String, dynamic>>.from(json['yearly_trend'])
          : [],
      recentTransactions: txs,
      upcomingBills: json['upcoming_bills'] != null && json['upcoming_bills'] is List
          ? List<Map<String, dynamic>>.from(json['upcoming_bills'])
          : [],
      aiInsights: json['ai_insights'] != null && json['ai_insights'] is List
          ? List<String>.from(json['ai_insights'].map((e) => e.toString()))
          : [],
    );
  }
}

