import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_card.dart';

class EnterpriseDashboardScreen extends ConsumerStatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  ConsumerState<EnterpriseDashboardScreen> createState() => _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends ConsumerState<EnterpriseDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _clients = [];
  String _errorMessage = "";

  // Selected Client Account Dropdown Tile state
  int? _selectedClientId;
  bool _isLoadingSelectedClient = false;
  Map<String, dynamic>? _selectedClientDashboard;
  bool _showSelectedClientPasscode = false;

  // Controllers for Add Client Modal
  final _clientNameController = TextEditingController();
  final _clientEmailController = TextEditingController();
  final _clientPasscodeController = TextEditingController();

  // Controllers for Injecting Client Fund / Transaction
  final _txTitleController = TextEditingController();
  final _txAmountController = TextEditingController();
  String _txType = "investment";
  String _txCategory = "Mutual Funds";

  // Map to track password visibility toggles per client
  final Map<int, bool> _showPasscodeMap = {};

  @override
  void initState() {
    super.initState();
    _fetchEnterpriseData();
  }

  Future<void> _fetchEnterpriseData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final dashRes = await ApiClient.get('/enterprise/dashboard');
      final clientsRes = await ApiClient.get('/enterprise/clients');

      if (dashRes != null) {
        setState(() {
          _dashboardData = dashRes;
          _clients = (clientsRes is List) ? clientsRes : [];
          _isLoading = false;
        });

        if (_selectedClientId != null) {
          _fetchSelectedClientDashboard(_selectedClientId);
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load Enterprise Advisor Portal. Please check credentials.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Enterprise Portal API Error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSelectedClientDashboard(int? clientId) async {
    setState(() {
      _selectedClientId = clientId;
    });

    if (clientId == null) {
      setState(() {
        _selectedClientDashboard = null;
        _isLoadingSelectedClient = false;
      });
      return;
    }

    setState(() {
      _isLoadingSelectedClient = true;
    });

    try {
      final res = await ApiClient.get('/enterprise/clients/$clientId/dashboard');
      if (mounted) {
        setState(() {
          _selectedClientDashboard = (res is Map) ? res as Map<String, dynamic> : null;
          _isLoadingSelectedClient = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSelectedClient = false;
        });
      }
    }
  }

  // Dialog to Add a New Client (with Name, Email, and Passcode)
  void _showAddClientDialog() {
    _clientNameController.clear();
    _clientEmailController.clear();
    _clientPasscodeController.clear();
    bool obscurePasscode = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text("Register New Client", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create a client account under your enterprise practice. Client credentials and passcodes will be accessible in your roster.",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _clientNameController,
                  decoration: InputDecoration(
                    labelText: "Client Full Name",
                    hintText: "John Doe",
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _clientEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Client Email Address",
                    hintText: "client@example.com",
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _clientPasscodeController,
                  obscureText: obscurePasscode,
                  decoration: InputDecoration(
                    labelText: "Client Access Passcode",
                    hintText: "Set client passcode",
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePasscode ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                      onPressed: () => setDialogState(() => obscurePasscode = !obscurePasscode),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final name = _clientNameController.text.trim();
                final email = _clientEmailController.text.trim();
                final pass = _clientPasscodeController.text.trim();

                if (name.isEmpty || email.isEmpty || pass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in Client Name, Email, and Passcode.")),
                  );
                  return;
                }

                final res = await ApiClient.post('/enterprise/clients/create', {
                  'full_name': name,
                  'email': email,
                  'password': pass,
                });

                if (mounted) {
                  Navigator.pop(ctx);
                  if (res != null && res['client'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Client '${name}' registered successfully! Passcode saved."),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _fetchEnterpriseData();
                  } else {
                    final err = (res != null && res['error'] != null) ? res['error'] : "Failed to create client.";
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err.toString()), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Register Client", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Modal to Inspect Client Financial Activities & Manage Funds
  void _showInspectClientModal(Map<String, dynamic> client) async {
    final clientId = client['client_id'];
    final clientName = client['full_name'] ?? 'Client';
    final clientEmail = client['email'] ?? '';
    final passcode = client['passcode'] ?? '••••••••';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientPortfolioBottomSheet(
        clientId: clientId,
        clientName: clientName,
        clientEmail: clientEmail,
        passcode: passcode,
        onRefreshNeeded: _fetchEnterpriseData,
      ),
    );
  }

  // Quick Action: Inject Fund / Investment on behalf of Client
  void _showInjectFundDialog(int clientId, String clientName) {
    _txTitleController.text = "Strategic Wealth Allocation";
    _txAmountController.clear();
    _txType = "investment";
    _txCategory = "Mutual Funds";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Manage Funds for $clientName", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Inject wealth investment, income dividend, or financial activity directly into $clientName's managed account.",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _txTitleController,
                  decoration: const InputDecoration(
                    labelText: "Transaction Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _txAmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount (INR)",
                    prefixText: "₹ ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _txType,
                  decoration: const InputDecoration(labelText: "Activity Type", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "investment", child: Text("Investment (Wealth Growth)")),
                    DropdownMenuItem(value: "income", child: Text("Income / Dividend Credit")),
                    DropdownMenuItem(value: "savings", child: Text("Savings Allocation")),
                    DropdownMenuItem(value: "expense", child: Text("Expense Payment")),
                  ],
                  onChanged: (val) => setDialogState(() => _txType = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _txCategory,
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: "Mutual Funds", child: Text("Mutual Funds / Equity SIP")),
                    DropdownMenuItem(value: "Stocks & ETFs", child: Text("Stocks & ETFs")),
                    DropdownMenuItem(value: "Fixed Income", child: Text("Fixed Income & FDs")),
                    DropdownMenuItem(value: "Real Estate", child: Text("Real Estate Fund")),
                    DropdownMenuItem(value: "Salary", child: Text("Salary / Regular Income")),
                    DropdownMenuItem(value: "Other Expense", child: Text("Other Activity")),
                  ],
                  onChanged: (val) => setDialogState(() => _txCategory = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final title = _txTitleController.text.trim();
                final amt = double.tryParse(_txAmountController.text.trim()) ?? 0.0;

                if (title.isEmpty || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter a valid title and amount.")),
                  );
                  return;
                }

                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                final res = await ApiClient.post('/enterprise/clients/$clientId/transactions', {
                  'title': title,
                  'amount': amt,
                  'type': _txType,
                  'category': _txCategory,
                  'date': today,
                  'merchant': 'Managed by Enterprise Advisor',
                  'note': 'Fund managed by Enterprise Financial Advisor',
                });

                if (mounted) {
                  Navigator.pop(ctx);
                  if (res != null && res['id'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Successfully allocated ₹${amt.toStringAsFixed(0)} to $clientName's portfolio!"),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _fetchEnterpriseData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to allocate fund."), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              child: Text("Allocate Fund", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Download Client PDF / Excel / PNG Report
  Future<void> _downloadClientReport(int clientId, String clientName, String format) async {
    String ext = format == 'excel' ? 'xlsx' : (format == 'image' ? 'png' : 'pdf');
    String endpoint = "/enterprise/clients/$clientId/reports/pdf";
    if (format == 'excel') endpoint = "/enterprise/clients/$clientId/reports/excel";
    if (format == 'image') endpoint = "/enterprise/clients/$clientId/reports/image";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Generating $format report for $clientName... Please wait.")),
    );

    final bytes = await ApiClient.getBytes(endpoint);
    if (bytes != null && bytes.isNotEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final filename = "Client_${clientName.replaceAll(' ', '_')}_Report.$ext";
      final file = File("${dir.path}/$filename");
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Report ready: $filename"),
            action: SnackBarAction(label: "OPEN FILE", textColor: Colors.amber, onPressed: () => OpenFile.open(file.path)),
            duration: const Duration(seconds: 7),
          ),
        );
        OpenFile.open(file.path);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to generate report."), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Enterprise Advisor Portal", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchEnterpriseData,
            tooltip: "Refresh Practice Data",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined, size: 56, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.redAccent)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchEnterpriseData, child: const Text("Retry"))
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enterprise Header Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.5), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.workspace_premium_rounded, color: AppColors.secondary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dashboardData?["enterprise_name"] ?? "Wealth Management Practice",
                                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        "Senior Advisor: ${authState.fullName} (${authState.email})",
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text("FINANCIAL ADVISOR", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Advisor Client Control Active: Manage client accounts, access credentials, and wealth growth portfolios.",
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Practice Aggregated Metrics Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 720;
                          final agg = _dashboardData?["aggregated_metrics"] ?? {};

                          final cards = [
                            _buildEnterpriseMetricCard("Managed Clients", "${_clients.length}", Icons.people_outline_rounded, AppColors.primary),
                            _buildEnterpriseMetricCard("Client Total Income", currencyFormat.format(agg["total_income"] ?? 0), Icons.arrow_upward_rounded, AppColors.success),
                            _buildEnterpriseMetricCard("Client Expenses", currencyFormat.format(agg["total_expense"] ?? 0), Icons.arrow_downward_rounded, AppColors.danger),
                            _buildEnterpriseMetricCard("Client Wealth Growth", currencyFormat.format(agg["total_investments"] ?? 0), Icons.trending_up_rounded, AppColors.secondary),
                          ];

                          return isWide
                              ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList())
                              : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
                        },
                      ),
                      const SizedBox(height: 20),

                      // Selected Client Account Dropdown Tile & Analytics Section
                      _buildClientAccountDropdownTile(),
                      const SizedBox(height: 20),

                      // Client Management & Roster Section
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.badge_rounded, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Text("Managed Client Accounts & Roster", style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showAddClientDialog,
                                  icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                                  label: Text("Add Client", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (_clients.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.folder_open_rounded, size: 44, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(
                                        "No client accounts in your practice yet.",
                                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: _showAddClientDialog,
                                        icon: const Icon(Icons.person_add_rounded, size: 16),
                                        label: const Text("Register First Client"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _clients.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final client = _clients[idx];
                                  final cId = client['client_id'] ?? idx;
                                  final showPass = _showPasscodeMap[cId] ?? false;
                                  final passcodeStr = client['passcode'] ?? '••••••••';
                                  final finSummary = client['financial_summary'] ?? {};
                                  final cIncome = (finSummary['monthly_income'] ?? 0.0) as num;
                                  final cInvest = (finSummary['total_investments'] ?? 0.0) as num;
                                  final cHealth = (finSummary['health_score'] ?? 0.0) as num;

                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppColors.primary.withOpacity(0.15),
                                              child: Text(
                                                (client['full_name'] ?? 'C')[0].toUpperCase(),
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    client['full_name'] ?? 'Client',
                                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  Text(
                                                    client['email'] ?? '',
                                                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.success.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "HEALTH ${cHealth.toStringAsFixed(1)}/100",
                                                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                              ),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Access Passcode Row for Financial Advisor
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.key_rounded, size: 16, color: AppColors.secondary),
                                              const SizedBox(width: 8),
                                              Text("Passcode: ", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text(
                                                showPass ? passcodeStr : '••••••••',
                                                style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.secondary),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () {
                                                  setState(() {
                                                    _showPasscodeMap[cId] = !showPass;
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: passcodeStr));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Passcode copied to clipboard!")),
                                                  );
                                                },
                                                child: Text("COPY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                              )
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Financial Snapshot Metrics
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text("Income: ₹${cIncome.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                                            Text("Invested: ₹${cInvest.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w600)),
                                            Text("Joined: ${client['joined_at'] ?? '2026'}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Advisor Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showInspectClientModal(client),
                                                icon: const Icon(Icons.analytics_rounded, size: 16),
                                                label: const Text("Inspect Portfolio"),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: AppColors.primary),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showInjectFundDialog(cId, client['full_name'] ?? 'Client'),
                                                icon: const Icon(Icons.add_chart_rounded, size: 16, color: Colors.white),
                                                label: Text("Manage Funds", style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.secondary,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                                              onSelected: (val) => _downloadClientReport(cId, client['full_name'] ?? 'Client', val),
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: "pdf", child: Text("Download PDF Report")),
                                                const PopupMenuItem(value: "excel", child: Text("Download Excel Sheet")),
                                                const PopupMenuItem(value: "image", child: Text("Download PNG Infographic")),
                                              ],
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEnterpriseMetricCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  // Dropdown Tile for Account Selection & Dedicated Client Analytics
  Widget _buildClientAccountDropdownTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Client Analytics & Financial Operations",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Select a client account from the dropdown tile to inspect individual analytics and put financial activities.",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdown Tile Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _selectedClientId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 28),
                hint: Text("Select Client Account...", style: GoogleFonts.inter(fontSize: 14)),
                dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Row(
                      children: [
                        const Icon(Icons.apartment_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          "🏢 All Clients (Practice Aggregate Summary)",
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ..._clients.map((c) {
                    final cId = c['client_id'] as int;
                    final cName = c['full_name'] ?? 'Client';
                    final cEmail = c['email'] ?? '';
                    return DropdownMenuItem<int?>(
                      value: cId,
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, color: AppColors.secondary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "👤 $cName  ($cEmail)",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (val) {
                  _fetchSelectedClientDashboard(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selection State Content Panel
          if (_selectedClientId == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Currently displaying Practice Aggregate Summary. Select an individual client account from the dropdown tile above to switch to individual client analytics and manage their financial activities.",
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isLoadingSelectedClient) ...[
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (_selectedClientDashboard != null) ...[
            _buildSelectedClientAnalyticsPanel(),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Unable to load analytics for selected client.",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSelectedClientAnalyticsPanel() {
    final dash = _selectedClientDashboard!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Find client details from _clients
    final clientInfo = _clients.firstWhere(
      (c) => c['client_id'] == _selectedClientId,
      orElse: () => <String, dynamic>{},
    );

    final clientName = clientInfo['full_name'] ?? 'Client';
    final clientEmail = clientInfo['email'] ?? '';
    final clientPasscode = clientInfo['passcode'] ?? '••••••••';
    final healthScore = (dash['health_score'] ?? 0.0) as num;

    final income = (dash['monthly_income'] ?? 0.0) as num;
    final expense = (dash['monthly_expense'] ?? 0.0) as num;
    final investments = (dash['total_investments'] ?? 0.0) as num;
    final balance = (dash['total_balance'] ?? 0.0) as num;

    final insights = (dash['ai_insights'] as List? ?? []);
    final recentTxs = (dash['recent_transactions'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(),
        const SizedBox(height: 12),

        // Selected Client Identity & Access Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary,
                    child: Text(
                      clientName[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        Text(
                          clientEmail,
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "HEALTH ${healthScore.toStringAsFixed(1)}/100",
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.key_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text("Passcode: ", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(
                    _showSelectedClientPasscode ? clientPasscode : '••••••••',
                    style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  IconButton(
                    icon: Icon(_showSelectedClientPasscode ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16, color: AppColors.secondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _showSelectedClientPasscode = !_showSelectedClientPasscode;
                      });
                    },
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: clientPasscode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Client passcode copied to clipboard!")),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: AppColors.secondary),
                        const SizedBox(width: 4),
                        Text("COPY PASSCODE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Metrics Grid for Selected Client
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final statCards = [
              _buildMiniStatCard("Monthly Income", currencyFormat.format(income), Icons.arrow_upward_rounded, AppColors.success),
              _buildMiniStatCard("Monthly Expense", currencyFormat.format(expense), Icons.arrow_downward_rounded, AppColors.danger),
              _buildMiniStatCard("Investments", currencyFormat.format(investments), Icons.trending_up_rounded, AppColors.secondary),
              _buildMiniStatCard("Net Balance", currencyFormat.format(balance), Icons.account_balance_wallet_rounded, AppColors.primary),
            ];

            return isWide
                ? Row(children: statCards.map((sc) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: sc))).toList())
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: statCards,
                  );
          },
        ),
        const SizedBox(height: 16),

        // Action Buttons: Put Financial Activity & Reports
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showInjectFundDialog(_selectedClientId!, clientName),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
              label: Text(
                "Put Financial Activity / Manage Funds",
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadClientReport(_selectedClientId!, clientName, "pdf"),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.redAccent),
              label: Text("PDF Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadClientReport(_selectedClientId!, clientName, "excel"),
              icon: const Icon(Icons.table_chart_rounded, size: 16, color: AppColors.success),
              label: Text("Excel Sheet", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadClientReport(_selectedClientId!, clientName, "image"),
              icon: const Icon(Icons.image_rounded, size: 16, color: AppColors.primary),
              label: Text("PNG Infographic", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // AI Advisory Insights
        Text(
          "AI Strategic Advisory Insights for $clientName",
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var item in insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.toString(),
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Financial Activities List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Client Financial Activities",
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              "${recentTxs.length} Activities",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (recentTxs.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "No financial activities recorded for this client yet. Click 'Put Financial Activity' above to record one.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTxs.length > 5 ? 5 : recentTxs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final tx = recentTxs[idx];
                final tType = (tx['type'] ?? 'expense').toString().toLowerCase();
                final isIncome = tType == 'income';
                final isInvest = tType == 'investment' || tType == 'savings';
                final amt = (tx['amount'] ?? 0.0) as num;

                final color = isIncome ? AppColors.success : (isInvest ? AppColors.secondary : AppColors.danger);
                final icon = isIncome ? Icons.add_circle_outline_rounded : (isInvest ? Icons.trending_up_rounded : Icons.remove_circle_outline_rounded);

                return ListTile(
                  dense: true,
                  leading: Icon(icon, color: color, size: 20),
                  title: Text(tx['title'] ?? 'Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("${tx['category'] ?? ''} • ${tx['date'] ?? ''}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    "${isIncome ? '+' : (isInvest ? '⚡ ' : '-')}₹${amt.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet to Inspect Client Portfolio & Wealth Growth Activities
class _ClientPortfolioBottomSheet extends StatefulWidget {
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String passcode;
  final VoidCallback onRefreshNeeded;

  const _ClientPortfolioBottomSheet({
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.passcode,
    required this.onRefreshNeeded,
  });

  @override
  State<_ClientPortfolioBottomSheet> createState() => _ClientPortfolioBottomSheetState();
}

class _ClientPortfolioBottomSheetState extends State<_ClientPortfolioBottomSheet> {
  bool _loading = true;
  Map<String, dynamic>? _clientDash;

  @override
  void initState() {
    super.initState();
    _loadClientDashboard();
  }

  Future<void> _loadClientDashboard() async {
    final res = await ApiClient.get('/enterprise/clients/${widget.clientId}/dashboard');
    if (mounted) {
      setState(() {
        _clientDash = (res is Map) ? res as Map<String, dynamic> : null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clientDash == null
              ? const Center(child: Text("Unable to load client portfolio."))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Client Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(widget.clientName[0], style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.clientName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text("Email: ${widget.clientEmail}  •  Passcode: ${widget.passcode}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metrics Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniMetric("Income", "₹${(_clientDash!['monthly_income'] ?? 0.0).toStringAsFixed(0)}", AppColors.success),
                            _buildMiniMetric("Expenses", "₹${(_clientDash!['monthly_expense'] ?? 0.0).toStringAsFixed(0)}", AppColors.danger),
                            _buildMiniMetric("Investments", "₹${(_clientDash!['total_investments'] ?? 0.0).toStringAsFixed(0)}", AppColors.secondary),
                            _buildMiniMetric("Health", "${_clientDash!['health_score'] ?? 0.0}/100", AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Advisory Insights for Client
                      Text("AI Strategic Advisor Assessment", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var insight in (_clientDash!['ai_insights'] as List? ?? ["Portfolio actively monitored."]))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text("• $insight", style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Client Investment Goals
                      Text("Managed Wealth Growth Goals", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if ((_clientDash!['investment_goals'] as List? ?? []).isEmpty) ...[
                        Text("No active wealth growth goals set for this client yet.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                      ] else ...[
                        for (var goal in (_clientDash!['investment_goals'] as List))
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.flag_rounded, color: AppColors.secondary),
                              title: Text(goal['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                              subtitle: Text("Target: ₹${goal['target_amount']}  •  SIP: ₹${goal['monthly_sip']}/mo"),
                              trailing: Text("Risk: ${goal['risk_level']}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
