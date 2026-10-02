import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/health_score_gauge.dart';

class HealthScoreScreen extends StatelessWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Financial Health Score", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radial Score Hero Card
            CustomCard(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: Column(
                  children: [
                    const HealthScoreGauge(score: 82.5, size: 160),
                    const SizedBox(height: 16),
                    Text("FinSight Standing: Excellent", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success)),
                    const SizedBox(height: 6),
                    Text("Your financial discipline puts you in the top 8% of investors!", style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Metric Ratios Breakdown
            Text("Health Score Metrics Breakdown", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            _buildMetricBar("Savings Ratio", 50.0, "50.0% (Target: >= 30%)", AppColors.success),
            const SizedBox(height: 12),
            _buildMetricBar("Debt Ratio (EMI / Income)", 18.9, "18.9% (Ideal: <= 30%)", AppColors.success),
            const SizedBox(height: 12),
            _buildMetricBar("Investment Ratio", 13.3, "13.3% (Target: >= 20%)", AppColors.warning),
            const SizedBox(height: 12),
            _buildMetricBar("Emergency Fund Coverage", 76.6, "4.6 Months (Target: 6.0 Months)", AppColors.secondary),
            const SizedBox(height: 12),
            _buildMetricBar("Expense Stability Score", 88.5, "88.5 / 100", AppColors.primary),

            const SizedBox(height: 28),

            // Actionable Improvement Suggestions
            Text("Actionable Improvement Tips", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            _buildTipCard("Increase Equity SIP", "Automate an additional 5% SIP into equity index mutual funds to beat inflation and achieve your target 20% investment ratio.", Icons.trending_up_rounded, AppColors.success),
            const SizedBox(height: 12),
            _buildTipCard("Build Emergency Runway", "You currently have 4.6 months of liquid reserves. Add ₹15,000/mo to liquid funds to reach full 6-month coverage.", Icons.shield_rounded, AppColors.secondary),
          ],
        ),
      ),
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
            value: pct / 100.0,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
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
                Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
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
