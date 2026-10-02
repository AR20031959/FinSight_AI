import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_card.dart';

import 'package:intl/intl.dart';
import '../../providers/finance_provider.dart';
import '../../providers/ai_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _pushNotifications = true;
  String _selectedLanguage = "English";
  String _salaryPeriod = "monthly"; // "monthly" or "yearly"
  final _salaryController = TextEditingController();
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final financeState = ref.read(financeProvider);
      _salaryPeriod = financeState.salaryPeriod;
      final currentIncome = financeState.summary?.monthlyIncome ?? 0.0;
      if (currentIncome > 0) {
        if (_salaryPeriod == "yearly") {
          final yearlyVal = currentIncome * 12.0;
          _salaryController.text = yearlyVal % 1 == 0 ? yearlyVal.toInt().toString() : yearlyVal.toStringAsFixed(2);
        } else {
          _salaryController.text = currentIncome % 1 == 0 ? currentIncome.toInt().toString() : currentIncome.toStringAsFixed(2);
        }
      } else {
        _salaryController.text = "";
      }
      _isInit = true;
    }
  }

  void _onSalaryPeriodChanged(String newPeriod) {
    if (_salaryPeriod == newPeriod) return;
    final currentText = _salaryController.text.trim();
    final currentAmt = double.tryParse(currentText) ?? 0.0;

    setState(() {
      if (currentAmt > 0) {
        if (newPeriod == "yearly" && _salaryPeriod == "monthly") {
          final yearlyVal = currentAmt * 12.0;
          _salaryController.text = yearlyVal % 1 == 0 ? yearlyVal.toInt().toString() : yearlyVal.toStringAsFixed(2);
        } else if (newPeriod == "monthly" && _salaryPeriod == "yearly") {
          final monthlyVal = currentAmt / 12.0;
          _salaryController.text = monthlyVal % 1 == 0 ? monthlyVal.toInt().toString() : monthlyVal.toStringAsFixed(2);
        }
      }
      _salaryPeriod = newPeriod;
    });
  }

  void _saveSalaryDetails() {
    final amt = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    if (amt <= 0) return;

    ref.read(financeProvider.notifier).updatePrimarySalary(
      amount: amt,
      period: _salaryPeriod,
      title: _salaryPeriod == "yearly" ? "Tech Corp Annual Salary" : "Tech Corp Monthly Salary Credit",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _salaryPeriod == "yearly"
              ? "Yearly Salary updated to ₹${NumberFormat('#,##,##0').format(amt)} (Monthly: ₹${NumberFormat('#,##,##0').format(amt / 12)})"
              : "Monthly Salary updated to ₹${NumberFormat('#,##,##0').format(amt)} (Annual: ₹${NumberFormat('#,##,##0').format(amt * 12)})",
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final inputSalary = double.tryParse(_salaryController.text.trim()) ?? 0.0;
    final calcMonthly = _salaryPeriod == "yearly" ? (inputSalary / 12.0) : inputSalary;
    final calcYearly = _salaryPeriod == "monthly" ? (inputSalary * 12.0) : inputSalary;

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile & Settings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar Card
            CustomCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      (authState.fullName?.isNotEmpty ?? false) ? authState.fullName![0] : "A",
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authState.fullName ?? "User", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(authState.email ?? "", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Chip(
                          avatar: Icon(
                            authState.role.toLowerCase() == "enterprise" ? Icons.business_rounded : Icons.person_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            "ROLE: ${authState.role.toUpperCase()}",
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          backgroundColor: authState.role.toLowerCase() == "enterprise" ? AppColors.secondary : AppColors.primary,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial & Salary Details Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text("Financial & Salary Details", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text("Primary Income / Salary Calculation", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(Icons.calendar_view_month_rounded, size: 16, color: _salaryPeriod == "monthly" ? Colors.white : AppColors.primary),
                          label: Text("Monthly Salary", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          selected: _salaryPeriod == "monthly",
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: _salaryPeriod == "monthly" ? Colors.white : null),
                          onSelected: (_) => _onSalaryPeriodChanged("monthly"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          avatar: Icon(Icons.calendar_today_rounded, size: 16, color: _salaryPeriod == "yearly" ? Colors.white : AppColors.primary),
                          label: Text("Yearly Salary (CTC)", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          selected: _salaryPeriod == "yearly",
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: _salaryPeriod == "yearly" ? Colors.white : null),
                          onSelected: (_) => _onSalaryPeriodChanged("yearly"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _salaryController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _salaryPeriod == "yearly" ? "Yearly Salary / Annual CTC (₹)" : "Monthly Base Salary (₹)",
                      hintText: _salaryPeriod == "yearly" ? "e.g. 18,00,000" : "e.g. 1,50,000",
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (inputSalary > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _salaryPeriod == "yearly"
                                  ? "Monthly Net Income: ₹${NumberFormat('#,##,##0.00').format(calcMonthly)} / mo"
                                  : "Annual CTC Equivalent: ₹${NumberFormat('#,##,##0.00').format(calcYearly)} / yr",
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSalaryDetails,
                      icon: const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                      label: Text("Save Salary Details", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Options
            CustomCard(
              child: Column(
                children: [
                  // Dark Mode Switch
                  SwitchListTile(
                    secondary: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.primary),
                    title: Text("Dark Mode", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text(isDark ? "Dark theme active" : "Light theme active", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    value: isDark,
                    activeColor: AppColors.primary,
                    onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                  const Divider(),

                  // Push Notifications Switch
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.warning),
                    title: Text("Push Notifications", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text("Bills & budget alerts", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    value: _pushNotifications,
                    activeColor: AppColors.warning,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(),

                  // Multi-Language Selector
                  ListTile(
                    leading: const Icon(Icons.translate_rounded, color: AppColors.secondary),
                    title: Text("Language", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      underline: const SizedBox(),
                      items: ["English", "Hindi", "Spanish", "German"].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (val) => setState(() => _selectedLanguage = val ?? "English"),
                    ),
                  ),
                  const Divider(),

                  // Backup & Export
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: AppColors.success),
                    title: Text("Local Storage Persistence", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text("All user inputs saved locally on device", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data is securely persisted in device storage!")));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                ref.read(financeProvider.notifier).resetState();
                ref.read(aiProvider.notifier).resetState();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text("Sign Out", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
