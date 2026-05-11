import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/account_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final AccountModel? account;
  final String currencySymbol;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final int animationIndex;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.account,
    this.currencySymbol = '₹',
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.animationIndex = 0,
  });

  Color _amountColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (transaction.type) {
      case TransactionType.income:
        return isDark ? DarkColors.incomeGreen : LightColors.incomeGreen;
      case TransactionType.expense:
        return isDark ? DarkColors.expenseRed : LightColors.expenseRed;
      case TransactionType.transfer:
        return isDark ? DarkColors.transferColor : LightColors.transferColor;
    }
  }

  String _amountPrefix() {
    switch (transaction.type) {
      case TransactionType.income:
        return '+';
      case TransactionType.expense:
        return '-';
      case TransactionType.transfer:
        return '↔ ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = category?.color ?? const Color(0xFF636E72);
    final catIcon = category?.icon ?? Icons.receipt;

    return Dismissible(
      key: ValueKey(transaction.id),
      background: _buildSwipeBackground(
        context: context,
        alignment: Alignment.centerLeft,
        color: const Color(0xFF00B87C),
        icon: Icons.edit,
        label: 'Edit',
      ),
      secondaryBackground: _buildSwipeBackground(
        context: context,
        alignment: Alignment.centerRight,
        color: const Color(0xFFE8365D),
        icon: Icons.delete,
        label: 'Delete',
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        } else {
          onEdit?.call();
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        }
        return true;
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 22),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category?.name ?? 'Unknown',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (transaction.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (account != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(account!.icon, size: 10, color: account!.color),
                          const SizedBox(width: 4),
                          Text(
                            account!.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: account!.color,
                            ),
                          ),
                        ],
                      ),
                    ] else if (transaction.accountId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Deleted Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Amount & time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_amountPrefix()}${AppFormatters.formatAmount(transaction.amount, currencySymbol)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _amountColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatTime(transaction.date),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: animationIndex * 40))
        .fadeIn(duration: 350.ms, curve: Curves.easeOutExpo)
        .slideY(
            begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOutExpo);
  }

  Widget _buildSwipeBackground({
    required BuildContext context,
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
