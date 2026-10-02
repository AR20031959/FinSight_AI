import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  List<dynamic> _members = [];
  String _errorMessage = "";

  final _inviteEmailController = TextEditingController();

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
      final membRes = await ApiClient.get('/enterprise/members');

      if (dashRes != null) {
        setState(() {
          _dashboardData = dashRes;
          _members = (membRes is List) ? membRes : [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Failed to load Enterprise Dashboard. Verify enterprise credentials.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Enterprise API Error: $e";
        _isLoading = false;
      });
    }
  }

  void _showInviteMemberModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Associate Enterprise Member", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter user email to authorize and associate them with your Enterprise Account:",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "employee@company.com",
                labelText: "Member Email",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final email = _inviteEmailController.text.trim();
              if (email.isNotEmpty) {
                final res = await ApiClient.post('/enterprise/members/invite?email=${Uri.encodeComponent(email)}', {});
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res != null && res['message'] != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message']), backgroundColor: AppColors.success),
                    );
                    _fetchEnterpriseData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to associate member. User not found."), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Associate Member", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text("Enterprise Decision Intelligence", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _fetchEnterpriseData,
            tooltip: "Refresh Enterprise Metrics",
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
                        const Icon(Icons.security_rounded, size: 56, color: Colors.redAccent),
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
                                  child: const Icon(Icons.business_center_rounded, color: AppColors.secondary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dashboardData?["enterprise_name"] ?? "Enterprise Account",
                                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        "Enterprise Administrator: ${authState.fullName} (${authState.email})",
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
                                  child: Text("ENTERPRISE ROLE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                )
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 16, color: AppColors.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _dashboardData?["privacy_compliance_notice"] ?? "Privacy Compliance: Aggregated Data Only",
                                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Metrics Cards Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 720;
                          final agg = _dashboardData?["aggregated_metrics"] ?? {};

                          final cards = [
                            _buildEnterpriseMetricCard("Total Associated Members", "${_dashboardData?['total_members'] ?? 0}", Icons.group_rounded, AppColors.primary),
                            _buildEnterpriseMetricCard("Aggregate Income", currencyFormat.format(agg["total_income"] ?? 0), Icons.arrow_upward_rounded, AppColors.success),
                            _buildEnterpriseMetricCard("Aggregate Expenses", currencyFormat.format(agg["total_expense"] ?? 0), Icons.arrow_downward_rounded, AppColors.danger),
                            _buildEnterpriseMetricCard("Aggregate Investments", currencyFormat.format(agg["total_investments"] ?? 0), Icons.trending_up_rounded, AppColors.secondary),
                          ];

                          return isWide
                              ? Row(children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList())
                              : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList());
                        },
                      ),
                      const SizedBox(height: 20),

                      // Member Authorization & Usage Analytics Card
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people_alt_rounded, color: AppColors.primary),
                                    const SizedBox(width: 10),
                                    Text("Authorized Organization Members", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showInviteMemberModal,
                                  icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white),
                                  label: Text("Add Member", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (_members.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text("No authorized members associated with this enterprise yet. Tap 'Add Member' to associate accounts.", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                              ),
                            ] else ...[
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _members.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, idx) {
                                  final m = _members[idx];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.15),
                                      child: Text((m["full_name"] ?? "M")[0], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                    ),
                                    title: Text(m["full_name"] ?? "", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text("${m['email']}  •  Joined: ${m['joined_at']}", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text((m["member_role"] ?? "member").toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Audit & Platform Usage Stats Card
                      CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics_rounded, color: AppColors.secondary),
                                const SizedBox(width: 10),
                                Text("Enterprise AI & Report Observability", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ListTile(
                              leading: const Icon(Icons.psychology_rounded, color: AppColors.primary),
                              title: Text("Total AI Advisory Interactions", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              trailing: Text("${_dashboardData?['usage_statistics']?['total_ai_advisory_queries'] ?? 0}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.description_rounded, color: AppColors.success),
                              title: Text("Total Reports Generated", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              trailing: Text("${_dashboardData?['usage_statistics']?['reports_generated_count'] ?? 0}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.receipt_long_rounded, color: AppColors.warning),
                              title: Text("Transactions Tracked Across Enterprise", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                              trailing: Text("${_dashboardData?['usage_statistics']?['total_transactions_tracked'] ?? 0}", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
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
}
