import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../expenses/add_expense_route.dart';
import '../../expenses/providers/expense_providers.dart';
import '../models/group_overview.dart';
import '../providers/dashboard_providers.dart';

class AddExpenseFab extends ConsumerWidget {
  const AddExpenseFab({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _onTap(context, ref),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Expense',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final data = await ref.read(dashboardDataProvider(user.uid).future);
    if (!context.mounted) return;

    if (data.groups.isEmpty) {
      showAppSnackBar(
        context,
        'Create a group first from the Groups tab.',
        isError: true,
      );
      return;
    }

    GroupOverview group;
    if (data.groups.length == 1) {
      group = data.groups.first;
    } else {
      final index = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (ctx) => _GroupPickerSheet(groups: data.groups),
      );
      if (index == null || !context.mounted) return;
      group = data.groups[index];
    }

    try {
      final ctx = await ref
          .read(expenseServiceProvider)
          .loadGroupContext(group.groupId);
      if (!context.mounted) return;
      await openAddExpenseScreen(
        context,
        user: user,
        groupId: ctx.groupId,
        groupName: ctx.groupName,
        members: ctx.members,
        memberIds: ctx.memberIds,
      );
    } catch (error) {
      if (!context.mounted) return;
      showAppSnackBar(context, 'Could not open expense form.', isError: true);
    }
  }
}

class _GroupPickerSheet extends StatelessWidget {
  const _GroupPickerSheet({required this.groups});

  final List<GroupOverview> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Material(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder(brightness),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select a group',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: groups.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final g = groups[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      child: Text(
                        g.groupName.isNotEmpty
                            ? g.groupName[0].toUpperCase()
                            : 'G',
                        style: TextStyle(
                          color: AppColors.primaryColor(brightness),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(g.groupName),
                    subtitle: Text('${g.memberCount} members'),
                    onTap: () => Navigator.pop(context, index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
