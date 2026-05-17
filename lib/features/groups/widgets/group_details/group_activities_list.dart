import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../dashboard/models/activity_log_item.dart';
import '../../models/group_details_data.dart';
import '../premium_section_header.dart';

class GroupActivitiesList extends StatelessWidget {
  const GroupActivitiesList({required this.data, super.key});

  final GroupDetailsData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionHeader(
          title: 'Recent Activities',
          subtitle: 'Expenses, members, and settlements',
          accent: AppColors.amber,
        ),
        const SizedBox(height: 14),
        if (!data.hasActivities)
          const _EmptyActivitiesHint()
        else
          ...data.activities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityTile(item: item),
            ),
          ),
      ],
    );
  }
}

class _EmptyActivitiesHint extends StatelessWidget {
  const _EmptyActivitiesHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.12),
            AppColors.glassFill(brightness),
          ],
        ),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: AppColors.amber.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Activity from expenses and members will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brightness == Brightness.dark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityLogItem item;

  IconData get _icon {
    switch (item.type) {
      case ActivityType.expenseAdded:
        return Icons.receipt_long_rounded;
      case ActivityType.settlement:
        return Icons.handshake_rounded;
      case ActivityType.groupCreated:
        return Icons.group_add_rounded;
      case ActivityType.memberJoined:
        return Icons.person_add_outlined;
      case ActivityType.expenseUpdated:
        return Icons.edit_outlined;
      case ActivityType.expenseDeleted:
      case ActivityType.groupDeleted:
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

  (Color, List<Color>) _style() {
    switch (item.type) {
      case ActivityType.expenseAdded:
        return (AppColors.blue, [AppColors.blue, AppColors.cyan]);
      case ActivityType.settlement:
        return (AppColors.mint, [AppColors.mint, AppColors.cyan]);
      case ActivityType.groupCreated:
      case ActivityType.memberJoined:
        return (AppColors.purple, [AppColors.purple, AppColors.blue]);
      case ActivityType.expenseUpdated:
      case ActivityType.groupUpdated:
        return (AppColors.purple, [AppColors.purple, AppColors.blue]);
      case ActivityType.expenseDeleted:
      case ActivityType.groupDeleted:
      case ActivityType.memberRemoved:
        return (AppColors.coral, [AppColors.coral, AppColors.amber]);
      case ActivityType.activityRestored:
        return (AppColors.mint, [AppColors.mint, AppColors.cyan]);
      case ActivityType.unknown:
        return (AppColors.amber, [AppColors.amber, AppColors.coral]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final (accent, gradient) = _style();
    final time = item.timestamp;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradient.first.withValues(alpha: 0.08),
            AppColors.glassFill(brightness),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: Colors.white, size: 20),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(item.subtitle),
        trailing: time != null
            ? Text(
                '${time.day}/${time.month}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: brightness == Brightness.dark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              )
            : null,
      ),
    );
  }
}
