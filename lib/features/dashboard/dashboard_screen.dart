import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/app_user.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/brand_mark.dart';
import '../auth/data/auth_repository.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/add_expense_fab.dart';
import 'widgets/dashboard_bottom_nav.dart';
import 'widgets/dashboard_home_content.dart';
import '../groups/widgets/groups_tab.dart';
import 'widgets/activity_tab_content.dart';
import '../notifications/providers/notification_providers.dart';
import 'widgets/profile_bottom_sheet.dart';
import '../profile/screens/profile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.uid, super.key});

  final String uid;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      ref.read(notificationServiceProvider).resetSession();
      await ref.read(authRepositoryProvider).logout();
      if (context.mounted) {
        showAppSnackBar(context, 'Logged out successfully.');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, authErrorMessage(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDocumentProvider(uid));
    final navIndex = ref.watch(dashboardNavIndexProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const Scaffold(
        body: _MessageView(
          title: 'Unable to load profile',
          message: 'Please check your connection and try again.',
        ),
      ),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: _MessageView(
              title: 'Profile not found',
              message: 'Your Firestore user document does not exist.',
            ),
          );
        }

        // FCM init once per session (not on every rebuild).
        ref.watch(notificationInitProvider(uid));

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: SafeArea(
            child: _DashboardShell(
              user: user,
              navIndex: navIndex,
              onProfileTap: () => showProfileBottomSheet(
                context: context,
                ref: ref,
                user: user,
                onLogout: () => _logout(context, ref),
                onMyGroups: () =>
                    ref.read(dashboardNavIndexProvider.notifier).select(1),
              ),
              onLogout: () => _logout(context, ref),
            ),
          ),
          floatingActionButton:
              navIndex == 0 ? AddExpenseFab(user: user) : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: const DashboardBottomNav(),
        );
      },
    );
  }
}

class _DashboardShell extends StatelessWidget {
  const _DashboardShell({
    required this.user,
    required this.navIndex,
    required this.onProfileTap,
    required this.onLogout,
  });

  final AppUser user;
  final int navIndex;
  final VoidCallback onProfileTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (navIndex) {
        0 => DashboardHomeContent(
          key: const ValueKey('home'),
          user: user,
          onProfileTap: onProfileTap,
        ),
        1 => GroupsTab(
          key: const ValueKey('groups'),
          user: user,
        ),
        2 => ActivityTabContent(
          key: const ValueKey('activity'),
          user: user,
        ),
        _ => ProfileScreen(
          key: const ValueKey('profile'),
          user: user,
          onLogout: onLogout,
        ),
      },
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 64),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
