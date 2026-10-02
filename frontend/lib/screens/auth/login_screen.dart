import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/ai_provider.dart';
import '../../widgets/custom_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: "demo@finsight.ai");
  final _passwordController = TextEditingController(text: "demo123");
  bool _obscureText = true;
  String _selectedRole = "user"; // 'user' or 'enterprise'
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          role: _selectedRole,
        );

    if (mounted) {
      if (success) {
        ref.read(financeProvider.notifier).fetchData();
        ref.read(aiProvider.notifier).startNewSession();
        final currentRole = ref.read(authProvider).role;
        if (currentRole.toLowerCase() == "enterprise") {
          context.go('/enterprise/dashboard');
        } else {
          context.go('/dashboard');
        }
      } else {
        final err = ref.read(authProvider).error;
        setState(() {
          _errorMessage = err ?? "Your account is not registered for this role.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      child: const Icon(Icons.auto_graph_rounded, size: 44, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome to FinSight AI",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Sign in to access your financial decision platform",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Demo Account Banner Card
                  CustomCard(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Demo Accounts", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text("Select role & auto-fill credentials", style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _emailController.text = "demo@finsight.ai";
                                    _passwordController.text = "demo123";
                                    _selectedRole = "user";
                                    _errorMessage = null;
                                  });
                                  _handleLogin();
                                },
                                icon: const Icon(Icons.person_rounded, size: 14, color: Colors.white),
                                label: Text("User Demo", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _emailController.text = "corp@finsight.ai";
                                    _passwordController.text = "corp123";
                                    _selectedRole = "enterprise";
                                    _errorMessage = null;
                                  });
                                  // Register enterprise demo user if needed and login
                                  ref.read(authProvider.notifier).register("corp@finsight.ai", "Acme Enterprise Admin", "corp123", role: "enterprise").then((_) {
                                    _handleLogin();
                                  });
                                },
                                icon: const Icon(Icons.business_rounded, size: 14, color: Colors.white),
                                label: Text("Enterprise Demo", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text("Email Address", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: "email@example.com",
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text("Password", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: "••••••••",
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, size: 20),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // MANDATORY VISIBLE ROLE SELECTOR ON SIGN-IN
                        Text("Login as:", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = "user"),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == "user" ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedRole == "user" ? AppColors.primary : Colors.grey.shade400,
                                      width: _selectedRole == "user" ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selectedRole == "user" ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                        size: 18,
                                        color: _selectedRole == "user" ? AppColors.primary : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "User",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _selectedRole == "user" ? AppColors.primary : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedRole = "enterprise"),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == "enterprise" ? AppColors.secondary.withOpacity(0.15) : Colors.transparent,
                                    border: Border.all(
                                      color: _selectedRole == "enterprise" ? AppColors.secondary : Colors.grey.shade400,
                                      width: _selectedRole == "enterprise" ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _selectedRole == "enterprise" ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                                        size: 18,
                                        color: _selectedRole == "enterprise" ? AppColors.secondary : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Enterprise",
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: _selectedRole == "enterprise" ? AppColors.secondary : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text("Forgot Password?", style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == "enterprise" ? AppColors.secondary : AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _selectedRole == "enterprise" ? "SIGN IN AS ENTERPRISE" : "SIGN IN AS USER",
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/biometric'),
                          icon: const Icon(Icons.fingerprint_rounded, color: AppColors.secondary),
                          label: Text("Biometric Login", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.secondary)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.secondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondaryLight)),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text("Register", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
