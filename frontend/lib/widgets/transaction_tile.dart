import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/transaction_model.dart';
import 'custom_card.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.tx,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeLower = tx.type.toLowerCase();
    final isIncome = typeLower == 'income';
    final isInvestment = typeLower == 'investment';
    final isSavings = typeLower == 'savings';

    Color amtColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    String signStr = "-";

    if (isIncome) {
      amtColor = AppColors.success;
      signStr = "+";
    } else if (isInvestment) {
      amtColor = AppColors.secondary;
      signStr = "📈";
    } else if (isSavings) {
      amtColor = AppColors.primary;
      signStr = "🛡️";
    }

    final catColor = AppCategories.getColor(tx.category);
    final catIcon = AppCategories.getIcon(tx.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(catIcon, color: catColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.category,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: catColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tx.date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$signStr ₹${NumberFormat('#,##,##0').format(tx.amount)}",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amtColor,
                  ),
                ),
                if (isInvestment)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("Asset / SIP", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  )
                else if (tx.isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.autorenew_rounded, size: 12, color: AppColors.secondary),
                        const SizedBox(width: 2),
                        Text(
                          "Auto",
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
