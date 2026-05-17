import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_realtime_service.dart';
import '../../../core/utils/json_helpers.dart';
import '../../dashboard/models/activity_log_item.dart';
import '../../dashboard/models/monthly_spending.dart';
import '../models/group_details_data.dart';
import '../models/group_expense.dart';
import '../models/group_json_helpers.dart';
import '../models/group_member_balance.dart';

class GroupDetailsService {
  GroupDetailsService({
    SupabaseClient? client,
    SupabaseRealtimeService? realtime,
  })  : _client = client ?? Supabase.instance.client,
        _realtime = realtime ?? SupabaseRealtimeService();

  final SupabaseClient _client;
  final SupabaseRealtimeService _realtime;

  Stream<GroupDetailsData> watchGroupDetails({
    required String groupId,
    required String currentUserId,
  }) {
    final controller = StreamController<GroupDetailsData>.broadcast();

    Map<String, dynamic>? groupData;
    List<Map<String, dynamic>>? expenseRows;
    List<Map<String, dynamic>>? logRows;

    void emit() {
      if (groupData == null || expenseRows == null || logRows == null) return;
      try {
        controller.add(
          _buildData(
            groupData: groupData!,
            expenseRows: expenseRows!,
            logRows: logRows!,
            currentUserId: currentUserId,
          ),
        );
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    final subs = <StreamSubscription<dynamic>>[
      _realtime.watchGroup(groupId).listen((g) {
        if (g != null) groupData = g;
        emit();
      }, onError: controller.addError),
      _realtime.watchGroupExpenses(groupId).listen((rows) {
        expenseRows = rows;
        emit();
      }, onError: controller.addError),
      _realtime.watchGroupLogs(groupId).listen((rows) {
        logRows = rows;
        emit();
      }, onError: controller.addError),
    ];

    controller.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> deleteGroup({
    required String groupId,
    required String currentUserId,
  }) async {
    final row = await _client
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .maybeSingle();
    if (row == null) {
      throw const GroupDetailsException('Group not found.');
    }

    final createdBy = row['created_by'] as String? ?? '';
    if (createdBy != currentUserId) {
      throw const GroupDetailsException(
        'Only the group creator can delete this group.',
      );
    }

    await _client.from('expenses').delete().eq('group_id', groupId);
    await _client.from('group_logs').delete().eq('group_id', groupId);
    await _client.from('group_members').delete().eq('group_id', groupId);
    await _client.from('groups').delete().eq('id', groupId);
  }

  GroupDetailsData _buildData({
    required Map<String, dynamic> groupData,
    required List<Map<String, dynamic>> expenseRows,
    required List<Map<String, dynamic>> logRows,
    required String currentUserId,
  }) {
    final membersRaw = groupData['member_details'] as List? ??
        groupData['memberDetails'] as List? ??
        [];
    final memberIds = parseMemberIds(groupData);

    final membersMeta = <String, _MemberMeta>{};
    for (final raw in membersRaw) {
      final map = Map<String, dynamic>.from(raw as Map);
      final uid = map['uid'] as String? ?? '';
      if (uid.isEmpty) continue;
      membersMeta[uid] = _MemberMeta(
        uid: uid,
        name: map['name'] as String? ?? 'Member',
        profileImage: map['profileImage'] as String?,
        isCreator: map['isCreator'] as bool? ?? false,
      );
    }

    final expenses = expenseRows.map(_parseExpense).toList()
      ..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });

    final totalSpent = expenses.fold<double>(0, (t, e) => t + e.amount);
    final monthSpent = _thisMonthSpent(expenses);
    final memberBalances = _memberBalances(membersMeta, memberIds, expenses);
    final (youOwe, youGetBack) = _yourBalances(currentUserId, expenses);
    final expenseByMember = _expenseByMemberShare(expenses);
    final monthlySpending = _monthlySpending(expenses);
    final groupName = groupData['group_name'] as String? ??
        groupData['groupName'] as String? ??
        'Group';
    final activities = _parseActivities(logRows, groupName);

    final pendingCount =
        memberBalances.where((m) => !m.isSettled).length;

    return GroupDetailsData(
      groupId: groupData['id'] as String? ?? groupData['groupId'] as String? ?? '',
      groupName: groupName,
      groupImage: groupData['group_image'] as String? ??
          groupData['groupImage'] as String? ??
          '',
      groupType: groupData['group_type'] as String? ??
          groupData['groupType'] as String? ??
          'room',
      description: groupData['description'] as String? ?? '',
      createdBy: groupData['created_by'] as String? ??
          groupData['createdBy'] as String? ??
          '',
      memberIds: memberIds,
      memberCount: memberIds.length,
      totalSpent: totalSpent,
      monthSpent: monthSpent,
      pendingBalanceCount: pendingCount,
      youOwe: youOwe,
      youGetBack: youGetBack,
      members: memberBalances,
      expenses: expenses,
      expenseByMember: expenseByMember,
      monthlySpending: monthlySpending,
      activities: activities,
    );
  }

  GroupExpense _parseExpense(Map<String, dynamic> data) {
    final splitsRaw = data['expense_splits'] as List? ?? data['splits'] as List? ?? [];
    final splits = splitsRaw.map((s) {
      final map = Map<String, dynamic>.from(s as Map);
      return ExpenseSplit(
        userId: map['user_id'] as String? ?? map['userId'] as String? ?? '',
        userName: map['user_name'] as String? ?? map['userName'] as String? ?? 'Member',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return GroupExpense(
      id: data['id'] as String? ?? data['expenseId'] as String? ?? '',
      groupId: data['group_id'] as String? ?? data['groupId'] as String? ?? '',
      title: data['title'] as String? ?? 'Expense',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paid_by'] as String? ?? data['paidBy'] as String? ?? '',
      paidByName: data['paid_by_name'] as String? ?? data['paidByName'] as String? ?? 'Someone',
      createdAt: parseDateTime(data['created_at'] ?? data['createdAt']),
      splits: splits,
    );
  }

  double _thisMonthSpent(List<GroupExpense> expenses) {
    final now = DateTime.now();
    return expenses
        .where((e) {
          final d = e.createdAt;
          return d != null && d.year == now.year && d.month == now.month;
        })
        .fold<double>(0, (t, e) => t + e.amount);
  }

  (double, double) _yourBalances(String uid, List<GroupExpense> expenses) {
    var youOwe = 0.0;
    var youGetBack = 0.0;

    for (final expense in expenses) {
      final mySplit = expense.splits
          .where((s) => s.userId == uid)
          .fold<double>(0, (t, s) => t + s.amount);

      if (expense.paidBy == uid) {
        for (final split in expense.splits) {
          if (split.userId != uid) youGetBack += split.amount;
        }
      } else {
        youOwe += mySplit;
      }
    }

    return (youOwe, youGetBack);
  }

  List<GroupMemberBalance> _memberBalances(
    Map<String, _MemberMeta> membersMeta,
    List<String> memberIds,
    List<GroupExpense> expenses,
  ) {
    final balances = <String, double>{for (final id in memberIds) id: 0};

    for (final expense in expenses) {
      for (final split in expense.splits) {
        if (split.userId == expense.paidBy) continue;
        if (split.userId.isEmpty) continue;

        balances[split.userId] = (balances[split.userId] ?? 0) - split.amount;
        balances[expense.paidBy] =
            (balances[expense.paidBy] ?? 0) + split.amount;
      }
    }

    return memberIds.map((id) {
      final meta = membersMeta[id];
      return GroupMemberBalance(
        userId: id,
        name: meta?.name ?? 'Member',
        balance: balances[id] ?? 0,
        profileImage: meta?.profileImage,
        isCreator: meta?.isCreator ?? false,
      );
    }).toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
  }

  Map<String, double> _expenseByMemberShare(List<GroupExpense> expenses) {
    final map = <String, double>{};
    for (final expense in expenses) {
      for (final split in expense.splits) {
        if (split.userId.isEmpty) continue;
        map[split.userName] = (map[split.userName] ?? 0) + split.amount;
      }
    }
    return map;
  }

  List<MonthlySpending> _monthlySpending(List<GroupExpense> expenses) {
    final now = DateTime.now();
    final months = <String, MonthlySpending>{};

    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = '${date.year}-${date.month}';
      months[key] = MonthlySpending(
        monthLabel: _monthLabel(date.month),
        amount: 0,
        month: date.month,
        year: date.year,
      );
    }

    for (final expense in expenses) {
      final date = expense.createdAt ?? now;
      final key = '${date.year}-${date.month}';
      if (months.containsKey(key)) {
        final current = months[key]!;
        months[key] = MonthlySpending(
          monthLabel: current.monthLabel,
          amount: current.amount + expense.amount,
          month: current.month,
          year: current.year,
        );
      }
    }

    return months.values.toList();
  }

  List<ActivityLogItem> _parseActivities(
    List<Map<String, dynamic>> logRows,
    String groupName,
  ) {
    final logs = logRows.map((data) {
      final action = data['action_type'] as String? ??
          data['actionType'] as String? ??
          '';
      final creator = data['created_by_name'] as String? ??
          data['creatorName'] as String? ??
          'Someone';

      ActivityType type;
      String title;
      String subtitle;

      switch (action) {
        case 'GROUP_CREATED':
          type = ActivityType.groupCreated;
          title = 'Group created';
          subtitle = '$creator created "$groupName"';
          break;
        case 'EXPENSE_ADDED':
          type = ActivityType.expenseAdded;
          title = 'Expense added';
          subtitle = '$creator added an expense';
          break;
        case 'MEMBER_JOINED':
          type = ActivityType.memberJoined;
          title = 'Member joined';
          subtitle = '$creator joined the group';
          break;
        case 'SETTLEMENT':
          type = ActivityType.settlement;
          title = 'Settlement update';
          subtitle = '$creator settled up';
          break;
        default:
          type = ActivityType.unknown;
          title = action.replaceAll('_', ' ');
          subtitle = groupName;
      }

      return ActivityLogItem(
        id: data['id'] as String? ?? '',
        title: title,
        subtitle: subtitle,
        timestamp: parseDateTime(data['timestamp'] ?? data['created_at']),
        type: type,
        groupName: groupName,
      );
    }).toList();

    logs.sort((a, b) {
      final at = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return logs.take(15).toList();
  }

  String _monthLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month - 1];
  }
}

class _MemberMeta {
  const _MemberMeta({
    required this.uid,
    required this.name,
    this.profileImage,
    this.isCreator = false,
  });

  final String uid;
  final String name;
  final String? profileImage;
  final bool isCreator;
}

class GroupDetailsException implements Exception {
  const GroupDetailsException(this.message);

  final String message;

  @override
  String toString() => message;
}

String groupDetailsErrorMessage(Object error) {
  if (error is GroupDetailsException) return error.message;
  if (error is PostgrestException) {
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}
