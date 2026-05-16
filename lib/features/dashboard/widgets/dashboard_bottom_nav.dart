import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';

class DashboardBottomNav extends ConsumerWidget {
  const DashboardBottomNav({super.key});

  static const _items = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.groups_rounded, label: 'Groups'),
    (icon: Icons.history_rounded, label: 'Activity'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(dashboardNavIndexProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: scheme.onSurface.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: ref.read(dashboardNavIndexProvider.notifier).select,
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: scheme.primary.withValues(alpha: 0.12),
          destinations: [
            for (final item in _items)
              NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
