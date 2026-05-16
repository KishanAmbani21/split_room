import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import '../groups/models/group_expense.dart';
import 'models/expense_group_member.dart';
import 'screens/edit_expense_screen.dart';

Future<bool?> openEditExpenseScreen(
  BuildContext context, {
  required AppUser user,
  required GroupExpense expense,
  required String groupName,
  required List<ExpenseGroupMember> members,
  required List<String> memberIds,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => EditExpenseScreen(
        user: user,
        expense: expense,
        groupName: groupName,
        members: members,
        memberIds: memberIds,
      ),
    ),
  );
}
