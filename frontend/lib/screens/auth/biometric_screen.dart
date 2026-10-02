import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

class BiometricScreen extends ConsumerWidget {
  const BiometricScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Biometric Authentication")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.12),
                ),
                child: const Icon(Icons.fingerprint_rounded, size: 80, color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              Text("Biometric Security", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Touch fingerprint sensor or face scanner to verify identity", textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () {
                  final auth = ref.read(authProvider);
                  if (auth.isAuthenticated) {
                    context.go(auth.role == "enterprise" ? '/enterprise/dashboard' : '/dashboard');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Biometric access requires a registered session. Please sign in.")),
                    );
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                label: Text("Verify Session", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
