import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../app_version/widgets/app_version_label.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../dashboard/widgets/animated_fade_slide.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../widgets/settings_tile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.user, required this.onLogout, super.key});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = ref.watch(themeModeProvider);
    final unreadAsync = ref.watch(unreadNotificationCountProvider(user.uid));
    final unreadCount = unreadAsync.value ?? 0;
    final imageUrl = user.profileImageUrl ?? '';
    final hasPhoto = imageUrl.isNotEmpty && File(imageUrl).existsSync();

    return PremiumBackground(
      child: SingleChildScrollView(
        padding: AppLayout.scrollPadding(context).copyWith(bottom: 120),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppLayout.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                AnimatedFadeSlide(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar_${user.uid}',
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: hasPhoto
                              ? FileImage(File(imageUrl))
                              : null,
                          child: hasPhoto
                              ? null
                              : Text(
                                  user.fullName.trim().isEmpty
                                      ? '?'
                                      : user.fullName.trim()[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName.isEmpty ? 'Your Profile' : user.fullName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 60),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          onTap: () => showAppSnackBar(
                            context,
                            'Edit profile — coming soon!',
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.groups_outlined,
                          title: 'My Groups',
                          onTap: () => ref
                              .read(dashboardNavIndexProvider.notifier)
                              .select(1),
                        ),
                        SettingsTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Expense History',
                          onTap: () => ref
                              .read(dashboardNavIndexProvider.notifier)
                              .select(2),
                        ),
                        SettingsTile(
                          icon: isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          title: 'Theme',
                          trailing: Switch.adaptive(
                            value: isDark,
                            onChanged: (v) => ref
                                .read(themeModeProvider.notifier)
                                .setDarkMode(v),
                          ),
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setDarkMode(!isDark),
                        ),
                        SettingsTile(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          trailing: unreadCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NotificationsScreen(user: user),
                            ),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.settings_outlined,
                          title: 'App Settings',
                          trailing: const AppVersionLabel(
                            compact: true,
                            textAlign: TextAlign.right,
                          ),
                          onTap: () => showAppSnackBar(
                            context,
                            'App settings — coming soon!',
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          onTap: () => showAppSnackBar(
                            context,
                            'Help & support — coming soon!',
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          showDivider: false,
                          onTap: () => showAppSnackBar(
                            context,
                            'Privacy policy — coming soon!',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedFadeSlide(
                  delay: const Duration(milliseconds: 120),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const AppVersionLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
