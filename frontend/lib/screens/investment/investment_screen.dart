import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  double _monthlySip = 15000;
  double _expectedReturn = 12.0;
  double _tenureYears = 10;
  String _riskLevel = "Moderate";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Clean SIP Calculations
    final i = (_expectedReturn / 100.0) / 12.0;
    final n = _tenureYears * 12;
    final investedAmount = _monthlySip * n;
    final totalValue = _monthlySip * ((pow(1 + i, n) - 1) / i) * (1 + i);
    final estReturns = totalValue - investedAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text("Investment Planner", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SIP Calculator Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SIP Growth Calculator", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Icon(Icons.calculate_rounded, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Monthly Investment Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Monthly SIP Amount", style: GoogleFonts.inter(fontSize: 13)),
                      Text("₹${NumberFormat('#,##,##0').format(_monthlySip)}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _monthlySip,
                    min: 1000,
                    max: 100000,
                    divisions: 99,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _monthlySip = val),
                  ),

                  // Expected Return % Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Expected Return Rate (p.a)", style: GoogleFonts.inter(fontSize: 13)),
                      Text("${_expectedReturn.toStringAsFixed(1)}%", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                  Slider(
                    value: _expectedReturn,
                    min: 5,
                    max: 25,
                    divisions: 40,
                    activeColor: AppColors.success,
                    onChanged: (val) => setState(() => _expectedReturn = val),
                  ),

                  // Tenure Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Time Period (Years)", style: GoogleFonts.inter(fontSize: 13)),
                      Text("${_tenureYears.toInt()} Years", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                    ],
                  ),
                  Slider(
                    value: _tenureYears,
                    min: 1,
                    max: 30,
                    divisions: 29,
                    activeColor: AppColors.secondary,
                    onChanged: (val) => setState(() => _tenureYears = val),
                  ),

                  const Divider(height: 28),

                  // Growth Projections Result Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildResultItem("Invested Amount", "₹${NumberFormat('#,##,##0').format(investedAmount)}", isDark ? Colors.white70 : Colors.black87),
                      _buildResultItem("Est. Wealth Gain", "₹${NumberFormat('#,##,##0').format(estReturns)}", AppColors.success),
                      _buildResultItem("Future Portfolio", "₹${NumberFormat('#,##,##0').format(totalValue)}", AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Risk Assessment & Asset Allocation Suggestion
            Text("Asset Allocation Engine", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Risk Profile:", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      DropdownButton<String>(
                        value: _riskLevel,
                        items: ["Low", "Moderate", "High"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) => setState(() => _riskLevel = val ?? "Moderate"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: _buildAllocationSections(_riskLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _riskLevel == "Low"
                        ? "Conservative Strategy: 55% Debt & FD, 25% Equity, 15% Gold, 5% Liquid Cash."
                        : _riskLevel == "High"
                            ? "Aggressive Growth: 70% Equity Mutual Funds, 15% Smallcap, 10% Debt, 5% Gold."
                            : "Balanced Growth: 50% Equity Mutual Funds, 30% Debt/FD, 10% Gold, 10% Cash.",
                    style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Goal-Based Planning Progress
            Text("Your Financial Goals", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildGoalCard("Luxury Vehicle Fund", 450000, 1200000, 3, AppColors.primary),
            const SizedBox(height: 12),
            _buildGoalCard("Dream Home Down payment", 890000, 2500000, 5, AppColors.secondary),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(val, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  List<PieChartSectionData> _buildAllocationSections(String risk) {
    if (risk == "Low") {
      return [
        PieChartSectionData(color: const Color(0xFF2563EB), value: 25, title: '25%', radius: 25),
        PieChartSectionData(color: const Color(0xFF22C55E), value: 55, title: '55%', radius: 25),
        PieChartSectionData(color: const Color(0xFFF59E0B), value: 15, title: '15%', radius: 25),
        PieChartSectionData(color: const Color(0xFF06B6D4), value: 5, title: '5%', radius: 25),
      ];
    } else if (risk == "High") {
      return [
        PieChartSectionData(color: const Color(0xFF2563EB), value: 70, title: '70%', radius: 25),
        PieChartSectionData(color: const Color(0xFF22C55E), value: 10, title: '10%', radius: 25),
        PieChartSectionData(color: const Color(0xFFF59E0B), value: 5, title: '5%', radius: 25),
        PieChartSectionData(color: const Color(0xFFA855F7), value: 15, title: '15%', radius: 25),
      ];
    }
    return [
      PieChartSectionData(color: const Color(0xFF2563EB), value: 50, title: '50%', radius: 25),
      PieChartSectionData(color: const Color(0xFF22C55E), value: 30, title: '30%', radius: 25),
      PieChartSectionData(color: const Color(0xFFF59E0B), value: 10, title: '10%', radius: 25),
      PieChartSectionData(color: const Color(0xFF06B6D4), value: 10, title: '10%', radius: 25),
    ];
  }

  Widget _buildGoalCard(String title, double current, double target, int years, Color color) {
    final pct = (current / target);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("${(pct * 100).toStringAsFixed(0)}%", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Saved: ₹${NumberFormat('#,##,##0').format(current)}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text("Target: ₹${NumberFormat('#,##,##0').format(target)}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
