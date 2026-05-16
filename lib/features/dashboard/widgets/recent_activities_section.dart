import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/activity_log_item.dart';
import '../models/dashboard_data.dart';
import 'dashboard_empty_state.dart';
import 'section_title.dart';

class RecentActivitiesSection extends StatelessWidget {
  const RecentActivitiesSection({
    required this.data,
    super.key,
    this.compact = false,
    this.maxItems = 5,
  });

  final DashboardData data;
  final bool compact;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final items = data.activities.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Recent activities',
          subtitle: compact ? null : 'Latest updates across your groups',
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          DashboardEmptyState(
            icon: Icons.history_rounded,
            title: 'No activity yet',
            subtitle: 'Expenses and group updates will appear here.',
            accent: AppColors.primaryColor(Theme.of(context).brightness),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CompactActivityTile(item: item),
            ),
          ),
      ],
    );
  }
}

class CompactActivityTile extends StatelessWidget {
  const CompactActivityTile({required this.item, super.key});

  final ActivityLogItem item;

  IconData get _icon {
    switch (item.type) {
      case ActivityType.expenseAdded:
        return Icons.receipt_long_outlined;
      case ActivityType.settlement:
        return Icons.handshake_outlined;
      case ActivityType.groupCreated:
        return Icons.group_add_outlined;
      case ActivityType.memberJoined:
        return Icons.person_add_outlined;
      case ActivityType.expenseUpdated:
        return Icons.edit_outlined;
      case ActivityType.expenseDeleted:
        return Icons.delete_outline;
      case ActivityType.groupUpdated:
        return Icons.edit_note_outlined;
      case ActivityType.memberRemoved:
        return Icons.person_remove_outlined;
      case ActivityType.activityRestored:
        return Icons.restore_rounded;
      case ActivityType.unknown:
        return Icons.info_outline_rounded;
    }
  }

  Color _accent(Brightness brightness) {
    switch (item.type) {
      case ActivityType.expenseAdded:
        return AppColors.primaryColor(brightness);
      case ActivityType.settlement:
        return AppColors.successColor(brightness);
      case ActivityType.groupCreated:
      case ActivityType.memberJoined:
        return AppColors.secondaryColor(brightness);
      case ActivityType.expenseUpdated:
      case ActivityType.groupUpdated:
        return AppColors.secondaryColor(brightness);
      case ActivityType.expenseDeleted:
      case ActivityType.memberRemoved:
        return AppColors.errorColor(brightness);
      case ActivityType.activityRestored:
        return AppColors.successColor(brightness);
      case ActivityType.unknown:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final accent = _accent(brightness);
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final time = item.timestamp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(12),
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
            child: Icon(_icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
          if (time != null)
            Text(
              '${time.day}/${time.month}',
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
        ],
      ),
    );
  }
}
