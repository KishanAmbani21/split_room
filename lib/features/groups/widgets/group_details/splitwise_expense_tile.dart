import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/constants/app_strings.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/group_expense.dart';
import '../../models/group_member_balance.dart';

class SplitwiseExpenseTile extends StatelessWidget {
  const SplitwiseExpenseTile({
    required this.expense,
    required this.currentUserId,
    required this.members,
    this.showFullPaidAmount = false,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final GroupExpense expense;
  final String currentUserId;
  final List<GroupMemberBalance> members;
  /// When true, shows the full expense amount (for Paid by Me / Others Paid tabs).
  final bool showFullPaidAmount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  GroupMemberBalance? get _payer {
    for (final m in members) {
      if (m.userId == expense.paidBy) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final impact = expense.balanceImpactFor(currentUserId);
    final receives = !showFullPaidAmount && impact > 0.01;
    final owes = !showFullPaidAmount && impact < -0.01;
    final impactColor = showFullPaidAmount
        ? theme.colorScheme.onSurface
        : receives
            ? AppColors.successColor(brightness)
            : owes
                ? AppColors.errorColor(brightness)
                : muted;
    final payer = _payer;
    final imagePath = payer?.profileImage ?? '';
    final hasImage =
        imagePath.isNotEmpty && File(imagePath).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: hasImage ? FileImage(File(imagePath)) : null,
            child: hasImage
                ? null
                : Text(
                    expense.paidByName.isNotEmpty
                        ? expense.paidByName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.primaryColor(brightness),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.paidByName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                  ),
                ),
                if (expense.createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(expense.createdAt!),
                    style: theme.textTheme.labelSmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!showFullPaidAmount && (receives || owes))
                Text(
                  receives ? AppStrings.owesYou : AppStrings.needToPayShort,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                showFullPaidAmount
                    ? '${AppColors.currencySymbol}${expense.amount.toStringAsFixed(2)}'
                    : receives || owes
                        ? '${receives ? '+' : '-'}${AppColors.currencySymbol}${impact.abs().toStringAsFixed(2)}'
                        : '${AppColors.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: impactColor,
                ),
              ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: muted,
                size: 20,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.error),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
