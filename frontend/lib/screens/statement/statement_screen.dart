import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_card.dart';

class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  bool _isAnalyzing = false;
  bool _isImporting = false;
  Map<String, dynamic>? _analysisResult;

  void _pickAndAnalyzeFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'csv', 'xlsx', 'xls', 'png', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _isAnalyzing = true;
      });

      // Simulate backend OCR parsing
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isAnalyzing = false;
        _analysisResult = {
          "filename": result.files.single.name,
          "total_parsed": 10,
          "detected_merchants": ["Tech Corp", "Swiggy", "Amazon", "Netflix", "HPCL", "HDFC Bank", "Zerodha", "HDFC AMC", "Apollo", "Airtel"],
          "parsed_transactions": [
            {"title": "Tech Corp Monthly Salary Credit", "amount": 150000.0, "type": "income", "category": "Salary", "date": "2026-07-01", "merchant": "Tech Corp", "is_recurring": true},
            {"title": "Swiggy Food Order #482", "amount": 420.0, "type": "expense", "category": "Food & Dining", "date": "2026-07-02", "merchant": "Swiggy", "is_recurring": false},
            {"title": "Amazon Electronics Purchase", "amount": 3499.0, "type": "expense", "category": "Shopping", "date": "2026-07-04", "merchant": "Amazon", "is_recurring": false},
            {"title": "Netflix Premium Subscription", "amount": 649.0, "type": "expense", "category": "Subscriptions", "date": "2026-07-05", "merchant": "Netflix", "is_recurring": true},
            {"title": "HPCL Petrol Pump Fuel", "amount": 2000.0, "type": "expense", "category": "Travel & Transport", "date": "2026-07-08", "merchant": "HPCL", "is_recurring": false},
            {"title": "Home Loan EMI HDFC", "amount": 24500.0, "type": "expense", "category": "EMI & Loans", "date": "2026-07-10", "merchant": "HDFC Bank", "is_recurring": true},
            {"title": "Zerodha Nifty Index SIP", "amount": 20000.0, "type": "investment", "category": "Mutual Funds / SIP", "date": "2026-07-12", "merchant": "Zerodha", "is_recurring": true},
            {"title": "HDFC Bluechip Equity Fund", "amount": 10000.0, "type": "investment", "category": "Stocks & Equities", "date": "2026-07-14", "merchant": "HDFC AMC", "is_recurring": true},
            {"title": "Apollo Pharmacy Medicines", "amount": 890.0, "type": "expense", "category": "Medical & Health", "date": "2026-07-15", "merchant": "Apollo Pharmacy", "is_recurring": false},
            {"title": "Airtel Broadband Fiber", "amount": 1179.0, "type": "expense", "category": "Utilities", "date": "2026-07-18", "merchant": "Airtel", "is_recurring": true},
          ],
          "recurring_payments": [
            {"title": "Netflix Premium Subscription", "amount": 649.0, "category": "Subscriptions", "date": "2026-07-05"},
            {"title": "Airtel Broadband Fiber", "amount": 1179.0, "category": "Utilities", "date": "2026-07-18"},
            {"title": "Zerodha Nifty SIP", "amount": 20000.0, "category": "Mutual Funds / SIP", "date": "2026-07-12"},
          ],
          "duplicate_charges": [
            {"title": "Uber Auto Ride", "amount": 185.0, "reason": "Double charged within 2 minutes", "date": "2026-07-14"},
          ]
        };
      });
    }
  }

  void _importTransactions() async {
    if (_analysisResult == null || _analysisResult!['parsed_transactions'] == null) return;
    
    setState(() => _isImporting = true);
    final txs = List<Map<String, dynamic>>.from(_analysisResult!['parsed_transactions']);
    
    await ref.read(financeProvider.notifier).importStatementTransactions(txs);
    
    setState(() => _isImporting = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success! ${txs.length} statement activities imported to your account ledger.", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/expense');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Link Bank Statement & OCR", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Banner Box
            CustomCard(
              padding: const EdgeInsets.all(24),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Upload Bank Statement / Receipt",
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Supports PDF, CSV, Excel & Receipt Images",
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickAndAnalyzeFile,
                    icon: _isAnalyzing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.description_rounded, color: Colors.white),
                    label: Text(
                      _isAnalyzing ? "Analyzing Document..." : "Select Statement File",
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_analysisResult != null) ...[
              // Parsed Summary Header & Import Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Analysis Results", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                  ElevatedButton.icon(
                    onPressed: _isImporting ? null : _importTransactions,
                    icon: _isImporting 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                    label: Text(_isImporting ? "Importing..." : "Import to Account", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("File Processed:", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        Text(_analysisResult!['filename'], style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Transactions Parsed:", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        Text("${_analysisResult!['total_parsed']} entries", style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Duplicate Warnings Banner
              if ((_analysisResult!['duplicate_charges'] as List).isNotEmpty) ...[
                CustomCard(
                  color: AppColors.danger.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                          const SizedBox(width: 8),
                          Text("Duplicate Charge Alerts Detected", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...(_analysisResult!['duplicate_charges'] as List).map((dup) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dup['title'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text(dup['reason'], style: GoogleFonts.inter(fontSize: 11, color: AppColors.danger)),
                                  ],
                                ),
                                Text("₹${dup['amount']}", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.danger)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Recurring Payments
              Text("Recurring Payments & Subscriptions", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(_analysisResult!['recurring_payments'] as List).map((rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: CustomCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.autorenew_rounded, color: AppColors.secondary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rec['title'], style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                                Text("Category: ${rec['category']} | Date: ${rec['date']}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Text("₹${rec['amount']}/mo", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
