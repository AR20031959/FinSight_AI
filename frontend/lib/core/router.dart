import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/biometric_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expense/expense_screen.dart';
import '../screens/statement/statement_screen.dart';
import '../screens/ai_assistant/ai_assistant_screen.dart';
import '../screens/investment/investment_screen.dart';
import '../screens/business/business_screen.dart';
import '../screens/cash_flow/cash_flow_screen.dart';
import '../screens/health_score/health_score_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/floating_ai_button.dart';
import '../widgets/voice_assistant_modal.dart';
import '../screens/enterprise/enterprise_dashboard_screen.dart';
import '../providers/auth_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OTPScreen(),
    ),
    GoRoute(
      path: '/biometric',
      builder: (context, state) => const BiometricScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellScreen(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/user/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/enterprise/dashboard',
          builder: (context, state) => const EnterpriseDashboardScreen(),
        ),
        GoRoute(
          path: '/expense',
          builder: (context, state) => const ExpenseScreen(),
        ),
        GoRoute(
          path: '/statement',
          builder: (context, state) => const StatementScreen(),
        ),
        GoRoute(
          path: '/ai-assistant',
          builder: (context, state) => const AIAssistantScreen(),
        ),
        GoRoute(
          path: '/investment',
          builder: (context, state) => const InvestmentScreen(),
        ),
        GoRoute(
          path: '/business',
          builder: (context, state) => const BusinessScreen(),
        ),
        GoRoute(
          path: '/cash-flow',
          builder: (context, state) => const CashFlowScreen(),
        ),
        GoRoute(
          path: '/health-score',
          builder: (context, state) => const HealthScoreScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/expense')) return 1;
    if (location.startsWith('/ai-assistant')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final role = ref.read(authProvider).role.toLowerCase();
    switch (index) {
      case 0:
        if (role == "enterprise") {
          context.go('/enterprise/dashboard');
        } else {
          context.go('/dashboard');
        }
        break;
      case 1:
        context.go('/expense');
        break;
      case 2:
        context.go('/ai-assistant');
        break;
      case 3:
        context.go('/reports');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final authState = ref.watch(authProvider);
    final isEnterprise = authState.role.toLowerCase() == "enterprise";

    return Scaffold(
      body: widget.child,
      floatingActionButton: const FloatingAIButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnterprise ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] : [const Color(0xFF2563EB), const Color(0xFF06B6D4)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("FinSight AI", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    isEnterprise ? "Enterprise Account (${authState.fullName})" : "Personal Financial Intelligence",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isEnterprise) ...[
              ListTile(
                leading: const Icon(Icons.business_center_rounded, color: Color(0xFF06B6D4)),
                title: const Text("Enterprise Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/enterprise/dashboard');
                },
              ),
              const Divider(),
            ],
            ListTile(leading: const Icon(Icons.dashboard_rounded), title: const Text("Personal Dashboard"), onTap: () => context.go('/dashboard')),
            ListTile(leading: const Icon(Icons.receipt_long_rounded), title: const Text("Expense Manager"), onTap: () => context.go('/expense')),
            ListTile(leading: const Icon(Icons.document_scanner_rounded), title: const Text("Statement Analyzer & OCR"), onTap: () => context.go('/statement')),
            ListTile(leading: const Icon(Icons.psychology_rounded), title: const Text("AI Financial Advisor"), onTap: () => context.go('/ai-assistant')),
            ListTile(leading: const Icon(Icons.show_chart_rounded), title: const Text("Investment Planner"), onTap: () => context.go('/investment')),
            ListTile(leading: const Icon(Icons.storefront_rounded), title: const Text("Business Analytics"), onTap: () => context.go('/business')),
            ListTile(leading: const Icon(Icons.ssid_chart_rounded), title: const Text("Cash Flow Forecast"), onTap: () => context.go('/cash-flow')),
            ListTile(leading: const Icon(Icons.health_and_safety_rounded), title: const Text("Financial Health Score"), onTap: () => context.go('/health-score')),
            ListTile(leading: const Icon(Icons.description_rounded), title: const Text("Reports Generator"), onTap: () => context.go('/reports')),
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: const Text("Smart Voice Assistant"),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const VoiceAssistantModal(),
                );
              },
            ),
            const Divider(),
            ListTile(leading: const Icon(Icons.person_outline_rounded), title: const Text("Profile & Settings"), onTap: () => context.go('/profile')),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology_rounded), label: 'AI Assistant'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description_rounded), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
