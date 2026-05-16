import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/branding/app_branding.dart';
import '../../shared/models/app_user.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/brand_mark.dart';
import '../auth/data/auth_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({required this.uid, super.key});

  final String uid;

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
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
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            BrandMark(size: 34),
            SizedBox(width: 10),
            Text(AppBranding.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).setDarkMode(!isDark);
            },
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _MessageView(
            title: 'Unable to load profile',
            message: 'Please check your connection and try again.',
          ),
          data: (user) {
            if (user == null) {
              return const _MessageView(
                title: 'Profile not found',
                message: 'Your Firestore user document does not exist.',
              );
            }
            return _DashboardContent(user: user);
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatDate(user.createdAt);
    final updatedAt = _formatDate(user.updatedAt);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user.fullName.isEmpty
                              ? '?'
                              : user.fullName.characters.first.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(user.email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 560;
                  final cards = [
                    _DashboardCard(
                      title: 'Status',
                      value: user.status,
                      icon: Icons.verified_user_outlined,
                    ),
                    _DashboardCard(
                      title: 'Login type',
                      value: user.loginType,
                      icon: Icons.mail_outline_rounded,
                    ),
                    _DashboardCard(
                      title: 'Device',
                      value: user.deviceType,
                      icon: Icons.android_rounded,
                    ),
                    _DashboardCard(
                      title: 'Created',
                      value: createdAt,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ];

                  return GridView.count(
                    crossAxisCount: twoColumns ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: twoColumns ? 2.8 : 3.8,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 16),
              _InfoTile(label: 'Firebase UID', value: user.uid),
              _InfoTile(label: 'Last updated', value: updatedAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        title: Text(label),
        subtitle: Text(value),
      ),
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

String _formatDate(DateTime? value) {
  if (value == null) {
    return 'Syncing';
  }
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
