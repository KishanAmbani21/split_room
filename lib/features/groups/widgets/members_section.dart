import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../providers/create_group_provider.dart';
import 'app_users_tab.dart';
import 'contacts_coming_soon_tab.dart';
import 'premium_section_header.dart';

class MembersSection extends ConsumerWidget {
  const MembersSection({required this.currentUserId, super.key});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createGroupProvider);
    final notifier = ref.read(createGroupProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumSectionHeader(
          title: 'Add Members',
          subtitle: 'You are automatically added as the group creator',
          accent: AppColors.cyan,
          trailing: state.selectedCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0.25),
                        AppColors.blue.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${state.selectedCount} selected',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.cyanDeep,
                        ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        _MembersTabBar(
          selected: state.membersTab,
          onChanged: notifier.setMembersTab,
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: state.membersTab == MembersTab.appUsers
              ? AppUsersTab(
                  key: const ValueKey('app_users'),
                  currentUserId: currentUserId,
                )
              : const ContactsComingSoonTab(key: ValueKey('contacts')),
        ),
      ],
    );
  }
}

class _MembersTabBar extends StatelessWidget {
  const _MembersTabBar({
    required this.selected,
    required this.onChanged,
  });

  final MembersTab selected;
  final ValueChanged<MembersTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder(brightness)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow(brightness),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'App Users',
              icon: Icons.people_alt_rounded,
              selected: selected == MembersTab.appUsers,
              onTap: () => onChanged(MembersTab.appUsers),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _TabButton(
              label: 'Contacts',
              icon: Icons.contacts_rounded,
              selected: selected == MembersTab.contacts,
              onTap: () => onChanged(MembersTab.contacts),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final primary = AppColors.primaryColor(brightness);
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected ? Border.all(color: primary.withValues(alpha: 0.35)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? primary : muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? primary : muted,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
