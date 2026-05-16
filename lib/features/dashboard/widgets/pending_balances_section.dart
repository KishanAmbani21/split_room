import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../models/dashboard_data.dart';
import '../models/pending_balance.dart';
import 'dashboard_empty_state.dart';
import 'section_title.dart';

class PendingBalancesSection extends StatelessWidget {
  const PendingBalancesSection({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Pending Balances',
                  subtitle: 'Balances with your group members',
        ),
        const SizedBox(height: 14),
        if (data.pendingBalances.isEmpty)
          const DashboardEmptyState(
            icon: Icons.celebration_rounded,
            title: 'All settled up!',
            subtitle: 'No pending balances. You are in the clear.',
            accent: AppColors.mint,
          )
        else
          ...data.pendingBalances.map(
            (balance) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PendingBalanceTile(balance: balance),
            ),
          ),
      ],
    );
  }
}

class _PendingBalanceTile extends StatelessWidget {
  const _PendingBalanceTile({required this.balance});

  final PendingBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isOwed = balance.isOwedToYou;
    final gradient = isOwed
        ? [AppColors.mint.withValues(alpha: 0.15), AppColors.cyan.withValues(alpha: 0.08)]
        : [AppColors.coral.withValues(alpha: 0.15), AppColors.error.withValues(alpha: 0.08)];
    final accent = isOwed ? AppColors.mint : AppColors.coral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOwed
                    ? [AppColors.mint, AppColors.cyan]
                    : [AppColors.coral, AppColors.error],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOwed ? Icons.call_received_rounded : Icons.call_made_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balance.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isOwed ? 'You will receive' : 'Need to pay',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: brightness == Brightness.dark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${AppColors.currencySymbol}${balance.amount.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => showAppSnackBar(context, 'Settle — coming soon.'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Settle', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
