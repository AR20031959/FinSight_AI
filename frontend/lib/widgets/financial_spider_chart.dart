import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../models/summary_model.dart';
import 'custom_card.dart';

enum SpiderChartMode { healthPillars, spendingCategories }

class FinancialSpiderChart extends StatefulWidget {
  final DashboardSummaryModel summary;
  final bool compact;
  final String? title;

  const FinancialSpiderChart({
    super.key,
    required this.summary,
    this.compact = false,
    this.title,
  });

  @override
  State<FinancialSpiderChart> createState() => _FinancialSpiderChartState();
}

class _FinancialSpiderChartState extends State<FinancialSpiderChart> {
  SpiderChartMode _mode = SpiderChartMode.healthPillars;
  int? _selectedEntryIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = widget.summary;

    final titles = <String>[];
    final currentValues = <double>[];
    final targetValues = <double>[];
    final rawDescriptions = <String>[];

    if (_mode == SpiderChartMode.healthPillars) {
      // 1. Savings Score
      final double savingsScore = (summary.savingsRate.clamp(0.0, 50.0) / 50.0 * 100.0).clamp(10.0, 100.0);
      titles.add("Savings");
      currentValues.add(savingsScore);
      targetValues.add(75.0);
      rawDescriptions.add("${summary.savingsRate.toStringAsFixed(1)}% savings rate");

      // 2. Investment Score
      final double invRatio = summary.monthlyIncome > 0
          ? (summary.totalInvestments / summary.monthlyIncome * 100.0)
          : (summary.totalInvestments > 0 ? 50.0 : 5.0);
      final double invScore = (invRatio.clamp(0.0, 30.0) / 30.0 * 100.0).clamp(10.0, 100.0);
      titles.add("Investments");
      currentValues.add(invScore);
      targetValues.add(70.0);
      rawDescriptions.add("₹${summary.totalInvestments.toStringAsFixed(0)} allocated");

      // 3. Expense Control
      final double expRatio = summary.monthlyIncome > 0
          ? (summary.monthlyExpense / summary.monthlyIncome * 100.0)
          : 100.0;
      final double expScore = (100.0 - (expRatio * 0.7)).clamp(15.0, 100.0);
      titles.add("Expense Ctrl");
      currentValues.add(expScore);
      targetValues.add(80.0);
      rawDescriptions.add("${expRatio.toStringAsFixed(1)}% spend ratio");

      // 4. Debt Safety
      final double debtAmount = summary.categoryBreakdown['EMI'] ?? 0.0;
      final double debtRatio = summary.monthlyIncome > 0 ? (debtAmount / summary.monthlyIncome * 100.0) : 0.0;
      final double debtScore = (100.0 - (debtRatio * 2.0)).clamp(20.0, 100.0);
      titles.add("Debt Safety");
      currentValues.add(debtScore);
      targetValues.add(85.0);
      rawDescriptions.add(debtRatio > 0 ? "${debtRatio.toStringAsFixed(1)}% EMI ratio" : "No debt recorded");

      // 5. Emergency Runway
      final double essential = (summary.monthlyExpense > 0 ? summary.monthlyExpense : 1000.0);
      final double liquid = (summary.savings > 0 ? summary.savings : 0.0) + summary.totalInvestments;
      final double runwayMonths = liquid / essential;
      final double runwayScore = (runwayMonths / 6.0 * 100.0).clamp(10.0, 100.0);
      titles.add("Runway");
      currentValues.add(runwayScore);
      targetValues.add(80.0);
      rawDescriptions.add("${runwayMonths.toStringAsFixed(1)} mos buffer");

      // 6. Overall Health
      final double healthScore = summary.healthScore > 0 ? summary.healthScore.clamp(10.0, 100.0) : 25.0;
      titles.add("Health Score");
      currentValues.add(healthScore);
      targetValues.add(85.0);
      rawDescriptions.add("${summary.healthScore.toStringAsFixed(0)} / 100 radial");
    } else {
      // Spending Categories Mode
      final catBreakdown = summary.categoryBreakdown;
      List<MapEntry<String, double>> topCats = catBreakdown.entries.toList();
      topCats.sort((a, b) => b.value.compareTo(a.value));

      if (topCats.length < 3) {
        // Fallback default buckets to guarantee >= 3 axes
        final defaultBuckets = ["Food & Dining", "Rent & Housing", "Travel", "Entertainment", "Utilities", "Other"];
        for (var b in defaultBuckets) {
          if (!topCats.any((e) => e.key == b)) {
            topCats.add(MapEntry(b, 500.0));
          }
        }
      }

      final selectedEntries = topCats.take(6).toList();
      final double maxVal = selectedEntries.map((e) => e.value).fold(0.0, max);

      for (var e in selectedEntries) {
        // Format shortened label for radar vertex
        String shortName = e.key;
        if (shortName.contains("&")) {
          shortName = shortName.split("&")[0].trim();
        } else if (shortName.contains("/")) {
          shortName = shortName.split("/")[0].trim();
        }
        if (shortName.length > 12) {
          shortName = "${shortName.substring(0, 10)}..";
        }
        titles.add(shortName);

        final double score = maxVal > 0 ? (e.value / maxVal * 80.0 + 15.0).clamp(10.0, 100.0) : 30.0;
        currentValues.add(score);
        targetValues.add(50.0); // Balanced reference baseline
        rawDescriptions.add("₹${e.value.toStringAsFixed(0)}");
      }
    }

