import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../create_group_route.dart';
import '../providers/groups_providers.dart';
import 'gradient_create_button.dart';
import 'group_list_card.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsStreamProvider(user.uid));
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return PremiumBackground(
      child: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load groups', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(userGroupsStreamProvider(user.uid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groups) {
          final count = groups.length;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: AppLayout.scrollPadding(context),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppLayout.contentMaxWidth(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Groups',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$count ${count == 1 ? 'group' : 'groups'}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientCreateButton(
                            label: 'Create Group',
                            onPressed: () => openCreateGroupScreen(
                              context,
                              user,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (groups.isEmpty)
                            GroupsEmptyState(muted: muted)
                          else
                            Text(
                              'Your groups',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (groups.isNotEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppLayout.pagePadding(context).left,
                    0,
                    AppLayout.pagePadding(context).right,
                    AppLayout.scrollPadding(context).bottom,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    AppLayout.contentMaxWidth(context),
                              ),
                              child: GroupListCard(
                                group: group.toOverview(),
                                user: user,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class GroupsEmptyState extends StatelessWidget {
  const GroupsEmptyState({required this.muted, super.key});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group and invite members. Everyone you add will see the group instantly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
