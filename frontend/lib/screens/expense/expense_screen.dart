import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/transaction_tile.dart';

class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = "All";
  String _selectedMonthKey = "All"; // "All" or "yyyy-MM" e.g. "2026-07"

  final List<Map<String, String>> _monthOptions = [
    {"key": "All", "label": "All Months"},
    {"key": "2026-01", "label": "Jan 2026"},
    {"key": "2026-02", "label": "Feb 2026"},
    {"key": "2026-03", "label": "Mar 2026"},
    {"key": "2026-04", "label": "Apr 2026"},
    {"key": "2026-05", "label": "May 2026"},
    {"key": "2026-06", "label": "Jun 2026"},
    {"key": "2026-07", "label": "Jul 2026"},
    {"key": "2026-08", "label": "Aug 2026"},
    {"key": "2026-09", "label": "Sep 2026"},
    {"key": "2026-10", "label": "Oct 2026"},
    {"key": "2026-11", "label": "Nov 2026"},
    {"key": "2026-12", "label": "Dec 2026"},
  ];

  void _showAddTransactionModal(BuildContext context, {TransactionModel? initialTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(initialTx: initialTx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Filter by selected Month strictly from actual transactions
    var monthFilteredList = financeState.transactions;
    if (_selectedMonthKey != "All") {
      monthFilteredList = monthFilteredList.where((t) {
        return t.date.startsWith(_selectedMonthKey);
      }).toList();
    }

    // 2. Calculate actual Monthly Analytics Metrics from dataset
    double monthIncome = 0.0;
    double monthExpense = 0.0;
    double monthInvestment = 0.0;
    Map<String, double> categoryBreakdown = {};

    for (var t in monthFilteredList) {
      final type = t.type.toLowerCase();
      if (type == 'income') {
        monthIncome += t.amount;
      } else if (type == 'expense') {
        monthExpense += t.amount;
        categoryBreakdown[t.category] = (categoryBreakdown[t.category] ?? 0.0) + t.amount;
      } else if (type == 'investment') {
        monthInvestment += t.amount;
        categoryBreakdown[t.category] = (categoryBreakdown[t.category] ?? 0.0) + t.amount;
      }
    }
    double monthSavings = (monthIncome - monthExpense - monthInvestment).clamp(0.0, double.infinity);

    // 3. Apply category filter & search query to final display list
    var displayList = monthFilteredList;
    if (_selectedCategory != "All") {
      displayList = displayList.where((t) => t.category == _selectedCategory).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      displayList = displayList.where((t) => t.title.toLowerCase().contains(q) || (t.merchant?.toLowerCase().contains(q) ?? false)).toList();
    }

    final selectedMonthLabel = _monthOptions.firstWhere(
      (m) => m["key"] == _selectedMonthKey,
      orElse: () => {"key": _selectedMonthKey, "label": _selectedMonthKey},
    )["label"];

    return Scaffold(
      appBar: AppBar(
        title: Text("Financial Analytics & Ledger", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: "Add Activity",
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddTransactionModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text("Add Activity", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector (Compact Radio / Choice Chip experience)
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  "Month Selection",
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _monthOptions.length,
                itemBuilder: (context, index) {
                  final option = _monthOptions[index];
                  final isSelected = _selectedMonthKey == option["key"];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(option["label"]!),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedMonthKey = option["key"]!;
                          });
                          if (option["key"] != "All" && option["key"]!.contains("-")) {
                            final parts = option["key"]!.split("-");
                            final y = int.tryParse(parts[0]);
                            final m = int.tryParse(parts[1]);
                            if (y != null && m != null) {
                              ref.read(financeProvider.notifier).changeMonth(y, m);
                            }
                          } else {
                            ref.read(financeProvider.notifier).fetchData();
                          }
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Monthly Analytics Dashboard Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$selectedMonthLabel Analytics",
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${monthFilteredList.length} Entries",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (monthFilteredList.isEmpty && _selectedMonthKey != "All")
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.event_busy_rounded, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              "No financial activity recorded for this month.",
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // KPI Row
                    Wrap(
                      alignment: WrapAlignment.spaceAround,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        _buildKpiTile("Income", monthIncome, AppColors.success),
                        _buildKpiTile("Expenses", monthExpense, AppColors.danger),
                        _buildKpiTile("Investments", monthInvestment, AppColors.secondary),
                        _buildKpiTile("Net Savings", monthSavings, AppColors.warning),
                      ],
                    ),

                    if (categoryBreakdown.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Text("Category Breakdown", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: categoryBreakdown.entries.map((e) {
                          final catColor = AppCategories.getColor(e.key);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.key, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: catColor)),
                                const SizedBox(width: 4),
                                Text("₹${NumberFormat('#,##,##0').format(e.value)}", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: catColor)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search Bar (Cleaned - No Link Statement button)
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search activities or merchants...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Categories horizontal filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ["All", ...AppCategories.categories].map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Transactions list
            Expanded(
              child: displayList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            "No financial entries found",
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tap 'Add Activity' to record transactions.",
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final tx = displayList[index];
                        return TransactionTile(
                          tx: tx,
                          onEdit: () => _showAddTransactionModal(context, initialTx: tx),
                          onDelete: () => ref.read(financeProvider.notifier).deleteTransaction(tx.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiTile(String label, double val, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "₹${NumberFormat('#,##,##0').format(val)}",
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

class AddTransactionModal extends ConsumerStatefulWidget {
  final TransactionModel? initialTx;
  const AddTransactionModal({super.key, this.initialTx});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();

  late String _type;
  late String _category;
  late bool _isRecurring;
  String _salaryPeriod = "monthly"; // "monthly" or "yearly"

  @override
  void initState() {
    super.initState();
    final init = widget.initialTx;
    if (init != null) {
      _titleController.text = init.title;
      _amountController.text = init.amount.toString();
      _merchantController.text = init.merchant ?? "";
      _type = init.type.toLowerCase();
      _category = init.category;
      _isRecurring = init.isRecurring;
    } else {
      _type = "expense";
      _category = AppCategories.getCategoriesForType("expense").first;
      _isRecurring = false;
    }
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      final options = AppCategories.getCategoriesForType(newType);
      _category = options.first;
    });
  }

  void _onSalaryPeriodChanged(String newPeriod) {
    if (_salaryPeriod == newPeriod) return;
    final currentText = _amountController.text.trim();
    final currentAmt = double.tryParse(currentText) ?? 0.0;

    setState(() {
      if (currentAmt > 0) {
        if (newPeriod == "yearly" && _salaryPeriod == "monthly") {
          final yearlyVal = currentAmt * 12.0;
          _amountController.text = yearlyVal % 1 == 0 ? yearlyVal.toInt().toString() : yearlyVal.toStringAsFixed(2);
        } else if (newPeriod == "monthly" && _salaryPeriod == "yearly") {
          final monthlyVal = currentAmt / 12.0;
          _amountController.text = monthlyVal % 1 == 0 ? monthlyVal.toInt().toString() : monthlyVal.toStringAsFixed(2);
        }
      }
      _salaryPeriod = newPeriod;
    });
  }

  void _save() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) return;
    double rawAmt = double.tryParse(_amountController.text) ?? 0.0;
    
    // If entered as Yearly Salary / Income, calculate monthly equivalent for standard ledger tracking
    double finalAmt = rawAmt;
    if ((_type == "income" || _category == "Salary") && _salaryPeriod == "yearly") {
      finalAmt = rawAmt / 12.0;
    }

    if (widget.initialTx != null) {
      final updatedTx = TransactionModel(
        id: widget.initialTx!.id,
        title: _titleController.text,
        amount: finalAmt,
        type: _type,
        category: _category,
        date: widget.initialTx!.date,
        merchant: _merchantController.text.isNotEmpty ? _merchantController.text : null,
        isRecurring: _isRecurring,
      );
      ref.read(financeProvider.notifier).editTransaction(updatedTx);
    } else {
      final newTx = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: _titleController.text,
        amount: finalAmt,
        type: _type,
        category: _category,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        merchant: _merchantController.text.isNotEmpty ? _merchantController.text : null,
        isRecurring: _isRecurring,
      );
      ref.read(financeProvider.notifier).addTransaction(newTx);
    }
    ref.read(financeProvider.notifier).setSalaryPeriod(_salaryPeriod);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryOptions = AppCategories.getCategoriesForType(_type);
    final isEditing = widget.initialTx != null;
    final isIncomeOrSalary = _type == "income" || _category == "Salary";

    final inputAmount = double.tryParse(_amountController.text) ?? 0.0;
    final monthlyCalc = _salaryPeriod == "yearly" ? (inputAmount / 12.0) : inputAmount;
    final yearlyCalc = _salaryPeriod == "monthly" ? (inputAmount * 12.0) : inputAmount;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? "Edit Financial Activity" : "Add Financial Activity",
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),

            // Segmented 4-Type Selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text("Expense", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  selected: _type == "expense",
                  selectedColor: AppColors.danger.withOpacity(0.2),
                  onSelected: (val) => _onTypeChanged("expense"),
                ),
                ChoiceChip(
                  label: Text("Investment", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  selected: _type == "investment",
                  selectedColor: AppColors.secondary.withOpacity(0.2),
                  onSelected: (val) => _onTypeChanged("investment"),
                ),
                ChoiceChip(
                  label: Text("Income", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  selected: _type == "income",
                  selectedColor: AppColors.success.withOpacity(0.2),
                  onSelected: (val) => _onTypeChanged("income"),
                ),
                ChoiceChip(
                  label: Text("Savings", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  selected: _type == "savings",
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  onSelected: (val) => _onTypeChanged("savings"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Salary / Income Period Selector (Monthly vs Yearly)
            if (isIncomeOrSalary) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 6),
                            Text("Salary / Income Frequency", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            ChoiceChip(
                              label: Text("Monthly", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: _salaryPeriod == "monthly",
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: _salaryPeriod == "monthly" ? Colors.white : null),
                              onSelected: (_) => _onSalaryPeriodChanged("monthly"),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text("Yearly (CTC)", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                              selected: _salaryPeriod == "yearly",
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: _salaryPeriod == "yearly" ? Colors.white : null),
                              onSelected: (_) => _onSalaryPeriodChanged("yearly"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (inputAmount > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _salaryPeriod == "yearly"
                              ? "💡 Monthly Equivalent: ₹${NumberFormat('#,##,##0.00').format(monthlyCalc)} / month"
                              : "💡 Yearly Salary Equivalent: ₹${NumberFormat('#,##,##0.00').format(yearlyCalc)} / year",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title / Description",
                hintText: _type == "investment" ? "e.g. Zerodha Nifty Index SIP" : (_type == "income" ? "e.g. Tech Corp Salary" : "e.g. Grocery Shopping"),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: isIncomeOrSalary ? "Salary Amount (₹) [${_salaryPeriod.toUpperCase()}]" : "Amount (₹)",
                hintText: _salaryPeriod == "yearly" ? "e.g. 1200000 (12 Lakhs CTC)" : "e.g. 100000 (Monthly)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              value: categoryOptions.contains(_category) ? _category : categoryOptions.first,
              items: categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _category = val ?? categoryOptions.first),
              decoration: InputDecoration(
                labelText: "Category (${_type.toUpperCase()})",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _merchantController,
              decoration: InputDecoration(
                labelText: "Merchant / Platform (Optional)",
                hintText: _type == "investment" ? "Zerodha / Groww / HDFC Bank" : "Swiggy / Amazon",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: Text("Auto-Recurring Monthly", style: GoogleFonts.inter(fontSize: 14)),
              subtitle: Text("Auto-repeats on salary / SIP date", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              value: _isRecurring,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isEditing ? "Update Financial Entry" : "Save Activity Entry",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
