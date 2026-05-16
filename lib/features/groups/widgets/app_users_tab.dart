import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../providers/create_group_provider.dart';
import '../providers/groups_providers.dart';
import 'member_user_card.dart';

class AppUsersTab extends ConsumerWidget {
  const AppUsersTab({required this.currentUserId, super.key});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createGroupProvider);
    final notifier = ref.read(createGroupProvider.notifier);
    final usersAsync = ref.watch(appUsersProvider(currentUserId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: notifier.setMemberSearchQuery,
          decoration: InputDecoration(
            hintText: 'Search by name or email',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: state.memberSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => notifier.setMemberSearchQuery(''),
                  )
                : null,
          ),
        ),
        if (state.selectedCount > 0) ...[
          const SizedBox(height: 12),
          _SelectedCountBadge(count: state.selectedCount),
        ],
        const SizedBox(height: 14),
        usersAsync.when(
          loading: () => const _UsersLoadingState(),
          error: (error, _) => _UsersEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load users',
            subtitle: 'Check your connection and Firestore rules.',
          ),
          data: (users) {
            final query = state.memberSearchQuery.trim().toLowerCase();
            final filtered = query.isEmpty
                ? users
                : users
                    .where(
                      (u) =>
                          u.name.toLowerCase().contains(query) ||
                          u.email.toLowerCase().contains(query),
                    )
                    .toList();

            if (filtered.isEmpty) {
              return _UsersEmptyState(
                icon: Icons.person_search_rounded,
                title: query.isEmpty ? 'No app users yet' : 'No users found',
                subtitle: query.isEmpty
                    ? 'Other users will appear here after they sign up.'
                    : 'Try a different search term.',
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 520;
                  if (isWide) {
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 720 ? 2 : 1,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 3.2,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final selected =
                            state.selectedMemberIds.contains(user.uid);
                        return MemberUserCard(
                          user: user,
                          selected: selected,
                          onTap: () => notifier.toggleMember(user),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final selected =
                          state.selectedMemberIds.contains(user.uid);
                      return MemberUserCard(
                        user: user,
                        selected: selected,
                        onTap: () => notifier.toggleMember(user),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SelectedCountBadge extends StatelessWidget {
  const _SelectedCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.2),
            AppColors.blue.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_rounded, size: 18, color: AppColors.cyanDeep),
          const SizedBox(width: 8),
          Text(
            '$count member${count == 1 ? '' : 's'} selected',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.cyanDeep,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _UsersLoadingState extends StatelessWidget {
  const _UsersLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 40, color: scheme.primary.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
