import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../dashboard/widgets/animated_counter.dart';
import '../../models/group_details_data.dart';

class GroupSummaryCards extends StatelessWidget {
  const GroupSummaryCards({required this.data, super.key});

  final GroupDetailsData data;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final cardHeight = wide ? 130.0 : 118.0;

        final cards = [
          _SummaryTile(
            label: 'Total spent',
            value: data.totalSpent,
            icon: Icons.account_balance_wallet_rounded,
            gradient: brightness == Brightness.dark
                ? AppColors.spentGradientDark
                : AppColors.spentGradientLight,
          ),
          _SummaryTile(
            label: 'This month',
            value: data.monthSpent,
            icon: Icons.calendar_month_rounded,
            gradient: [AppColors.purple, AppColors.cyan],
          ),
          _SummaryTile(
            label: 'Pending',
            value: data.pendingBalanceCount.toDouble(),
            icon: Icons.pending_actions_rounded,
            gradient: [AppColors.amber, AppColors.coral],
            isCount: true,
          ),
        ];

        if (wide) {
          return SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }

        return SizedBox(
          height: cardHeight * 3 + 24,
          child: Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.isCount = false,
  });

  final String label;
  final double value;
  final IconData icon;
  final List<Color> gradient;
  final bool isCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.95), size: 22),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          isCount
              ? Text(
                  value.toInt().toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                )
              : AnimatedCounter(
                  value: value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
        ],
      ),
    );
  }
}
