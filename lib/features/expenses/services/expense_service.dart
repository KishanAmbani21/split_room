import 'package:cloud_firestore/cloud_firestore.dart';

import '../../notifications/services/notification_service.dart';
import '../models/add_expense_input.dart';
import '../models/expense_group_member.dart';

class ExpenseService {
  ExpenseService({
    required FirebaseFirestore firestore,
    NotificationService? notificationService,
  })  : _firestore = firestore,
        _notifications = notificationService;

  final FirebaseFirestore _firestore;
  final NotificationService? _notifications;

  static const actionExpenseAdded = 'EXPENSE_ADDED';
  static const actionExpenseUpdated = 'EXPENSE_UPDATED';
  static const actionExpenseDeleted = 'EXPENSE_DELETED';

  Future<String> createExpense(AddExpenseInput input) async {
    final expenseRef = _firestore.collection('expenses').doc();
    final expenseId = expenseRef.id;
    final logRef = _firestore.collection('group_logs').doc();
    final groupRef = _firestore.collection('groups').doc(input.groupId);

    final expenseData = input.toExpenseMap(expenseId)
      ..['category'] = inferExpenseCategory(input.title)
      ..['createdAt'] = FieldValue.serverTimestamp();

    if (input.expenseDate != null) {
      expenseData['expenseDate'] = Timestamp.fromDate(input.expenseDate!);
    }

    final batch = _firestore.batch()
      ..set(expenseRef, expenseData)
      ..set(logRef, {
        'logId': logRef.id,
        'groupId': input.groupId,
        'actionType': actionExpenseAdded,
        'createdBy': input.createdBy,
        'creatorName': input.createdByName,
        'memberIds': input.memberIds,
        'timestamp': FieldValue.serverTimestamp(),
        'expenseData': input.toLogExpenseSnapshot(expenseId),
      })
      ..update(groupRef, {
        'totalExpense': FieldValue.increment(input.amount),
        'lastExpenseAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    await batch.commit();

    await _notify(
      memberIds: input.memberIds,
      excludeUserId: input.createdBy,
      groupId: input.groupId,
      groupName: input.groupName,
      type: actionExpenseAdded,
      title: 'Expense Added',
      message: '${input.createdByName} added "${input.title.trim()}"',
      createdBy: input.createdBy,
    );

    return expenseId;
  }

  Future<void> updateExpense({
    required String expenseId,
    required AddExpenseInput input,
    required double previousAmount,
    required String updatedByName,
  }) async {
    final expenseRef = _firestore.collection('expenses').doc(expenseId);
    final logRef = _firestore.collection('group_logs').doc();
    final groupRef = _firestore.collection('groups').doc(input.groupId);
    final amountDelta = input.amount - previousAmount;

    final expenseData = input.toExpenseMap(expenseId)
      ..['category'] = inferExpenseCategory(input.title)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    if (input.expenseDate != null) {
      expenseData['expenseDate'] = Timestamp.fromDate(input.expenseDate!);
    }

    final batch = _firestore.batch()
      ..update(expenseRef, expenseData)
      ..set(logRef, {
        'logId': logRef.id,
        'groupId': input.groupId,
        'actionType': actionExpenseUpdated,
        'createdBy': input.createdBy,
        'creatorName': updatedByName,
        'memberIds': input.memberIds,
        'timestamp': FieldValue.serverTimestamp(),
        'expenseData': input.toLogExpenseSnapshot(expenseId),
      });

    if (amountDelta.abs() > 0.001) {
      batch.update(groupRef, {
        'totalExpense': FieldValue.increment(amountDelta),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      batch.update(groupRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await _notify(
      memberIds: input.memberIds,
      excludeUserId: input.createdBy,
      groupId: input.groupId,
      groupName: input.groupName,
      type: actionExpenseUpdated,
      title: 'Expense Updated',
      message: '$updatedByName updated "${input.title.trim()}"',
      createdBy: input.createdBy,
    );
  }

  Future<void> deleteExpense({
    required String expenseId,
    required String deletedBy,
    required String deletedByName,
  }) async {
    final expenseRef = _firestore.collection('expenses').doc(expenseId);
    final snap = await expenseRef.get();
    if (!snap.exists) {
      throw const ExpenseServiceException('Expense not found.');
    }

    final expense = Map<String, dynamic>.from(snap.data()!);
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final groupId = expense['groupId'] as String? ?? '';
    final groupName = expense['groupName'] as String? ?? 'Group';
    final memberIds = List<String>.from(expense['memberIds'] as List? ?? []);
    final title = expense['title'] as String? ?? 'Expense';

    final logRef = _firestore.collection('group_logs').doc();
    final batch = _firestore.batch()
      ..delete(expenseRef)
      ..set(logRef, {
        'logId': logRef.id,
        'groupId': groupId,
        'actionType': actionExpenseDeleted,
        'createdBy': deletedBy,
        'creatorName': deletedByName,
        'memberIds': memberIds,
        'timestamp': FieldValue.serverTimestamp(),
        'deletedSnapshot': expense,
      })
      ..update(_firestore.collection('groups').doc(groupId), {
        'totalExpense': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    await batch.commit();

    final groupSnap = await _firestore.collection('groups').doc(groupId).get();
    final groupImage = groupSnap.data()?['groupImage'] as String? ?? '';

    await _notify(
      memberIds: memberIds,
      excludeUserId: deletedBy,
      groupId: groupId,
      groupName: groupName,
      groupImage: groupImage,
      type: actionExpenseDeleted,
      title: 'Expense Deleted',
      message: '$deletedByName deleted "$title"',
      createdBy: deletedBy,
    );
  }

  Future<Map<String, dynamic>> fetchExpense(String expenseId) async {
    final snap = await _firestore.collection('expenses').doc(expenseId).get();
    if (!snap.exists) {
      throw const ExpenseServiceException('Expense not found.');
    }
    return snap.data()!;
  }

  Future<ExpenseGroupContext> loadGroupContext(String groupId) async {
    final snap = await _firestore.collection('groups').doc(groupId).get();
    if (!snap.exists) {
      throw const ExpenseServiceException('Group not found.');
    }

    final data = snap.data()!;
    final membersRaw =
        data['memberDetails'] as List? ?? data['members'] as List? ?? [];
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);

    final members = membersRaw
        .map(
          (m) => ExpenseGroupMember.fromMap(Map<String, dynamic>.from(m as Map)),
        )
        .where((m) => m.uid.isNotEmpty)
        .toList();

    return ExpenseGroupContext(
      groupId: data['groupId'] as String? ?? groupId,
      groupName: data['groupName'] as String? ?? 'Group',
      memberIds: memberIds,
      members: members,
    );
  }

  Future<void> _notify({
    required List<String> memberIds,
    required String excludeUserId,
    required String groupId,
    required String groupName,
    required String type,
    required String title,
    required String message,
    required String createdBy,
    String groupImage = '',
  }) async {
    final notifications = _notifications;
    if (notifications == null) return;
    await notifications.notifyGroupMembers(
      memberIds: memberIds,
      excludeUserId: excludeUserId,
      groupId: groupId,
      groupName: groupName,
      groupImage: groupImage,
      type: type,
      title: title,
      message: message,
      createdBy: createdBy,
    );
  }
}

String inferExpenseCategory(String title) {
  final t = title.toLowerCase();
  if (RegExp(r'food|dinner|lunch|breakfast|grocery|restaurant|snack')
      .hasMatch(t)) {
    return 'Food';
  }
  if (RegExp(r'rent|room|housing|lease').hasMatch(t)) return 'Rent';
  if (RegExp(r'electric|water|gas|wifi|internet|utility|bill').hasMatch(t)) {
    return 'Utilities';
  }
  if (RegExp(r'uber|taxi|fuel|petrol|transport|bus|travel').hasMatch(t)) {
    return 'Transport';
  }
  if (RegExp(r'movie|game|entertain|party|fun').hasMatch(t)) {
    return 'Entertainment';
  }
  return 'Other';
}

class ExpenseGroupContext {
  const ExpenseGroupContext({
    required this.groupId,
    required this.groupName,
    required this.memberIds,
    required this.members,
  });

  final String groupId;
  final String groupName;
  final List<String> memberIds;
  final List<ExpenseGroupMember> members;
}

class ExpenseServiceException implements Exception {
  const ExpenseServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

String expenseServiceErrorMessage(Object error) {
  if (error is ExpenseServiceException) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Check Firestore rules.';
      case 'unavailable':
        return 'Firestore is unavailable. Check your connection.';
      default:
        return error.message ?? 'Could not save expense.';
    }
  }
  return 'Could not save expense. Please try again.';
}
