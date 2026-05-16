import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import 'user_avatar.dart';

Future<void> showProfileBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required AppUser user,
  required Future<void> Function() onLogout,
  VoidCallback? onMyGroups,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ProfileBottomSheet(
      user: user,
      onLogout: () async {
        Navigator.of(sheetContext).pop();
        await onLogout();
      },
      onEditProfile: () {
        Navigator.of(sheetContext).pop();
        showAppSnackBar(context, 'Edit Profile — coming soon.');
      },
      onMyGroups: () {
        Navigator.of(sheetContext).pop();
        if (onMyGroups != null) {
          onMyGroups();
        } else {
          showAppSnackBar(context, 'My Groups — coming soon.');
        }
      },
    ),
  );
}

class _ProfileBottomSheet extends ConsumerWidget {
  const _ProfileBottomSheet({
    required this.user,
    required this.onLogout,
    required this.onEditProfile,
    required this.onMyGroups,
  });

  final AppUser user;
  final VoidCallback onEditProfile;
  final VoidCallback onMyGroups;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = ref.watch(themeModeProvider);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.4 : 0.12),
              blurRadius: 32,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                UserAvatar(
                  name: user.fullName,
                  imageUrl: user.profileImageUrl,
                  radius: 36,
                ),
                const SizedBox(height: 14),
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 22),
                _ThemeToggleTile(
                  isDark: isDark,
                  onChanged: (value) {
                    ref.read(themeModeProvider.notifier).setDarkMode(value);
                  },
                ),
                const SizedBox(height: 8),
                _SheetActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: onEditProfile,
                ),
                const SizedBox(height: 8),
                _SheetActionButton(
                  icon: Icons.groups_outlined,
                  label: 'My Groups',
                  onTap: onMyGroups,
                ),
                const SizedBox(height: 8),
                _SheetActionButton(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isDestructive: true,
                  onTap: () => onLogout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile({
    required this.isDark,
    required this.onChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      leading: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      ),
      title: const Text('Dark mode'),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: onChanged,
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: theme.colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
