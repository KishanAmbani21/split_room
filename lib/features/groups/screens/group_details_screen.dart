import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart' show PremiumBackground;
import '../../expenses/add_expense_route.dart';
import '../../expenses/edit_expense_route.dart';
import '../add_members_route.dart';
import '../edit_group_route.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../models/group_details_data.dart';
import '../models/group_expense.dart';
import '../providers/group_details_providers.dart';
import '../services/group_details_service.dart';
import '../widgets/group_details/add_group_expense_fab.dart';
import '../widgets/group_details/group_balance_summary.dart';
import '../widgets/group_details/group_expense_list.dart';
import '../widgets/group_details/splitwise_tab_bar.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  const GroupDetailsScreen({
    required this.user,
    required this.groupId,
    super.key,
  });

  final AppUser user;
  final String groupId;

  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = (groupId: widget.groupId, userId: widget.user.uid);
    final detailsAsync = ref.watch(groupDetailsStreamProvider(params));

    return PremiumBackground(
      child: detailsAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: _ErrorBody(
            message: groupDetailsErrorMessage(error),
            onRetry: () => ref.invalidate(groupDetailsStreamProvider(params)),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final params = (groupId: widget.groupId, userId: widget.user.uid);
          final userName =
              widget.user.fullName.isEmpty ? 'You' : widget.user.fullName;
          void refresh() {
            ref.invalidate(groupDetailsStreamProvider(params));
            ref.invalidate(dashboardDataProvider(widget.user.uid));
          }

          Future<void> editExpense(GroupExpense expense) async {
            final updated = await openEditExpenseScreen(
              context,
              user: widget.user,
              expense: expense,
              groupName: data.groupName,
              members: expenseMembersFromBalances(data.members),
              memberIds: data.memberIds,
            );
            if (updated == true) refresh();
          }

          return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: AddGroupExpenseFab(
            user: widget.user,
            groupId: widget.groupId,
            groupName: data.groupName,
            members: expenseMembersFromBalances(data.members),
            memberIds: data.memberIds,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupDetailsTopBar(
                groupName: data.groupName,
                onBack: () => Navigator.of(context).pop(),
                onAddMembers: () => _openAddMembers(context, data),
                onMore: () => _showOptions(context),
              ),
              GroupBalanceSummary(data: data),
              SplitwiseTabBar(controller: _tabController),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    GroupExpenseList(
                      data: data,
                      currentUserId: widget.user.uid,
                      userName: userName,
                      filter: ExpenseFilter.overall,
                      onEditExpense: editExpense,
                      onExpenseChanged: refresh,
                    ),
                    GroupExpenseList(
                      data: data,
                      currentUserId: widget.user.uid,
                      userName: userName,
                      filter: ExpenseFilter.paidByMe,
                      onEditExpense: editExpense,
                      onExpenseChanged: refresh,
                    ),
                    GroupExpenseList(
                      data: data,
                      currentUserId: widget.user.uid,
                      userName: userName,
                      filter: ExpenseFilter.othersPaid,
                      onEditExpense: editExpense,
                      onExpenseChanged: refresh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Future<void> _openAddMembers(BuildContext context, GroupDetailsData data) async {
    final params = (groupId: widget.groupId, userId: widget.user.uid);
    final added = await openAddMembersScreen(
      context,
      user: widget.user,
      groupId: widget.groupId,
      groupName: data.groupName,
    );
    if (added == true && mounted) {
      ref.invalidate(groupDetailsStreamProvider(params));
      ref.invalidate(dashboardDataProvider(widget.user.uid));
    }
  }

  Future<void> _showOptions(BuildContext context) async {
    final params = (groupId: widget.groupId, userId: widget.user.uid);
    final data = ref.read(groupDetailsStreamProvider(params)).value;
    if (data == null) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit group'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text('Delete group', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'edit':
        final updated = await openEditGroupScreen(
          context,
          user: widget.user,
          groupId: widget.groupId,
        );
        if (updated == true && context.mounted) {
          ref.invalidate(groupDetailsStreamProvider(params));
          ref.invalidate(dashboardDataProvider(widget.user.uid));
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete group?'),
            content: Text(
              'This will permanently delete "${data.groupName}" and all expenses.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          await ref.read(groupDetailsServiceProvider).deleteGroup(
                groupId: widget.groupId,
                currentUserId: widget.user.uid,
              );
          if (!context.mounted) return;
          showAppSnackBar(context, 'Group deleted');
          Navigator.of(context).pop(true);
        } catch (error) {
          if (!context.mounted) return;
          showAppSnackBar(
            context,
            groupDetailsErrorMessage(error),
            isError: true,
          );
        }
    }
  }
}

class _GroupDetailsTopBar extends StatelessWidget {
  const _GroupDetailsTopBar({
    required this.groupName,
    required this.onBack,
    required this.onAddMembers,
    required this.onMore,
  });

  final String groupName;
  final VoidCallback onBack;
  final VoidCallback onAddMembers;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: onBack,
            ),
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add members',
              onPressed: onAddMembers,
            ),
            Expanded(
              child: Text(
                groupName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
