import 'package:flutter/material.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/theme/app_colors.dart';
import '../models/dashboard_summary.dart';
import 'animated_counter.dart';

class SimpleStatCards extends StatelessWidget {
  const SimpleStatCards({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 400;

        final cards = [
          _StatCard(
            label: 'Total spent',
            value: summary.totalSpent,
            icon: Icons.account_balance_wallet_outlined,
            accent: AppColors.primaryColor(Theme.of(context).brightness),
          ),
          _StatCard(
            label: AppStrings.needToPay,
            value: summary.needToPay,
            icon: Icons.arrow_upward_rounded,
            accent: Theme.of(context).brightness == Brightness.dark
                ? AppColors.errorDark
                : AppColors.error,
          ),
          _StatCard(
            label: AppStrings.willReceive,
            value: summary.willReceive,
            icon: Icons.arrow_downward_rounded,
            accent: Theme.of(context).brightness == Brightness.dark
                ? AppColors.successDark
                : AppColors.success,
          ),
        ];

        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
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
