import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/health_score_gauge.dart';

class HealthScoreScreen extends ConsumerStatefulWidget {
  const HealthScoreScreen({super.key});

  @override
  ConsumerState<HealthScoreScreen> createState() => _HealthScoreScreenState();
}

class _HealthScoreScreenState extends ConsumerState<HealthScoreScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _healthData;

  @override
  void initState() {
    super.initState();
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiClient.get('/health/score');
    if (res != null && res is Map<String, dynamic>) {
      setState(() {
        _healthData = res;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = "Failed to load dynamic financial health metrics from server.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Financial Health Score", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchHealthData,
            tooltip: "Refresh Health Analysis",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Calculating dynamic health score..."),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.inter(color: Colors.red), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchHealthData,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRadialScoreCard(_healthData!, isDark),
                      const SizedBox(height: 24),
                      Text("Health Score Metrics Breakdown", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      _buildMetricsBreakdown(_healthData!),
                      const SizedBox(height: 28),
                      Text("Actionable Improvement Tips", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      _buildSuggestionsList(_healthData!),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRadialScoreCard(Map<String, dynamic> data, bool isDark) {
    final double overallScore = (data["overall_score"] as num?)?.toDouble() ?? 0.0;
    
    String standingText;
    Color standingColor;
    if (overallScore >= 80) {
      standingText = "FinSight Standing: Excellent";
      standingColor = AppColors.success;
    } else if (overallScore >= 60) {
      standingText = "FinSight Standing: Good";
      standingColor = AppColors.primary;
    } else if (overallScore >= 40) {
      standingText = "FinSight Standing: Fair";
      standingColor = AppColors.warning;
    } else {
      standingText = "FinSight Standing: Action Recommended";
      standingColor = AppColors.danger;
    }

    return CustomCard(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          children: [
            HealthScoreGauge(score: overallScore, size: 160),
            const SizedBox(height: 16),
            Text(standingText, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: standingColor)),
            const SizedBox(height: 6),
            Text(
              "Calculated dynamically from your actual income, debt obligations, savings, and investments.",
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsBreakdown(Map<String, dynamic> data) {
    final savingsRatio = (data["savings_ratio"] as num?)?.toDouble() ?? 0.0;
    final debtRatio = (data["debt_ratio"] as num?)?.toDouble() ?? 0.0;
    final investmentRatio = (data["investment_ratio"] as num?)?.toDouble() ?? 0.0;
    final emergencyMonths = (data["emergency_fund_coverage_months"] as num?)?.toDouble() ?? 0.0;
    final stabilityScore = (data["expense_stability_score"] as num?)?.toDouble() ?? 0.0;

    return Column(
      children: [
        _buildMetricBar("Savings Ratio", savingsRatio, "${savingsRatio.toStringAsFixed(1)}% (Target: >= 20%)", savingsRatio >= 20 ? AppColors.success : AppColors.warning),
        const SizedBox(height: 12),
        _buildMetricBar("Debt Ratio (EMI / Income)", debtRatio, "${debtRatio.toStringAsFixed(1)}% (Ideal: <= 35%)", debtRatio <= 35 ? AppColors.success : AppColors.danger),
        const SizedBox(height: 12),
        _buildMetricBar("Investment Ratio", investmentRatio, "${investmentRatio.toStringAsFixed(1)}% (Target: >= 15%)", investmentRatio >= 15 ? AppColors.success : AppColors.warning),
        const SizedBox(height: 12),
        _buildMetricBar("Emergency Fund Coverage", (emergencyMonths / 6.0 * 100.0).clamp(0.0, 100.0), "${emergencyMonths.toStringAsFixed(1)} Months (Target: 6.0 Months)", emergencyMonths >= 6 ? AppColors.secondary : AppColors.warning),
        const SizedBox(height: 12),
        _buildMetricBar("Expense Stability Score", stabilityScore, "${stabilityScore.toStringAsFixed(1)} / 100", AppColors.primary),
      ],
    );
  }

  Widget _buildMetricBar(String title, double pct, String valueText, Color color) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(valueText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (pct / 100.0).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(Map<String, dynamic> data) {
    final List suggestions = (data["suggestions"] as List?) ?? [];
    if (suggestions.isEmpty) {
      return const CustomCard(
        child: Text("No actionable recommendations generated yet."),
      );
    }

    return Column(
      children: suggestions.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildTipCard("Financial Advisor Insight", tip.toString(), Icons.tips_and_updates_rounded, AppColors.primary),
        );
      }).toList(),
    );
  }

  Widget _buildTipCard(String title, String desc, IconData icon, Color color) {
    return CustomCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
