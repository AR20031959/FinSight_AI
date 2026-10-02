import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color success = Color(0xFF22C55E); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardLight = Colors.white;
  
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

class AppCategories {
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Shopping',
    'Rent & Housing',
    'Utilities',
    'Travel & Transport',
    'EMI & Loans',
    'Entertainment',
    'Medical & Health',
    'Subscriptions',
    'Education',
    'Other Expense'
  ];

  static const List<String> investmentCategories = [
    'Mutual Funds / SIP',
    'Stocks & Equities',
    'Fixed Deposit / RD',
    'Real Estate',
    'Gold & Precious Metals',
    'Crypto & Digital Assets',
    'PPF / NPS',
    'Retirement Fund',
    'Other Investment'
  ];

  static const List<String> incomeCategories = [
    'Salary',
    'Business & Freelance',
    'Investment Returns',
    'Rental Income',
    'Side Hustle',
    'Other Income'
  ];

  static const List<String> savingsCategories = [
    'Emergency Reserve',
    'Goal Savings',
    'Cash Buffer',
    'Other Savings'
  ];

  static List<String> get categories => [
        ...expenseCategories,
        ...investmentCategories,
        ...incomeCategories,
        ...savingsCategories,
      ];

  static List<String> getCategoriesForType(String type) {
    switch (type.toLowerCase()) {
      case 'expense':
        return expenseCategories;
      case 'investment':
        return investmentCategories;
      case 'income':
        return incomeCategories;
      case 'savings':
        return savingsCategories;
      default:
        return expenseCategories;
    }
  }

  static IconData getIcon(String category) {
    if (category.contains('Food') || category == 'Food') return Icons.restaurant_rounded;
    if (category.contains('Travel') || category == 'Travel') return Icons.directions_car_rounded;
    if (category.contains('Shopping') || category == 'Shopping') return Icons.shopping_bag_rounded;
    if (category.contains('Housing') || category.contains('Rent')) return Icons.home_rounded;
    if (category.contains('EMI') || category == 'EMI' || category.contains('Loan')) return Icons.account_balance_rounded;
    if (category.contains('Entertainment') || category == 'Entertainment') return Icons.movie_rounded;
    if (category.contains('SIP') || category.contains('Mutual Funds')) return Icons.trending_up_rounded;
    if (category.contains('Stocks') || category.contains('Equities')) return Icons.show_chart_rounded;
    if (category.contains('Deposit') || category.contains('RD')) return Icons.savings_rounded;
    if (category.contains('Real Estate')) return Icons.location_city_rounded;
    if (category.contains('Gold')) return Icons.workspace_premium_rounded;
    if (category.contains('Crypto')) return Icons.currency_bitcoin_rounded;
    if (category.contains('PPF') || category.contains('NPS')) return Icons.verified_user_rounded;
    if (category.contains('Utilities') || category == 'Utilities') return Icons.bolt_rounded;
    if (category.contains('Medical') || category == 'Medical') return Icons.medical_services_rounded;
    if (category.contains('Salary') || category == 'Salary') return Icons.payments_rounded;
    if (category.contains('Business') || category == 'Business') return Icons.business_center_rounded;
    if (category.contains('Subscription')) return Icons.subscriptions_rounded;
    if (category.contains('Emergency')) return Icons.shield_rounded;
    return Icons.receipt_long_rounded;
  }

  static Color getColor(String category) {
    if (category.contains('Food') || category == 'Food') return const Color(0xFFF97316);
    if (category.contains('Travel') || category == 'Travel') return const Color(0xFF06B6D4);
    if (category.contains('Shopping') || category == 'Shopping') return const Color(0xFFA855F7);
    if (category.contains('Housing') || category.contains('Rent')) return const Color(0xFF6366F1);
    if (category.contains('EMI') || category == 'EMI') return const Color(0xFFEF4444);
    if (category.contains('Entertainment')) return const Color(0xFFEC4899);
    if (category.contains('SIP') || category.contains('Mutual Funds')) return const Color(0xFF10B981);
    if (category.contains('Stocks') || category.contains('Equities')) return const Color(0xFF059669);
    if (category.contains('Deposit') || category.contains('RD')) return const Color(0xFF0D9488);
    if (category.contains('Gold')) return const Color(0xFFF59E0B);
    if (category.contains('Crypto')) return const Color(0xFF8B5CF6);
    if (category.contains('Utilities')) return const Color(0xFFEAB308);
    if (category.contains('Medical')) return const Color(0xFF14B8A6);
    if (category.contains('Salary')) return const Color(0xFF2563EB);
    if (category.contains('Business')) return const Color(0xFF3B82F6);
    return const Color(0xFF64748B);
  }
}
