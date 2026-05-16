import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/dashboard_summary.dart';
import 'animated_counter.dart';

class GradientSummaryCard extends StatelessWidget {
  const GradientSummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    super.key,
  });

  final String label;
  final double value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCardsSection extends StatelessWidget {
  const SummaryCardsSection({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final cardHeight = wide ? 152.0 : 136.0;

        final cards = [
          GradientSummaryCard(
            label: 'Total Spent',
            value: summary.totalSpent,
            icon: Icons.account_balance_wallet_rounded,
            gradient: brightness == Brightness.dark
                ? AppColors.spentGradientDark
                : AppColors.spentGradientLight,
          ),
          GradientSummaryCard(
            label: 'Need to Pay',
            value: summary.needToPay,
            icon: Icons.north_east_rounded,
            gradient: brightness == Brightness.dark
                ? AppColors.oweGradientDark
                : AppColors.oweGradientLight,
          ),
          GradientSummaryCard(
            label: 'You Will Receive',
            value: summary.willReceive,
            icon: Icons.south_west_rounded,
            gradient: brightness == Brightness.dark
                ? AppColors.getBackGradientDark
                : AppColors.getBackGradientLight,
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
