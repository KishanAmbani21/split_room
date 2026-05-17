import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../models/expense_group_member.dart';
import '../utils/expense_split_builder.dart';

/// Live breakdown of how the bill is split among members.
class SplitPreviewBanner extends StatelessWidget {
  const SplitPreviewBanner({
    required this.amount,
    required this.splitType,
    required this.selectedMembers,
    required this.customAmounts,
    required this.percentages,
    required this.shares,
    super.key,
  });

  final double? amount;
  final SplitType splitType;
  final List<ExpenseGroupMember> selectedMembers;
  final Map<String, double> customAmounts;
  final Map<String, double> percentages;
  final Map<String, int> shares;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = amount;
    if (total == null || total <= 0 || selectedMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    final splits = buildSplitsForType(
      splitType: splitType,
      amount: total,
      members: selectedMembers,
      customAmounts: customAmounts,
      percentages: percentages,
      shares: shares,
    );

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.mint, size: 18),
              const SizedBox(width: 8),
              Text(
                'Split preview',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${AppColors.currencySymbol}${total.toStringAsFixed(2)} total',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...splits.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${AppColors.currencySymbol}${s.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