    final currentEntries = currentValues.map((v) => RadarEntry(value: v)).toList();
    final targetEntries = targetValues.map((v) => RadarEntry(value: v)).toList();

    return CustomCard(
      padding: EdgeInsets.all(widget.compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radar_rounded, color: Color(0xFF06B6D4), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.title ?? "Financial Spider Radar",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Compact mode toggler
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeBtn("Pillars", SpiderChartMode.healthPillars, isDark),
                    _buildModeBtn("Categories", SpiderChartMode.spendingCategories, isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend Row
          Row(
            children: [
              _buildLegendDot(const Color(0xFF06B6D4), "Current Data Profile", isDark),
              const SizedBox(width: 16),
              _buildLegendDot(const Color(0xFF10B981), "Ideal Target Baseline", isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Radar / Spider Chart Widget
          SizedBox(
            height: widget.compact ? 240 : 280,
            width: double.infinity,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  // Target Benchmark Dataset
                  RadarDataSet(
                    fillColor: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderColor: const Color(0xFF10B981).withValues(alpha: 0.6),
                    borderWidth: 1.6,
                    entryRadius: 2.5,
                    dataEntries: targetEntries,
                  ),
                  // Current Live Dataset
                  RadarDataSet(
                    fillColor: const Color(0xFF06B6D4).withValues(alpha: 0.28),
                    borderColor: const Color(0xFF06B6D4),
                    borderWidth: 2.4,
                    entryRadius: 4.0,
                    dataEntries: currentEntries,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                radarBorderData: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1.2,
                ),
                radarShape: RadarShape.polygon,
                tickCount: 3,
                ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
                tickBorderData: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  width: 1.0,
                ),
                gridBorderData: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                titlePositionPercentageOffset: 0.22,
                titleTextStyle: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
                getTitle: (index, angle) {
                  if (index >= 0 && index < titles.length) {
                    return RadarChartTitle(
                      text: titles[index],
                      angle: 0,
                    );
                  }
                  return const RadarChartTitle(text: '');
                },
                radarTouchData: RadarTouchData(
                  touchCallback: (FlTouchEvent event, response) {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSpot == null) {
                      setState(() => _selectedEntryIndex = null);
                      return;
                    }
                    setState(() {
                      _selectedEntryIndex = response.touchedSpot!.touchedRadarEntryIndex;
                    });
                  },
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 14),

          // Dimensions Breakdown Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(titles.length, (idx) {
              final isHighlighted = _selectedEntryIndex == idx;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighlighted
                        ? const Color(0xFF06B6D4)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    width: isHighlighted ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${titles[idx]}: ",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      rawDescriptions[idx],
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBtn(String label, SpiderChartMode mode, bool isDark) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
