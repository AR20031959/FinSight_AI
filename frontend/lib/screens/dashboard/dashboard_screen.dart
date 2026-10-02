import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/health_score_gauge.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/pdf_report_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeProvider);
    final summary = financeState.summary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (summary == null && financeState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                "Loading FinSight AI Dashboard...",
                style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    if (summary == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                Text("Unable to load summary", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Tap refresh to sync financial data.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.read(financeProvider.notifier).fetchData(),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text("Refresh", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                "FinSight AI",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Generate Date-Range PDF Report",
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const PdfReportModal(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final isDesktop = constraints.maxWidth >= 1024;
          final contentPadding = constraints.maxWidth < 400 ? 12.0 : 20.0;

          return RefreshIndicator(
            onRefresh: () => ref.read(financeProvider.notifier).fetchData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dual Entry Choice Banner
                  _buildAddActivityBanner(context, isDark, constraints.maxWidth),
                  const SizedBox(height: 18),

                  // 2. Total Balance Banner
                  _buildTotalBalanceBanner(ref, financeState, summary, isDark, constraints.maxWidth),
                  const SizedBox(height: 20),

                  // 3. Financial Health Score & Upcoming Bills Section
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildHealthScoreCard(context, summary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildUpcomingBillsCard(summary),
                        ),
                      ],
                    )
                  else ...[
                    _buildHealthScoreCard(context, summary),
                    const SizedBox(height: 16),
                    _buildUpcomingBillsCard(summary),
                  ],
                  const SizedBox(height: 20),

                  // 4. AI Insights Section
                  _buildAiInsightsCard(summary, isDark),
                  const SizedBox(height: 24),

                  // 5. Interactive Visual Analytics & Multi-Charts
                  Text("Interactive Visual Analytics", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 14),

                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildCategoryPieChartCard(summary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildBarChartCard(summary),
                              const SizedBox(height: 16),
                              _buildLineChartCard(summary),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _buildCategoryPieChartCard(summary),
                    const SizedBox(height: 16),
                    _buildBarChartCard(summary),
                    const SizedBox(height: 16),
                    _buildLineChartCard(summary),
                  ],
                  const SizedBox(height: 24),

                  // 6. Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Recent Activity Ledger",
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/expense'),
                        child: Text("View All", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (financeState.transactions.isEmpty)
                    CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No financial activities recorded yet.",
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...financeState.transactions.take(5).map((tx) => TransactionTile(
                          tx: tx,
                          onDelete: () => ref.read(financeProvider.notifier).deleteTransaction(tx.id),
                        )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddActivityBanner(BuildContext context, bool isDark, double width) {
    final isCompact = width < 520;

    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Add Financial Activities", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                          Text("Link bank statement or enter data manually", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: "Link Bank Statement (Upload)",
                      icon: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                      onPressed: () => context.push('/statement'),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/expense'),
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: Text("Manual Entry", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Add Financial Activities", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text("Link bank statement or enter data manually", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: "Link Bank Statement (Upload)",
                      icon: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                      onPressed: () => context.push('/statement'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/expense'),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      label: Text("Manual Entry", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTotalBalanceBanner(WidgetRef ref, FinanceState financeState, dynamic summary, bool isDark, double width) {
    return CustomCard(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "Total Portfolio Balance",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(financeProvider.notifier).setSalaryPeriod("monthly"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: financeState.salaryPeriod == "monthly" ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Monthly",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: financeState.salaryPeriod == "monthly" ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(financeProvider.notifier).setSalaryPeriod("yearly"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: financeState.salaryPeriod == "yearly" ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "Yearly",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: financeState.salaryPeriod == "yearly" ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "₹${NumberFormat('#,##,##0.00').format(summary.totalBalance)}",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text("+12.4%", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildStatColumn(
                financeState.salaryPeriod == "yearly" ? "Yearly Salary" : "Monthly Income",
                "₹${NumberFormat('#,##,##0').format(financeState.salaryPeriod == "yearly" ? summary.monthlyIncome * 12 : summary.monthlyIncome)}",
                AppColors.success,
              ),
              _buildStatColumn(
                financeState.salaryPeriod == "yearly" ? "Yearly Expense" : "Monthly Expense",
                "₹${NumberFormat('#,##,##0').format(financeState.salaryPeriod == "yearly" ? summary.monthlyExpense * 12 : summary.monthlyExpense)}",
                AppColors.danger,
              ),
              _buildStatColumn(
                financeState.salaryPeriod == "yearly" ? "Annual Investments" : "Investments",
                "₹${NumberFormat('#,##,##0').format(financeState.salaryPeriod == "yearly" ? summary.totalInvestments * 12 : summary.totalInvestments)}",
                AppColors.secondary,
              ),
              _buildStatColumn(
                financeState.salaryPeriod == "yearly" ? "Annual Savings" : "Net Savings",
                "₹${NumberFormat('#,##,##0').format(financeState.salaryPeriod == "yearly" ? summary.savings * 12 : summary.savings)}",
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context, dynamic summary) {
    return CustomCard(
      onTap: () => context.push('/health-score'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HealthScoreGauge(score: summary.healthScore, size: 120),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Excellent Standing", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingBillsCard(dynamic summary) {
    final bills = summary.upcomingBills as List;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Upcoming Bills", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.event_note_rounded, size: 18, color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                "No pending bills due soon.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...bills.take(2).map((bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bill['biller_name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text("Due ${bill['due_date']}", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text("₹${bill['amount']}", style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.warning)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildAiInsightsCard(dynamic summary, bool isDark) {
    final insights = summary.aiInsights as List<String>;
    return CustomCard(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text("AI Monthly Insights", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Expanded(
                      child: Text(insight, style: GoogleFonts.inter(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChartCard(dynamic summary) {
    final catBreakdown = summary.categoryBreakdown as Map<String, double>;
    final invBreakdown = summary.investmentBreakdown as Map<String, double>;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Category Allocation (Pie)", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 38,
                sections: _buildPieSections(catBreakdown, invBreakdown),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ...catBreakdown.keys,
              ...invBreakdown.keys,
            ].map((cat) {
              final color = AppCategories.getColor(cat);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(cat, style: GoogleFonts.inter(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(dynamic summary) {
    final trend = summary.monthlyTrend as List;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Income vs Expense vs Investments", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.bar_chart_rounded, color: AppColors.secondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final index = val.toInt();
                        if (index >= 0 && index < trend.length) {
                          return Text(trend[index]['month'] ?? '', style: GoogleFonts.inter(fontSize: 10));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: trend.asMap().entries.map((e) {
                  final i = e.key;
                  final m = e.value;
                  final inc = ((m['income'] as num?) ?? 0) / 1000.0;
                  final exp = ((m['expense'] as num?) ?? 0) / 1000.0;
                  final inv = ((m['investment'] as num?) ?? 0) / 1000.0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(toY: inc, color: AppColors.success, width: 7, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: exp, color: AppColors.danger, width: 7, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: inv, color: AppColors.secondary, width: 7, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Income", AppColors.success),
              const SizedBox(width: 16),
              _buildLegendItem("Expense", AppColors.danger),
              const SizedBox(width: 16),
              _buildLegendItem("Investment", AppColors.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(dynamic summary) {
    final trend = summary.monthlyTrend as List;
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Net Portfolio Trend", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
              const Icon(Icons.show_chart_rounded, color: AppColors.success, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), ((e.value['income'] as num?) ?? 0).toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), ((e.value['expense'] as num?) ?? 0).toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.danger,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), ((e.value['investment'] as num?) ?? 0).toDouble())).toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> expenseBreakdown, Map<String, double> investmentBreakdown) {
    final combined = {...expenseBreakdown, ...investmentBreakdown};
    final total = combined.values.fold(0.0, (sum, item) => sum + item);
    if (total == 0) {
      return [
        PieChartSectionData(color: Colors.grey, value: 100, title: '0%', radius: 25)
      ];
    }
    return combined.entries.map((e) {
      final pct = (e.value / total) * 100;
      final color = AppCategories.getColor(e.key);
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 30,
        titleStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }
}

