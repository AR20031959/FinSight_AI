import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class PdfReportModal extends StatefulWidget {
  const PdfReportModal({super.key});

  @override
  State<PdfReportModal> createState() => _PdfReportModalState();
}

class _PdfReportModalState extends State<PdfReportModal> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedFormat = 'pdf'; // 'pdf', 'image', or 'excel'
  bool _isGenerating = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month, 1);
  }

  void _selectPreset(String preset) {
    final now = DateTime.now();
    setState(() {
      if (preset == 'this_month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (preset == 'last_30_days') {
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
      } else if (preset == 'last_month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        _startDate = lastMonth;
        _endDate = lastDayOfLastMonth;
      } else if (preset == 'year_to_date') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = "Connecting to FinSight AI Report Engine...";
    });

    final sStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final eStr = DateFormat('yyyy-MM-dd').format(_endDate);

    String endpoint = "/reports/pdf";
    String ext = "pdf";
    String formatName = "PDF Report";

    if (_selectedFormat == 'image') {
      endpoint = "/reports/image";
      ext = "png";
      formatName = "PNG Infographic Image";
    } else if (_selectedFormat == 'excel') {
      endpoint = "/reports/excel";
      ext = "xlsx";
      formatName = "Excel Spreadsheet";
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Generating $formatName ($sStr to $eStr)... Please wait."),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      setState(() {
        _statusMessage = "Rendering $formatName ($sStr to $eStr)...";
      });

      final bytes = await ApiClient.getBytes(
        endpoint,
        queryParams: {"start_date": sStr, "end_date": eStr},
      );

      if (bytes != null && bytes.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final cleanExt = ext.replaceAll('.', '');
        final filename = "FinSight_Report_${sStr}_to_$eStr.$cleanExt";
        final file = File("${dir.path}/$filename");
        await file.writeAsBytes(bytes);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$formatName ready: $filename",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              action: SnackBarAction(
                label: "OPEN FILE",
                textColor: Colors.amber,
                onPressed: () => OpenFile.open(file.path),
              ),
              duration: const Duration(seconds: 7),
              behavior: SnackBarBehavior.floating,
            ),
          );
          OpenFile.open(file.path);
        }
      } else {
        throw Exception("Failed to generate $formatName for selected dates.");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Report Generation Error: $e", maxLines: 2, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy');

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Generate Financial Report", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Select Export Format & Date Range", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Export Format Selector
            Text("Select Report Format", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  avatar: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.white),
                  label: Text("PDF", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  selected: _selectedFormat == 'pdf',
                  selectedColor: AppColors.primary,
                  onSelected: (selected) => setState(() => _selectedFormat = 'pdf'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.image_rounded, size: 16, color: Colors.white),
                  label: Text("PNG Image", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  selected: _selectedFormat == 'image',
                  selectedColor: AppColors.secondary,
                  onSelected: (selected) => setState(() => _selectedFormat = 'image'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: const Icon(Icons.table_chart_rounded, size: 16, color: Colors.white),
                  label: Text("Excel", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  selected: _selectedFormat == 'excel',
                  selectedColor: AppColors.success,
                  onSelected: (selected) => setState(() => _selectedFormat = 'excel'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Presets row
            Text("Quick Date Presets", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text("This Month", style: GoogleFonts.inter(fontSize: 11)),
                  onPressed: () => _selectPreset('this_month'),
                ),
                ActionChip(
                  label: Text("Last 30 Days", style: GoogleFonts.inter(fontSize: 11)),
                  onPressed: () => _selectPreset('last_30_days'),
                ),
                ActionChip(
                  label: Text("Last Month", style: GoogleFonts.inter(fontSize: 11)),
                  onPressed: () => _selectPreset('last_month'),
                ),
                ActionChip(
                  label: Text("Year-to-Date", style: GoogleFonts.inter(fontSize: 11)),
                  onPressed: () => _selectPreset('year_to_date'),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Date pickers row (From Date -> To Date)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("FROM DATE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(dateFormat.format(_startDate), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(16),
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("TO DATE", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 16, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Text(dateFormat.format(_endDate), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isGenerating) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_statusMessage ?? "Generating PDF...", style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _generateReport,
                icon: Icon(
                  _selectedFormat == 'image' ? Icons.image_rounded : (_selectedFormat == 'excel' ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded),
                  color: Colors.white,
                ),
                label: Text(
                  _selectedFormat == 'image'
                      ? "Generate & Open PNG Image Report"
                      : (_selectedFormat == 'excel' ? "Generate & Open Excel Sheet" : "Generate & Open PDF Report"),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedFormat == 'image' ? AppColors.secondary : (_selectedFormat == 'excel' ? AppColors.success : AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
