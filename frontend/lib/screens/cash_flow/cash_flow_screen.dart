import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants.dart';
import '../../widgets/custom_card.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  String _timeframe = "6 Months";
  String _scenario = "Realistic";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final forecastData = _getForecastData(_timeframe, _scenario);

    return Scaffold(
      appBar: AppBar(
        title: Text("Cash Flow Forecast", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe Selector Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ["1 Month", "3 Months", "6 Months", "12 Months"].map((t) {
                final isSelected = _timeframe == t;
                return ChoiceChip(
                  label: Text(t),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  onSelected: (val) => setState(() => _timeframe = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Scenario Buttons (Realistic, Pessimistic, Optimistic)
            CustomCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildScenarioTab("Realistic", AppColors.primary),
                  _buildScenarioTab("Pessimistic", AppColors.danger),
                  _buildScenarioTab("Optimistic", AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Forecast Interactive Line Chart with Confidence Interval
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Predicted Liquidity Runway", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text("95% Confidence Interval", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Predicted Line
                          LineChartBarData(
                            spots: (forecastData as List).asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['predicted'] as num).toDouble() / 1000)).toList(),
                            isCurved: true,
                            color: _getScenarioColor(_scenario),
                            barWidth: 3.5,
                            dotData: const FlDotData(show: true),
                          ),
                          // Upper Bound
                          LineChartBarData(
                            spots: forecastData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['upper'] as num).toDouble() / 1000)).toList(),
                            isCurved: true,
                            color: _getScenarioColor(_scenario).withOpacity(0.4),
                            barWidth: 1.5,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                          ),
                          // Lower Bound
                          LineChartBarData(
                            spots: forecastData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['lower'] as num).toDouble() / 1000)).toList(),
                            isCurved: true,
                            color: _getScenarioColor(_scenario).withOpacity(0.4),
                            barWidth: 1.5,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Projected Months Table List
            Text("Monthly Predictive Breakdown", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...forecastData.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: CustomCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['period'], style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text("Bounds: ₹${(item['lower'] / 1000).toStringAsFixed(0)}K - ₹${(item['upper'] / 1000).toStringAsFixed(0)}K", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        Text(
                          "₹${NumberFormat('#,##,##0').format(item['predicted'])}",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: _getScenarioColor(_scenario)),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioTab(String name, Color color) {
    final isSelected = _scenario == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _scenario = name),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Color _getScenarioColor(String scenario) {
    if (scenario == "Pessimistic") return AppColors.danger;
    if (scenario == "Optimistic") return AppColors.success;
    return AppColors.primary;
  }

  List<Map<String, dynamic>> _getForecastData(String timeframe, String scenario) {
    int count = 6;
    if (timeframe == "1 Month") count = 1;
    if (timeframe == "3 Months") count = 3;
    if (timeframe == "12 Months") count = 12;

    double mult = 1.0;
    if (scenario == "Pessimistic") mult = 0.88;
    if (scenario == "Optimistic") mult = 1.15;

    double base = 345000;
    List<Map<String, dynamic>> list = [];
    List<String> months = ["Aug 2026", "Sep 2026", "Oct 2026", "Nov 2026", "Dec 2026", "Jan 2027", "Feb 2027", "Mar 2027", "Apr 2027", "May 2027", "Jun 2027", "Jul 2027"];

    for (int i = 0; i < count; i++) {
      base += (75000 * mult);
      list.add({
        "period": months[i % 12],
        "predicted": base,
        "lower": base * 0.92,
        "upper": base * 1.08,
      });
    }
    return list;
  }
}
