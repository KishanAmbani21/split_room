import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../activity/providers/activity_providers.dart';
import '../../activity/services/activity_undo_service.dart';
import '../models/activity_log_item.dart';
import '../providers/dashboard_providers.dart';
import 'dashboard_empty_state.dart';

class ActivityTabContent extends ConsumerStatefulWidget {
  const ActivityTabContent({required this.user, super.key});

  final AppUser user;

  @override
  ConsumerState<ActivityTabContent> createState() => _ActivityTabContentState();
}

class _ActivityTabContentState extends ConsumerState<ActivityTabContent> {
  final _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider(widget.user.uid));

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorState(
        onRetry: () => ref.invalidate(dashboardDataProvider(widget.user.uid)),
      ),
      data: (data) {
        final grouped = groupActivitiesByGroup(data.activities);

        if (grouped.isEmpty) {
          return PremiumBackground(
            child: ListView(
              padding: AppLayout.scrollPadding(context),
              children: [
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 20),
                DashboardEmptyState(
                  icon: Icons.history_rounded,
                  title: 'No activity yet',
                  subtitle:
                      'Group updates and deleted items you can restore appear here.',
                  accent: AppColors.primaryColor(Theme.of(context).brightness),
                ),
              ],
            ),
          );
        }

        return PremiumBackground(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider(widget.user.uid));
              await ref.read(dashboardDataProvider(widget.user.uid).future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppLayout.scrollPadding(context),
              itemCount: grouped.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Activity',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                  );
                }

                final group = grouped[index - 1];
                final expanded = _expanded.contains(group.groupId);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExpandableGroupCard(
                    group: group,
                    expanded: expanded,
                    user: widget.user,
                    onToggle: () {
                      setState(() {
                        if (expanded) {
                          _expanded.remove(group.groupId);
                        } else {
                          _expanded.add(group.groupId);
                        }
                      });
                    },
                    onRestored: () =>
                        ref.invalidate(dashboardDataProvider(widget.user.uid)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ExpandableGroupCard extends ConsumerWidget {
  const _ExpandableGroupCard({
    required this.group,
    required this.expanded,
    required this.user,
    required this.onToggle,
    required this.onRestored,
  });

  final GroupedActivities group;
  final bool expanded;
  final AppUser user;
  final VoidCallback onToggle;
  final VoidCallback onRestored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final hasImage = group.groupImage.isNotEmpty &&
        File(group.groupImage).existsSync();

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: hasImage
                          ? FileImage(File(group.groupImage))
                          : null,
                      child: hasImage
                          ? null
                          : Text(
                              group.groupName.isNotEmpty
                                  ? group.groupName[0].toUpperCase()
                                  : 'G',
                              style: TextStyle(
                                color: AppColors.primaryColor(brightness),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.groupName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            group.introText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: brightness == Brightness.dark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.expand_more_rounded),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...[
              Divider(
                height: 1,
                color: AppColors.glassBorder(brightness),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  children: group.activities.map((item) {
                    return _ActivityTimelineTile(
                      item: item,
                      user: user,
                      isLast: item == group.activities.last,
                      onRestored: onRestored,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTimelineTile extends ConsumerWidget {
  const _ActivityTimelineTile({
    required this.item,
    required this.user,
    required this.isLast,
    required this.onRestored,
  });

  final ActivityLogItem item;
  final AppUser user;
  final bool isLast;
  final VoidCallback onRestored;

  Future<void> _confirmRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore deleted item?'),
        content: Text(
          'This will restore "${item.title}" and update balances.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(activityUndoServiceProvider).restoreDeleted(
            item: item,
            userId: user.uid,
            userName: user.fullName.isEmpty ? 'You' : user.fullName,
          );
      if (!context.mounted) return;
      onRestored();
      showAppSnackBar(context, 'Item restored');
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, activityUndoErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final time = item.timestamp;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: item.isDeletedAction
                  ? AppColors.errorColor(brightness)
                  : AppColors.primaryColor(brightness),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (time != null)
                      Text(
                        _formatDateTime(time),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                if (item.actorName != null && item.actorName!.isNotEmpty)
                  Text(
                    item.actorName!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryColor(brightness),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (item.canUndo) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _confirmRestore(context, ref),
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Restore'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime time) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${time.day} ${months[time.month - 1]}, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load activity'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
