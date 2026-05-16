import 'activity_log_item.dart';
import 'dashboard_summary.dart';
import 'group_overview.dart';
import 'monthly_spending.dart';
import 'pending_balance.dart';
import 'recent_expense_item.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.groups,
    required this.activities,
    required this.pendingBalances,
    required this.monthlySpending,
    required this.expenseByGroup,
    required this.expenseByCategory,
    required this.recentExpenses,
    this.mostActiveGroup,
    this.topCategoryThisMonth = 'Other',
  });

  final DashboardSummary summary;
  final List<GroupOverview> groups;
  final List<ActivityLogItem> activities;
  final List<PendingBalance> pendingBalances;
  final List<MonthlySpending> monthlySpending;
  final Map<String, double> expenseByGroup;
  final Map<String, double> expenseByCategory;
  final List<RecentExpenseItem> recentExpenses;
  final GroupOverview? mostActiveGroup;
  final String topCategoryThisMonth;

  static const empty = DashboardData(
    summary: DashboardSummary(),
    groups: [],
    activities: [],
    pendingBalances: [],
    monthlySpending: [],
    expenseByGroup: {},
    expenseByCategory: {},
    recentExpenses: [],
  );

  bool get hasGroups => groups.isNotEmpty;
  bool get hasExpenses =>
      summary.totalSpent > 0 || expenseByGroup.isNotEmpty;
  bool get hasActivities => activities.isNotEmpty;
  bool get hasPending => pendingBalances.isNotEmpty;
}
