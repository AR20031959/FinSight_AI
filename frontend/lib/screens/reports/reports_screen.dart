import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/pdf_report_modal.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _isDownloadingPdf = false;
  bool _isDownloadingExcel = false;
  bool _isDownloadingImage = false;

  Future<void> _downloadReport(String format) async {
    setState(() {
      if (format == 'pdf') _isDownloadingPdf = true;
      if (format == 'excel') _isDownloadingExcel = true;
      if (format == 'image') _isDownloadingImage = true;
    });

    String endpoint = "/reports/pdf";
    String ext = "pdf";
    String formatName = "PDF Report";

    if (format == 'excel') {
      endpoint = "/reports/excel";
      ext = "xlsx";
      formatName = "Excel Spreadsheet";
    } else if (format == 'image') {
      endpoint = "/reports/image";
      ext = "png";
      formatName = "PNG Infographic Image";
    }

    final now = DateTime.now();
    final sStr = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    final eStr = DateFormat('yyyy-MM-dd').format(now);

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

      final bytes = await ApiClient.getBytes(
        endpoint,
        queryParams: {"start_date": sStr, "end_date": eStr},
      );

      final dir = await getApplicationDocumentsDirectory();

      if (bytes != null && bytes.isNotEmpty) {
        final cleanExt = ext.replaceAll('.', '');
        final filename = "FinSight_Report_${sStr}_to_$eStr.$cleanExt";
        final file = File("${dir.path}/$filename");
        await file.writeAsBytes(bytes);

        if (mounted) {
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
        // Offline Fallback: Generate Local CSV Financial Ledger directly on device storage
        final financeState = ref.read(financeProvider);
        final txs = financeState.transactions;
        final csvContent = StringBuffer();
        csvContent.writeln("ID,Date,Title,Category,Type,Amount (INR),Merchant,Is Recurring");
        for (var t in txs) {
          csvContent.writeln('${t.id},${t.date},"${t.title.replaceAll('"', '""')}",${t.category},${t.type},${t.amount},"${(t.merchant ?? '').replaceAll('"', '""')}",${t.isRecurring}');
        }
        final filename = "FinSight_Local_Ledger_${sStr}_to_$eStr.csv";
        final file = File("${dir.path}/$filename");
        await file.writeAsString(csvContent.toString());

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Offline Financial Ledger ready: $filename",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              action: SnackBarAction(
                label: "OPEN CSV",
                textColor: Colors.amber,
                onPressed: () => OpenFile.open(file.path),
              ),
              duration: const Duration(seconds: 7),
              behavior: SnackBarBehavior.floating,
            ),
          );
          OpenFile.open(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Report Error: $e", maxLines: 2, overflow: TextOverflow.ellipsis),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 7),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPdf = false;
          _isDownloadingExcel = false;
          _isDownloadingImage = false;
        });
      }
    }
  }

  void _openCustomReportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PdfReportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Financial Reports Hub", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: AppColors.primary),
            tooltip: "Custom Date Filter",
            onPressed: _openCustomReportModal,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.summarize_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Export Statements & Ledgers", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text("Download secure executive reports in PDF, Excel, or PNG formats.", style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _openCustomReportModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Filter Range", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PDF Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text("Executive PDF Report", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Includes executive summary metrics, financial health score assessment, and formatted activity ledger.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDownloadingPdf ? null : () => _downloadReport('pdf'),
                    icon: _isDownloadingPdf
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded, color: Colors.white),
                    label: Text(_isDownloadingPdf ? "Generating PDF..." : "Download PDF Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Excel Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.table_chart_rounded, size: 48, color: AppColors.success),
                  const SizedBox(height: 12),
                  Text("Excel Data Ledger (.xlsx)", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Export raw transactions, category totals, and merchant records directly to a formatted Excel spreadsheet.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDownloadingExcel ? null : () => _downloadReport('excel'),
                    icon: _isDownloadingExcel
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.table_rows_rounded, color: Colors.white),
                    label: Text(_isDownloadingExcel ? "Exporting Excel..." : "Export Excel Ledger", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PNG Infographic Card
            CustomCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.image_rounded, size: 48, color: AppColors.secondary),
                  const SizedBox(height: 12),
                  Text("PNG Visual Infographic Image", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("High-resolution graphic dashboard image with spending category charts and key metric badges.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isDownloadingImage ? null : () => _downloadReport('image'),
                    icon: _isDownloadingImage
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.image_search_rounded, color: Colors.white),
                    label: Text(_isDownloadingImage ? "Rendering Image..." : "Generate PNG Infographic", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
