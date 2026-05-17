import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/json_helpers.dart';
import '../models/activity_log_item.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_summary.dart';
import '../models/group_overview.dart';
import '../models/monthly_spending.dart';
import '../models/pending_balance.dart';
import '../models/recent_expense_item.dart';
import '../../expenses/services/expense_service.dart';

class DashboardService {
  DashboardService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<DashboardData> fetchDashboard(String uid) async {
    final raw = await _client.rpc('get_dashboard_analytics');
    final data = Map<String, dynamic>.from(raw as Map);

    final groups = (data['groups'] as List? ?? [])
        .map((g) => Map<String, dynamic>.from(g as Map))
        .where((g) => _userBelongsToGroup(g, uid))
        .map(_parseGroup)
        .toList();
    final expenses = (data['expenses'] as List? ?? [])
        .map((e) => _parseExpense(Map<String, dynamic>.from(e as Map)))
        .toList();
    final memberGroupIds = groups.map((g) => g.groupId).toSet();
    final groupMap = {for (final g in groups) g.groupId: g};

    final summary = _computeSummary(uid, expenses);
    final expenseByGroup = _expenseByGroup(expenses, uid);
    final expenseByCategory = _expenseByCategory(expenses, uid);
    final groupOverviews = _buildGroupOverviews(groups, expenses, uid)
      ..sort((a, b) {
        final at = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
    final monthlySpending = _monthlySpending(expenses, uid);
    final pendingBalances = _pendingBalances(uid, expenses);
    final activities = _parseLogs(
      data['logs'] as List? ?? [],
      groupMap,
    ).where((a) {
      if (a.type == ActivityType.groupDeleted) return true;
      final gid = a.groupId;
      return gid == null || gid.isEmpty || memberGroupIds.contains(gid);
    }).toList();
    final recentExpenses = _buildRecentExpenses(expenses, uid);
    final mostActiveGroup = _mostActiveGroup(groupOverviews);
    final topCategoryThisMonth = _topCategoryThisMonth(expenses, uid);

    return DashboardData(
      summary: summary,
      groups: groupOverviews,
      activities: activities,
      pendingBalances: pendingBalances,
      monthlySpending: monthlySpending,
      expenseByGroup: expenseByGroup,
      expenseByCategory: expenseByCategory,
      recentExpenses: recentExpenses,
      mostActiveGroup: mostActiveGroup,
      topCategoryThisMonth: topCategoryThisMonth,
    );
  }

  GroupOverview _parseGroup(Map<String, dynamic> data) {
    final memberIds = parseUuidList(data['member_ids'] ?? data['memberIds']);
    final updatedAt = parseDateTime(data['updated_at'] ?? data['updatedAt']);
    final lastExpenseAt =
        parseDateTime(data['last_expense_at'] ?? data['lastExpenseAt']);
    final createdAt = parseDateTime(data['created_at'] ?? data['createdAt']);
    DateTime? lastActivity = updatedAt;
    if (lastExpenseAt != null &&
        (lastActivity == null || lastExpenseAt.isAfter(lastActivity))) {
      lastActivity = lastExpenseAt;
    }

    return GroupOverview(
      groupId: data['id'] as String? ?? data['groupId'] as String? ?? '',
      groupName: data['group_name'] as String? ?? data['groupName'] as String? ?? 'Group',
      groupImage: data['group_image'] as String? ?? data['groupImage'] as String? ?? '',
      memberCount: memberIds.length,
      totalExpense: (data['total_expense'] as num? ?? data['totalExpense'] as num?)
              ?.toDouble() ??
          0,
      yourBalance: 0,
      groupType: data['group_type'] as String? ?? data['groupType'] as String? ?? 'room',
      createdAt: createdAt,
      lastActivityAt: lastActivity ?? createdAt,
    );
  }

  _ExpenseDoc _parseExpense(Map<String, dynamic> data) {
    final splitsRaw = data['splits'] as List? ?? [];
    final splits = splitsRaw.map((s) {
      final map = Map<String, dynamic>.from(s as Map);
      return _SplitPart(
        userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
        userName: map['userName'] as String? ?? map['user_name'] as String? ?? 'Member',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    final title = data['title'] as String? ?? 'Expense';
    return _ExpenseDoc(
      id: data['id'] as String? ?? '',
      groupId: data['group_id'] as String? ?? data['groupId'] as String? ?? '',
      groupName: data['group_name'] as String? ?? data['groupName'] as String? ?? '',
      title: title,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paid_by'] as String? ?? data['paidBy'] as String? ?? '',
      paidByName: data['paid_by_name'] as String? ?? data['paidByName'] as String? ?? 'Someone',
      createdAt: parseDateTime(data['created_at'] ?? data['createdAt']),
      category: data['category'] as String? ?? inferExpenseCategory(title),
      splits: splits,
    );
  }

  List<ActivityLogItem> _parseLogs(
    List<dynamic> logsRaw,
    Map<String, GroupOverview> groupMap,
  ) {
    final logs = <ActivityLogItem>[];

    for (final raw in logsRaw) {
      final data = Map<String, dynamic>.from(raw as Map);
      logs.add(_parseLog(data, groupMap));
    }

    logs.sort((a, b) {
      final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return logs.take(20).toList();
  }

  bool _userBelongsToGroup(Map<String, dynamic> group, String uid) {
    final memberIds = parseUuidList(group['member_ids'] ?? group['memberIds']);
    final createdBy =
        group['created_by'] as String? ?? group['createdBy'] as String? ?? '';
    return createdBy == uid || memberIds.contains(uid);
  }

  double _userShare(_ExpenseDoc expense, String uid) {
    return expense.splits
        .where((s) => s.userId == uid)
        .fold<double>(0, (total, s) => total + s.amount);
  }

  Map<String, double> _expenseByCategory(
    List<_ExpenseDoc> expenses,
    String uid,
  ) {
    final map = <String, double>{};
    for (final e in expenses) {
      final share = _userShare(e, uid);
      if (share <= 0) continue;
      map[e.category] = (map[e.category] ?? 0) + share;
    }
    return map;
  }

  GroupOverview? _mostActiveGroup(List<GroupOverview> groups) {
    if (groups.isEmpty) return null;
    return groups.reduce(
      (a, b) => a.totalExpense >= b.totalExpense ? a : b,
    );
  }

  String _topCategoryThisMonth(List<_ExpenseDoc> expenses, String uid) {
    final map = <String, double>{};
    for (final e in expenses) {
      if (!_isThisMonth(e.createdAt)) continue;
      final share = _userShare(e, uid);
      if (share <= 0) continue;
      map[e.category] = (map[e.category] ?? 0) + share;
    }
    if (map.isEmpty) return 'Other';
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  bool _isThisMonth(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  DashboardSummary _computeSummary(String uid, List<_ExpenseDoc> expenses) {
    var totalSpent = 0.0;
    var needToPay = 0.0;
    var willReceive = 0.0;
    var monthYouPaid = 0.0;
    var monthNeedToPay = 0.0;
    var monthTotalSpent = 0.0;
    var monthWillReceive = 0.0;

    for (final expense in expenses) {
      final mySplit = expense.splits
          .where((s) => s.userId == uid)
          .fold<double>(0, (total, s) => total + s.amount);
      final inMonth = _isThisMonth(expense.createdAt);

      if (expense.paidBy == uid) {
        totalSpent += expense.amount;
        if (inMonth) {
          monthYouPaid += expense.amount;
          monthTotalSpent += expense.amount;
        }
        for (final split in expense.splits) {
          if (split.userId != uid) {
            willReceive += split.amount;
            if (inMonth) monthWillReceive += split.amount;
          }
        }
      } else {
        needToPay += mySplit;
        if (inMonth) monthNeedToPay += mySplit;
      }
    }

    return DashboardSummary(
      totalSpent: totalSpent,
      needToPay: needToPay,
      willReceive: willReceive,
      monthYouPaid: monthYouPaid,
      monthNeedToPay: monthNeedToPay,
      monthTotalSpent: monthTotalSpent,
      monthWillReceive: monthWillReceive,
    );
  }

  List<RecentExpenseItem> _buildRecentExpenses(
    List<_ExpenseDoc> expenses,
    String uid,
  ) {
    final sorted = List<_ExpenseDoc>.from(expenses)
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    return sorted.take(8).map((e) {
      var impact = 0.0;
      if (e.paidBy == uid) {
        impact = e.splits
            .where((s) => s.userId != uid)
            .fold<double>(0, (t, s) => t + s.amount);
      } else {
        impact = -e.splits
            .where((s) => s.userId == uid)
            .fold<double>(0, (t, s) => t + s.amount);
      }
      return RecentExpenseItem(
        id: e.id,
        groupId: e.groupId,
        groupName: e.groupName,
        title: e.title,
        amount: e.amount,
        paidByName: e.paidByName,
        createdAt: e.createdAt,
        balanceImpact: impact,
      );
    }).toList();
  }

  Map<String, double> _expenseByGroup(List<_ExpenseDoc> expenses, String uid) {
    final map = <String, double>{};
    for (final e in expenses) {
      final share = _userShare(e, uid);
      if (share <= 0) continue;
      map[e.groupId] = (map[e.groupId] ?? 0) + share;
    }
    return map;
  }

  List<GroupOverview> _buildGroupOverviews(
    List<GroupOverview> groups,
    List<_ExpenseDoc> expenses,
    String uid,
  ) {
    return groups.map((group) {
      final groupExpenses =
          expenses.where((e) => e.groupId == group.groupId).toList();
      final totalExpense =
          groupExpenses.fold<double>(0, (total, e) => total + e.amount);

      var balance = 0.0;
      for (final expense in groupExpenses) {
        if (expense.paidBy == uid) {
          for (final split in expense.splits) {
            if (split.userId != uid) balance += split.amount;
          }
        } else {
          final owed = expense.splits
              .where((s) => s.userId == uid)
              .fold<double>(0, (total, s) => total + s.amount);
          balance -= owed;
        }
      }

      return GroupOverview(
        groupId: group.groupId,
        groupName: group.groupName,
        groupImage: group.groupImage,
        memberCount: group.memberCount,
        totalExpense: totalExpense,
        yourBalance: balance,
        groupType: group.groupType,
        createdAt: group.createdAt,
        lastActivityAt: group.lastActivityAt,
      );
    }).toList();
  }

  List<MonthlySpending> _monthlySpending(List<_ExpenseDoc> expenses, String uid) {
    final now = DateTime.now();
    final months = <MonthlySpending>[];

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add(
        MonthlySpending(
          monthLabel: _monthLabel(date.month),
          amount: 0,
          month: date.month,
          year: date.year,
        ),
      );
    }

    for (final expense in expenses) {
      final share = _userShare(expense, uid);
      if (share <= 0) continue;

      final date = expense.createdAt ?? now;
      for (var j = 0; j < months.length; j++) {
        final bucket = months[j];
        if (bucket.year == date.year && bucket.month == date.month) {
          months[j] = MonthlySpending(
            monthLabel: bucket.monthLabel,
            amount: bucket.amount + share,
            month: bucket.month,
            year: bucket.year,
          );
          break;
        }
      }
    }

    return months;
  }

  List<PendingBalance> _pendingBalances(String uid, List<_ExpenseDoc> expenses) {
    final balanceMap = <String, _PersonBalance>{};

    for (final expense in expenses) {
      if (expense.paidBy == uid) {
        for (final split in expense.splits) {
          if (split.userId == uid) continue;
          final entry = balanceMap.putIfAbsent(
            split.userId,
            () => _PersonBalance(split.userId, split.userName),
          );
          entry.theyOweYou += split.amount;
        }
      } else {
        final mySplit = expense.splits.where((s) => s.userId == uid);
        for (final split in mySplit) {
          final entry = balanceMap.putIfAbsent(
            expense.paidBy,
            () => _PersonBalance(expense.paidBy, expense.paidByName),
          );
          entry.youOweThem += split.amount;
        }
      }
    }

    final results = <PendingBalance>[];
    for (final entry in balanceMap.values) {
      final net = entry.theyOweYou - entry.youOweThem;
      if (net.abs() < 0.01) continue;
      results.add(
        PendingBalance(
          userId: entry.userId,
          name: entry.name,
          amount: net.abs(),
          isOwedToYou: net > 0,
        ),
      );
    }

    results.sort((a, b) => b.amount.compareTo(a.amount));
    return results;
  }

  ActivityLogItem _parseLog(
    Map<String, dynamic> data,
    Map<String, GroupOverview> groupMap,
  ) {
    final action = data['action_type'] as String? ?? data['actionType'] as String? ?? '';
    final creator = data['created_by_name'] as String? ?? data['creatorName'] as String? ?? 'Someone';
    final groupId = data['group_id'] as String? ?? data['groupId'] as String? ?? '';
    final group = groupMap[groupId];
    final groupName =
        group?.groupName ??
        (data['group_data'] as Map?)?['groupName'] as String? ??
        'Group';
    final groupImage = group?.groupImage ?? '';

    ActivityType type;
    String title;
    String subtitle;

    switch (action) {
      case 'GROUP_CREATED':
        type = ActivityType.groupCreated;
        title = 'Group created';
        subtitle = data['action_message'] as String? ??
            '$creator created this group';
        break;
      case 'GROUP_UPDATED':
        type = ActivityType.groupUpdated;
        title = 'Group updated';
        subtitle = '$creator updated the group';
        break;
      case 'EXPENSE_ADDED':
        type = ActivityType.expenseAdded;
        title = 'Expense added';
        final addedData = data['expense_data'] as Map?;
        final addedTitle = addedData?['title'] as String?;
        subtitle = addedTitle != null
            ? '$creator added "$addedTitle"'
            : '$creator added an expense';
        break;
      case 'EXPENSE_UPDATED':
        type = ActivityType.expenseUpdated;
        title = 'Expense updated';
        final updatedData = data['expense_data'] as Map?;
        final updatedTitle = updatedData?['title'] as String?;
        subtitle = updatedTitle != null
            ? '$creator updated "$updatedTitle"'
            : '$creator updated an expense';
        break;
      case 'EXPENSE_DELETED':
        type = ActivityType.expenseDeleted;
        title = 'Expense deleted';
        final deletedExp = data['deleted_snapshot'] as Map?;
        final deletedTitle = deletedExp?['title'] as String?;
        subtitle = deletedTitle != null
            ? '$creator deleted "$deletedTitle"'
            : '$creator deleted an expense';
        break;
      case 'GROUP_DELETED':
        type = ActivityType.groupDeleted;
        title = 'Group deleted';
        final deletedGroup = data['deleted_snapshot'] as Map?;
        final deletedGroupName = deletedGroup?['group']?['group_name'] as String? ??
            deletedGroup?['group']?['groupName'] as String? ??
            groupName;
        subtitle = '$creator deleted "$deletedGroupName"';
        break;
      case 'MEMBER_JOINED':
        type = ActivityType.memberJoined;
        title = 'Member joined';
        subtitle = '$creator added a member';
        break;
      case 'MEMBER_REMOVED':
        type = ActivityType.memberRemoved;
        title = 'Member removed';
        final removed = data['deleted_snapshot'] as Map?;
        final removedName = removed?['name'] as String? ?? 'A member';
        subtitle = '$creator removed $removedName';
        break;
      case 'SETTLEMENT':
        type = ActivityType.settlement;
        title = 'Settlement done';
        subtitle = '$creator settled up';
        break;
      case 'ACTIVITY_RESTORED':
        type = ActivityType.activityRestored;
        title = 'Restored';
        subtitle = '$creator restored a deleted item';
        break;
      default:
        type = ActivityType.unknown;
        title = action.replaceAll('_', ' ');
        subtitle = groupName;
    }

    final isRestored = data['restored'] == true;
    final expenseData = data['expense_data'] as Map?;
    final memberData = data['member_data'] as Map?;
    final deletedSnapshot = data['deleted_snapshot'] as Map?;
    String? relatedId;
    double? amount;

    if (type == ActivityType.expenseAdded ||
        type == ActivityType.expenseUpdated) {
      relatedId = expenseData?['expenseId'] as String? ??
          expenseData?['expense_id'] as String?;
      amount = (expenseData?['amount'] as num?)?.toDouble();
    } else if (type == ActivityType.expenseDeleted) {
      relatedId = deletedSnapshot?['expenseId'] as String? ??
          deletedSnapshot?['id'] as String?;
      amount = (deletedSnapshot?['amount'] as num?)?.toDouble();
    } else if (type == ActivityType.groupDeleted) {
      final g = deletedSnapshot?['group'] as Map?;
      relatedId = g?['id'] as String? ?? deletedSnapshot?['groupId'] as String?;
    } else if (type == ActivityType.memberJoined) {
      relatedId = memberData?['uid'] as String?;
    } else if (type == ActivityType.memberRemoved) {
      relatedId = deletedSnapshot?['uid'] as String?;
    }

    final canUndo = !isRestored &&
        (type == ActivityType.expenseDeleted ||
            type == ActivityType.groupDeleted ||
            type == ActivityType.memberRemoved);

    return ActivityLogItem(
      id: data['id'] as String? ?? '',
      title: title,
      subtitle: subtitle,
      timestamp: parseDateTime(data['timestamp'] ?? data['created_at']),
      type: type,
      amount: amount,
      groupName: groupName,
      groupId: groupId,
      groupImage: groupImage,
      relatedId: relatedId,
      actorName: creator,
      canUndo: canUndo,
      isRestored: isRestored,
    );
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month - 1];
  }
}

class _ExpenseDoc {
  const _ExpenseDoc({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.category,
    required this.splits,
    this.createdAt,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final double amount;
  final String paidBy;
  final String paidByName;
  final DateTime? createdAt;
  final String category;
  final List<_SplitPart> splits;
}

class _SplitPart {
  const _SplitPart({
    required this.userId,
    required this.userName,
    required this.amount,
  });

  final String userId;
  final String userName;
  final double amount;
}

class _PersonBalance {
  _PersonBalance(this.userId, this.name);

  final String userId;
  final String name;
  double youOweThem = 0;
  double theyOweYou = 0;
}
