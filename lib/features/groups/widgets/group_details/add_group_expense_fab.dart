import 'package:flutter/material.dart';

import '../../../../shared/models/app_user.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../expenses/add_expense_route.dart';
import '../../../expenses/models/expense_group_member.dart';

class AddGroupExpenseFab extends StatelessWidget {
  const AddGroupExpenseFab({
    required this.user,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberIds,
    super.key,
  });

  final AppUser user;
  final String groupId;
  final String groupName;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryColor(Theme.of(context).brightness);

    return FloatingActionButton.extended(
      onPressed: () => openAddExpenseScreen(
        context,
        user: user,
        groupId: groupId,
        groupName: groupName,
        members: members,
        memberIds: memberIds,
      ),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 2,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Add Expense',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
