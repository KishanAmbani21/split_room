import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'user_avatar.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    required this.user,
    required this.onProfileTap,
    super.key,
  });

  final AppUser user;
  final VoidCallback onProfileTap;

  static const appDisplayName = 'RoomSplit';

  String get _firstName {
    final parts = user.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'there';
    return parts.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = AppColors.primaryColor(theme.brightness);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final unreadAsync = ref.watch(unreadNotificationCountProvider(user.uid));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appDisplayName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hello, $_firstName',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Here\'s your expense overview',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _NotificationBell(
          unreadCount: unreadAsync.value ?? 0,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationsScreen(user: user),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        UserAvatar(
          name: user.fullName,
          imageUrl: user.profileImageUrl,
          radius: 24,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    this.onTap,
  });

  final int unreadCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: Icon(
          Icons.notifications_outlined,
          color: AppColors.primaryColor(theme.brightness),
        ),
      ),
    );
  }
}
