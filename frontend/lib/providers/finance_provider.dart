import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/summary_model.dart';
import '../models/transaction_model.dart';

class FinanceState {
  final DashboardSummaryModel? summary;
  final List<TransactionModel> transactions;
  final bool isLoading;
  final String selectedCategoryFilter;
  final String searchQuery;
  final String salaryPeriod; // 'monthly' or 'yearly'
  final int selectedYear;
  final int selectedMonth;

  FinanceState({
    this.summary,
    this.transactions = const [],
    this.isLoading = false,
    this.selectedCategoryFilter = "All",
    this.searchQuery = "",
    this.salaryPeriod = "monthly",
    int? selectedYear,
    int? selectedMonth,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        selectedMonth = selectedMonth ?? DateTime.now().month;

  FinanceState copyWith({
    DashboardSummaryModel? summary,
    List<TransactionModel>? transactions,
    bool? isLoading,
    String? selectedCategoryFilter,
    String? searchQuery,
    String? salaryPeriod,
    int? selectedYear,
    int? selectedMonth,
  }) {
    return FinanceState(
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }
}

class FinanceNotifier extends StateNotifier<FinanceState> {
  FinanceNotifier() : super(FinanceState()) {
    fetchData();
  }

  Future<void> fetchData({int? year, int? month}) async {
    final y = year ?? state.selectedYear;
    final m = month ?? state.selectedMonth;
    state = state.copyWith(isLoading: true, selectedYear: y, selectedMonth: m);

    final Map<String, String> queryParams = {
      'year': '$y',
      'month': '$m',
    };

    final summaryRes = await ApiClient.get('/transactions/summary', queryParams: queryParams);
    final txsRes = await ApiClient.get('/transactions/', queryParams: queryParams);

    List<TransactionModel> txs = [];
    if (txsRes != null && txsRes is List) {
      txs = txsRes.map((item) => TransactionModel.fromJson(item)).toList();
    }

    if (summaryRes != null && summaryRes is Map) {
      try {
        final summary = DashboardSummaryModel.fromJson(summaryRes as Map<String, dynamic>);
        state = state.copyWith(summary: summary, transactions: txs, isLoading: false);
        return;
      } catch (_) {}
    }

    _updateStateWithTransactions(txs);
  }

  Future<void> changeMonth(int year, int month) async {
    await fetchData(year: year, month: month);
  }

  void resetState() {
    state = FinanceState();
  }

  void _updateStateWithTransactions(List<TransactionModel> txs) {
    double income = 0.0;
    double expense = 0.0;
    double investments = 0.0;

    Map<String, double> catBreakdown = {};
    Map<String, double> invBreakdown = {};

    for (var t in txs) {
      final typeLower = t.type.toLowerCase();
      if (typeLower == 'income') {
        income += t.amount;
      } else if (typeLower == 'expense') {
        expense += t.amount;
        catBreakdown[t.category] = (catBreakdown[t.category] ?? 0.0) + t.amount;
      } else if (typeLower == 'investment') {
        investments += t.amount;
        invBreakdown[t.category] = (invBreakdown[t.category] ?? 0.0) + t.amount;
      }
    }

    double netBalance = income - expense - investments;
    double savings = (income - expense - investments).clamp(0.0, double.infinity);

    double healthScore = 0.0;
    if (txs.isNotEmpty) {
      double savingsRatio = income > 0 ? ((savings + investments) / income * 100) : 30;
      healthScore = (45.0 + (savingsRatio * 0.6)).clamp(0.0, 100.0);
    }

    final summary = DashboardSummaryModel(
      totalBalance: netBalance,
      monthlyIncome: income,
      monthlyExpense: expense,
      totalInvestments: investments,
      savings: savings,
      healthScore: double.parse(healthScore.toStringAsFixed(1)),
      categoryBreakdown: catBreakdown,
      investmentBreakdown: invBreakdown,
      monthlyTrend: [
        {"month": "Active", "income": income, "expense": expense, "investment": investments},
      ],
      recentTransactions: txs,
      upcomingBills: [],
      aiInsights: txs.isEmpty
          ? ["No financial activity recorded for this period. Add transactions to generate analytics."]
          : ["Tracked ${txs.length} activities. Top expense driver: ${catBreakdown.isNotEmpty ? catBreakdown.keys.first : 'None'}."],
    );

    state = state.copyWith(summary: summary, transactions: txs, isLoading: false);
  }

  Future<void> importStatementTransactions(List<Map<String, dynamic>> parsedList) async {
    final payload = {
      "transactions": parsedList.map((tx) => {
        "title": tx['title'] ?? 'Bank Entry',
        "amount": (tx['amount'] as num).toDouble(),
        "type": tx['type'] ?? 'expense',
        "category": tx['category'] ?? 'Other Expense',
        "date": tx['date'] ?? '2026-07-15',
        "merchant": tx['merchant'],
        "is_recurring": tx['is_recurring'] ?? false,
      }).toList()
    };
    await ApiClient.post('/statement/import', payload);
    await fetchData();
  }

  Future<void> addTransaction(TransactionModel tx) async {
    await ApiClient.post('/transactions/', tx.toJson());
    await fetchData();
  }

  Future<void> editTransaction(TransactionModel tx) async {
    await ApiClient.put('/transactions/${tx.id}', tx.toJson());
    await fetchData();
  }

  Future<void> deleteTransaction(int id) async {
    await ApiClient.delete('/transactions/$id');
    await fetchData();
  }

  Future<void> clearAllTransactions() async {
    await ApiClient.delete('/transactions/clear-all');
    await fetchData();
  }

  Future<void> updatePrimarySalary({required double amount, required String period, required String title}) async {
    final double monthlyAmt = period == "yearly" ? amount / 12.0 : amount;
    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      amount: monthlyAmt,
      type: "income",
      category: "Salary / Regular Income",
      date: DateTime.now().toIso8601String().substring(0, 10),
      isRecurring: true,
    );
    await addTransaction(tx);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(selectedCategoryFilter: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSalaryPeriod(String period) {
    state = state.copyWith(salaryPeriod: period);
  }
}

final financeProvider = StateNotifierProvider<FinanceNotifier, FinanceState>((ref) {
  return FinanceNotifier();
});
