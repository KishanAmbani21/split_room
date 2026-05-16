import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dashboard/models/activity_log_item.dart';
import '../../dashboard/models/monthly_spending.dart';
import '../models/group_details_data.dart';
import '../models/group_expense.dart';
import '../models/group_member_balance.dart';

class GroupDetailsService {
  const GroupDetailsService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Stream<GroupDetailsData> watchGroupDetails({
    required String groupId,
    required String currentUserId,
  }) {
    final controller = StreamController<GroupDetailsData>.broadcast();

    DocumentSnapshot<Map<String, dynamic>>? groupDoc;
    QuerySnapshot<Map<String, dynamic>>? expenseSnap;
    QuerySnapshot<Map<String, dynamic>>? logsSnap;

    void emit() {
      if (groupDoc == null || !groupDoc!.exists) return;
      if (expenseSnap == null || logsSnap == null) return;
      try {
        controller.add(
          _buildData(
            groupDoc: groupDoc!,
            expenseSnap: expenseSnap!,
            logsSnap: logsSnap!,
            currentUserId: currentUserId,
          ),
        );
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    final groupSub = _firestore.collection('groups').doc(groupId).snapshots().listen(
      (snap) {
        groupDoc = snap;
        emit();
      },
      onError: controller.addError,
    );

    final expenseSub = _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .listen(
      (snap) {
        expenseSnap = snap;
        emit();
      },
      onError: controller.addError,
    );

    final logsSub = _firestore
        .collection('group_logs')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .listen(
      (snap) {
        logsSnap = snap;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await groupSub.cancel();
      await expenseSub.cancel();
      await logsSub.cancel();
    };

    return controller.stream;
  }

  Future<void> deleteGroup({
    required String groupId,
    required String currentUserId,
  }) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) {
      throw const GroupDetailsException('Group not found.');
    }

    final createdBy = groupSnap.data()?['createdBy'] as String? ?? '';
    if (createdBy != currentUserId) {
      throw const GroupDetailsException('Only the group creator can delete this group.');
    }

    final expensesSnap = await _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .get();

    final logsSnap = await _firestore
        .collection('group_logs')
        .where('groupId', isEqualTo: groupId)
        .get();

    final batch = _firestore.batch();
    for (final doc in expensesSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in logsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(groupRef);
    await batch.commit();
  }

  GroupDetailsData _buildData({
    required DocumentSnapshot<Map<String, dynamic>> groupDoc,
    required QuerySnapshot<Map<String, dynamic>> expenseSnap,
    required QuerySnapshot<Map<String, dynamic>> logsSnap,
    required String currentUserId,
  }) {
    final groupData = groupDoc.data()!;
    final membersRaw = groupData['memberDetails'] as List? ??
        groupData['members'] as List? ??
        [];
    final memberIds = List<String>.from(groupData['memberIds'] as List? ?? []);

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

    final expenses = expenseSnap.docs.map(_parseExpense).toList()
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
    final activities = _parseActivities(logsSnap, groupData['groupName'] as String? ?? 'Group');

    final pendingCount =
        memberBalances.where((m) => !m.isSettled).length;

    return GroupDetailsData(
      groupId: groupData['groupId'] as String? ?? groupDoc.id,
      groupName: groupData['groupName'] as String? ?? 'Group',
      groupImage: groupData['groupImage'] as String? ?? '',
      groupType: groupData['groupType'] as String? ?? 'room',
      description: groupData['description'] as String? ?? '',
      createdBy: groupData['createdBy'] as String? ?? '',
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

  GroupExpense _parseExpense(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final splitsRaw = data['splits'] as List? ?? [];
    final splits = splitsRaw.map((s) {
      final map = Map<String, dynamic>.from(s as Map);
      return ExpenseSplit(
        userId: map['userId'] as String? ?? '',
        userName: map['userName'] as String? ?? 'Member',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();

    return GroupExpense(
      id: doc.id,
      groupId: data['groupId'] as String? ?? '',
      title: data['title'] as String? ?? 'Expense',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paidBy: data['paidBy'] as String? ?? '',
      paidByName: data['paidByName'] as String? ?? 'Someone',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
    QuerySnapshot<Map<String, dynamic>> logsSnap,
    String groupName,
  ) {
    final logs = logsSnap.docs.map((doc) {
      final data = doc.data();
      final action = data['actionType'] as String? ?? '';
      final creator = data['creatorName'] as String? ?? 'Someone';

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
          type = ActivityType.groupCreated;
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
        id: doc.id,
        title: title,
        subtitle: subtitle,
        timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
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
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Check Firestore rules.';
      case 'unavailable':
        return 'Firestore is unavailable. Check your connection.';
      default:
        return error.message ?? 'Could not load group details.';
    }
  }
  return 'Something went wrong. Please try again.';
}
