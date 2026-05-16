import 'dart:io';

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
  return ref.watch(notificationServiceProvider).watchNotifications(userId).map(
        (docs) => docs
            .map((d) => AppNotification.fromMap(d.id, d.data))
            .toList(),
      );
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
              onPressed: () => ref
                  .read(notificationServiceProvider)
                  .markAllRead(user.uid),
              child: const Text('Mark all read'),
            ),
          ],
        ),
        body: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Could not load notifications')),
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No notifications yet'));
            }

            return ListView.separated(
              padding: AppLayout.scrollPadding(context),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final n = items[index];
                return _NotificationTile(notification: n);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = notification.groupImage.isNotEmpty &&
        File(notification.groupImage).existsSync();

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage:
                hasImage ? FileImage(File(notification.groupImage)) : null,
            child: hasImage
                ? null
                : Text(
                    notification.groupName.isNotEmpty
                        ? notification.groupName[0].toUpperCase()
                        : 'G',
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.groupName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 4),
                Text(notification.message),
                if (notification.createdAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _format(notification.createdAt!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  static String _format(DateTime time) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${time.day} ${months[time.month - 1]}, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
