import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/app_notification.dart';
import '../providers/notification_providers.dart';

final userNotificationsProvider = StreamProvider.autoDispose
    .family<List<AppNotification>, String>((ref, userId) {
      return ref
          .watch(notificationServiceProvider)
          .watchNotificationList(userId);
    });

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider(user.uid));

    return PremiumBackground(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(notificationServiceProvider).markAllRead(user.uid),
              child: const Text('Mark all read'),
            ),
          ],
        ),
        body: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load notifications'),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(userNotificationsProvider(user.uid)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No notifications yet'));
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(userNotificationsProvider(user.uid));
                await ref.read(userNotificationsProvider(user.uid).future);
              },
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppLayout.scrollPadding(context),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final n = items[index];
                  return _NotificationTile(
                    notification: n,
                    onTap: () {
                      if (!n.isRead) {
                        ref.read(notificationServiceProvider).markRead(n.id);
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case 'EXPENSE_ADDED':
        return Icons.receipt_long_rounded;
      case 'EXPENSE_UPDATED':
        return Icons.edit_outlined;
      case 'EXPENSE_DELETED':
      case 'GROUP_DELETED':
        return Icons.delete_outline_rounded;
      case 'GROUP_CREATED':
        return Icons.group_add_rounded;
      case 'MEMBER_JOINED':
        return Icons.person_add_alt_1_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _accent(Brightness brightness) {
    switch (notification.type) {
      case 'EXPENSE_DELETED':
      case 'GROUP_DELETED':
        return AppColors.errorColor(brightness);
      case 'EXPENSE_ADDED':
      case 'GROUP_CREATED':
      case 'MEMBER_JOINED':
        return AppColors.successColor(brightness);
      default:
        return AppColors.primaryColor(brightness);
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

    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: notification.createdByName),
                          TextSpan(
                            text: ' ${notification.actionLabel}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups_rounded, size: 14, color: muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            notification.groupName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (notification.createdAt != null)
                          Text(
                            _format(notification.createdAt!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor(brightness),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _format(DateTime time) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${time.day} ${months[time.month - 1]}, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
