import 'package:flutter/material.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/dashboard_summary.dart';
import 'animated_counter.dart';

class MonthlySummaryCards extends StatelessWidget {
  const MonthlySummaryCards({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final brightness = Theme.of(context).brightness;
        final cards = [
          _SummaryCard(
            label: AppStrings.totalMoneySpent,
            value: summary.monthTotalSpent,
            icon: Icons.account_balance_wallet_outlined,
            accent: AppColors.secondaryColor(brightness),
          ),
          _SummaryCard(
            label: AppStrings.totalWillReceive,
            value: summary.willReceive,
            icon: Icons.arrow_downward_rounded,
            accent: AppColors.successColor(brightness),
          ),
          _SummaryCard(
            label: AppStrings.youNeedToPay,
            value: summary.monthNeedToPay,
            icon: Icons.arrow_upward_rounded,
            accent: AppColors.errorColor(brightness),
          ),
        ];

        if (wide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
              const SizedBox(width: 10),
              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: brightness == Brightness.dark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedCounter(
                  value: value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
