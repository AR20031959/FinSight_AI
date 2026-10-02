import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key});

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String _selectedPeriod = "Monthly";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final metrics = _getMetricsForPeriod(_selectedPeriod);

    return Scaffold(
      appBar: AppBar(
        title: Text("Business Analytics", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter Buttons (Weekly, Monthly, Quarterly, Yearly)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["Weekly", "Monthly", "Quarterly", "Yearly"].map((p) {
                final isSelected = _selectedPeriod == p;
                return ChoiceChip(
                  label: Text(p),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (val) => setState(() => _selectedPeriod = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Financial Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard("Gross Revenue", "₹${NumberFormat('#,##,##0').format(metrics['total_revenue'])}", AppColors.primary, Icons.payments_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard("Net Profit", "₹${NumberFormat('#,##,##0').format(metrics['total_profit'])}", AppColors.success, Icons.trending_up_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard("Operating Expense", "₹${NumberFormat('#,##,##0').format(metrics['total_expenses'])}", AppColors.danger, Icons.account_balance_wallet_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard("Profit Margin", "${metrics['profit_margin']}%", AppColors.secondary, Icons.pie_chart_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bar Chart - Revenue vs Expense
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Revenue vs Expense Comparison", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: (metrics['breakdown'] as List).asMap().entries.map((entry) {
                          final item = entry.value;
                          return BarChartGroupData(
                            x: entry.key,
                            barRods: [
                              BarChartRodData(toY: (item['revenue'] as num).toDouble() / 1000, color: AppColors.primary, width: 10),
                              BarChartRodData(toY: (item['expenses'] as num).toDouble() / 1000, color: AppColors.danger, width: 10),
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
                      _buildLegendItem("Revenue", AppColors.primary),
                      const SizedBox(width: 24),
                      _buildLegendItem("Expenses", AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Business KPIs Grid
            Text("Key Performance Indicators (KPIs)", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                children: [
                  _buildKPIRow("Customer Acquisition Cost (CAC)", "₹1,450"),
                  const Divider(),
                  _buildKPIRow("Customer Lifetime Value (LTV)", "₹38,500"),
                  const Divider(),
                  _buildKPIRow("Annual Run Rate (ARR)", "₹8.16 Cr"),
                  const Divider(),
                  _buildKPIRow("Monthly Burn Rate", "₹4.10 Lakhs"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color color, IconData icon) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 12)),
      ],
    );
  }

  Widget _buildKPIRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(val, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Map<String, dynamic> _getMetricsForPeriod(String period) {
    if (period == "Weekly") {
      return {
        "total_revenue": 644000,
        "total_profit": 244000,
        "total_expenses": 400000,
        "profit_margin": "37.8",
        "breakdown": [
          {"revenue": 145000, "expenses": 93000},
          {"revenue": 162000, "expenses": 101000},
          {"revenue": 158000, "expenses": 101000},
          {"revenue": 179000, "expenses": 105000},
        ]
      };
    } else if (period == "Quarterly") {
      return {
        "total_revenue": 10590000,
        "total_profit": 3940000,
        "total_expenses": 6650000,
        "profit_margin": "37.2",
        "breakdown": [
          {"revenue": 1420000, "expenses": 940000},
          {"revenue": 1580000, "expenses": 1020000},
          {"revenue": 1650000, "expenses": 1060000},
          {"revenue": 1890000, "expenses": 1180000},
        ]
      };
    } else if (period == "Yearly") {
      return {
        "total_revenue": 20890000,
        "total_profit": 7210000,
        "total_expenses": 13680000,
        "profit_margin": "34.5",
        "breakdown": [
          {"revenue": 4500000, "expenses": 3150000},
          {"revenue": 5800000, "expenses": 3880000},
          {"revenue": 6540000, "expenses": 4200000},
          {"revenue": 4050000, "expenses": 2450000},
        ]
      };
    }
    return {
      "total_revenue": 4150000,
      "total_profit": 1552000,
      "total_expenses": 2598000,
      "profit_margin": "37.4",
      "breakdown": [
        {"revenue": 520000, "expenses": 335000},
        {"revenue": 545000, "expenses": 347000},
        {"revenue": 580000, "expenses": 365000},
        {"revenue": 570000, "expenses": 366000},
        {"revenue": 615000, "expenses": 383000},
        {"revenue": 640000, "expenses": 392000},
        {"revenue": 680000, "expenses": 410000},
      ]
    };
  }
}
