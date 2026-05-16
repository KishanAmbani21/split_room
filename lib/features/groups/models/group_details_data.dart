import '../../dashboard/models/activity_log_item.dart';
import '../../dashboard/models/monthly_spending.dart';
import 'group_expense.dart';
import 'group_member_balance.dart';

class GroupDetailsData {
  const GroupDetailsData({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.groupType,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.memberCount,
    required this.totalSpent,
    required this.monthSpent,
    required this.pendingBalanceCount,
    required this.youOwe,
    required this.youGetBack,
    required this.members,
    required this.expenses,
    required this.expenseByMember,
    required this.monthlySpending,
    required this.activities,
  });

  final String groupId;
  final String groupName;
  final String groupImage;
  final String groupType;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final int memberCount;
  final double totalSpent;
  final double monthSpent;
  final int pendingBalanceCount;
  final double youOwe;
  final double youGetBack;
  final List<GroupMemberBalance> members;
  final List<GroupExpense> expenses;
  final Map<String, double> expenseByMember;
  final List<MonthlySpending> monthlySpending;
  final List<ActivityLogItem> activities;

  bool get hasExpenses => expenses.isNotEmpty;
  bool get hasActivities => activities.isNotEmpty;

  double get yourNetBalance => youGetBack - youOwe;
}
