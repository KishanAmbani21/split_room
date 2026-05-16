import 'package:flutter/material.dart';

import '../../shared/models/app_user.dart';
import '../groups/models/group_member_balance.dart';
import 'models/expense_group_member.dart';
import 'screens/add_expense_screen.dart';

Future<bool?> openAddExpenseScreen(
  BuildContext context, {
  required AppUser user,
  required String groupId,
  required String groupName,
  required List<ExpenseGroupMember> members,
  required List<String> memberIds,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => AddExpenseScreen(
        user: user,
        groupId: groupId,
        groupName: groupName,
        members: members,
        memberIds: memberIds,
      ),
    ),
  );
}

List<ExpenseGroupMember> expenseMembersFromBalances(
  List<GroupMemberBalance> balances,
) {
  return balances
      .map(
        (m) => ExpenseGroupMember(
          uid: m.userId,
          name: m.name,
          profileImage: m.profileImage,
          isCreator: m.isCreator,
        ),
      )
      .toList();
}
