import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/group_details_data.dart';
import '../../models/group_settlement_item.dart';

/// Who owes the current user vs who they owe — shown under group summary.
class GroupSettlementList extends StatelessWidget {
  const GroupSettlementList({required this.data, super.key});

  final GroupDetailsData data;

  @override
  Widget build(BuildContext context) {
    if (data.receiveFrom.isEmpty && data.payTo.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text(
          'All settled up in this group',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.receiveFrom.isNotEmpty) ...[
            _SectionHeader(
              title: 'You will receive from',
              icon: Icons.south_west_rounded,
              color: AppColors.successColor(Theme.of(context).brightness),
            ),
            const SizedBox(height: 8),
            ...data.receiveFrom.map(
              (item) => _SettlementTile(
                item: item,
                subtitle: 'owes you',
                color: AppColors.successColor(Theme.of(context).brightness),
              ),
            ),
          ],
          if (data.receiveFrom.isNotEmpty && data.payTo.isNotEmpty)
            const SizedBox(height: 14),
          if (data.payTo.isNotEmpty) ...[
            _SectionHeader(
              title: 'You need to pay',
              icon: Icons.north_east_rounded,
              color: AppColors.errorColor(Theme.of(context).brightness),
            ),
            const SizedBox(height: 8),
            ...data.payTo.map(
              (item) => _SettlementTile(
                item: item,
                subtitle: 'you owe',
                color: AppColors.errorColor(Theme.of(context).brightness),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SettlementTile extends StatelessWidget {
  const _SettlementTile({
    required this.item,
    required this.subtitle,
    required this.color,
  });

  final GroupSettlementItem item;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Text(
              item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Text(
            '${AppColors.currencySymbol}${item.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
