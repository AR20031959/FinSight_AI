import 'transaction_model.dart';

class DashboardSummaryModel {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double totalInvestments;
  final double savings;
  final double healthScore;
  final Map<String, double> categoryBreakdown;
  final Map<String, double> investmentBreakdown;
  final List<Map<String, dynamic>> monthlyTrend;
  final List<TransactionModel> recentTransactions;
  final List<Map<String, dynamic>> upcomingBills;
  final List<String> aiInsights;

  DashboardSummaryModel({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.totalInvestments = 0.0,
    required this.savings,
    required this.healthScore,
    required this.categoryBreakdown,
    this.investmentBreakdown = const {},
    required this.monthlyTrend,
    required this.recentTransactions,
    required this.upcomingBills,
    required this.aiInsights,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    Map<String, double> catMap = {};
    if (json['category_breakdown'] != null) {
      (json['category_breakdown'] as Map<String, dynamic>).forEach((key, val) {
        catMap[key] = (val as num).toDouble();
      });
    }

    Map<String, double> invMap = {};
    if (json['investment_breakdown'] != null) {
      (json['investment_breakdown'] as Map<String, dynamic>).forEach((key, val) {
        invMap[key] = (val as num).toDouble();
      });
    }

    List<TransactionModel> txs = [];
    if (json['recent_transactions'] != null) {
      txs = (json['recent_transactions'] as List)
          .map((item) => TransactionModel.fromJson(item))
          .toList();
    }

    return DashboardSummaryModel(
      totalBalance: (json['total_balance'] ?? 0.0).toDouble(),
      monthlyIncome: (json['monthly_income'] ?? 0.0).toDouble(),
      monthlyExpense: (json['monthly_expense'] ?? 0.0).toDouble(),
      totalInvestments: (json['total_investments'] ?? 0.0).toDouble(),
      savings: (json['savings'] ?? 0.0).toDouble(),
      healthScore: (json['health_score'] ?? 80.0).toDouble(),
      categoryBreakdown: catMap,
      investmentBreakdown: invMap,
      monthlyTrend: List<Map<String, dynamic>>.from(json['monthly_trend'] ?? []),
      recentTransactions: txs,
      upcomingBills: List<Map<String, dynamic>>.from(json['upcoming_bills'] ?? []),
      aiInsights: List<String>.from(json['ai_insights'] ?? []),
    );
  }
}
