import 'package:cloud_firestore/cloud_firestore.dart';

import '../../dashboard/models/activity_log_item.dart';

/// Restores items deleted via [EXPENSE_DELETED] / [MEMBER_REMOVED] logs only.
class ActivityUndoService {
  const ActivityUndoService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const actionRestored = 'ACTIVITY_RESTORED';

  Future<void> restoreDeleted({
    required ActivityLogItem item,
    required String userId,
    required String userName,
  }) async {
    final logRef = _firestore.collection('group_logs').doc(item.id);
    final logSnap = await logRef.get();
    if (!logSnap.exists) {
      throw const ActivityUndoException('Activity not found.');
    }

    final data = logSnap.data()!;
    if (data['restored'] == true) {
      throw const ActivityUndoException('Already restored.');
    }

    switch (item.type) {
      case ActivityType.expenseDeleted:
        await _restoreExpense(data, userId, userName, logRef);
      case ActivityType.memberRemoved:
        await _restoreMember(data, userId, userName, logRef);
      default:
        throw const ActivityUndoException('Only deleted items can be restored.');
    }
  }

  Future<void> _restoreExpense(
    Map<String, dynamic> logData,
    String userId,
    String userName,
    DocumentReference<Map<String, dynamic>> logRef,
  ) async {
    final snapshot = logData['deletedSnapshot'] as Map?;
    if (snapshot == null) {
      throw const ActivityUndoException('Deleted expense data missing.');
    }

    final expense = Map<String, dynamic>.from(snapshot);
    final expenseId = expense['expenseId'] as String? ?? '';
    if (expenseId.isEmpty) {
      throw const ActivityUndoException('Expense id missing.');
    }

    final expenseRef = _firestore.collection('expenses').doc(expenseId);
    final existing = await expenseRef.get();
    if (existing.exists) {
      throw const ActivityUndoException('Expense already exists.');
    }

    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final groupId = expense['groupId'] as String? ?? logData['groupId'] as String? ?? '';
    final memberIds = List<String>.from(logData['memberIds'] as List? ?? []);

    expense.remove('deletedAt');
    if (expense['createdAt'] == null) {
      expense['createdAt'] = FieldValue.serverTimestamp();
    }

    final restoreLogRef = _firestore.collection('group_logs').doc();
    final batch = _firestore.batch()
      ..set(expenseRef, expense)
      ..update(_firestore.collection('groups').doc(groupId), {
        'totalExpense': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(logRef, {
        'restored': true,
        'restoredAt': FieldValue.serverTimestamp(),
      })
      ..set(restoreLogRef, {
        'logId': restoreLogRef.id,
        'groupId': groupId,
        'actionType': actionRestored,
        'createdBy': userId,
        'creatorName': userName,
        'memberIds': memberIds,
        'timestamp': FieldValue.serverTimestamp(),
        'restoreOf': logRef.id,
        'restoreType': 'EXPENSE_DELETED',
      });

    await batch.commit();
  }

  Future<void> _restoreMember(
    Map<String, dynamic> logData,
    String userId,
    String userName,
    DocumentReference<Map<String, dynamic>> logRef,
  ) async {
    final snapshot = logData['deletedSnapshot'] as Map?;
    if (snapshot == null) {
      throw const ActivityUndoException('Deleted member data missing.');
    }

    final member = Map<String, dynamic>.from(snapshot);
    final memberUid = member['uid'] as String? ?? '';
    if (memberUid.isEmpty) {
      throw const ActivityUndoException('Member id missing.');
    }

    final groupId = logData['groupId'] as String? ?? '';
    final groupRef = _firestore.collection('groups').doc(groupId);
    final groupSnap = await groupRef.get();
    if (!groupSnap.exists) {
      throw const ActivityUndoException('Group not found.');
    }

    final data = groupSnap.data()!;
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    if (memberIds.contains(memberUid)) {
      throw const ActivityUndoException('Member already in group.');
    }

    memberIds.add(memberUid);
    final members = List<Map<String, dynamic>>.from(
      (data['memberDetails'] as List? ?? data['members'] as List? ?? []).map(
        (m) => Map<String, dynamic>.from(m as Map),
      ),
    );
    members.add(member);

    final restoreLogRef = _firestore.collection('group_logs').doc();
    final batch = _firestore.batch()
      ..update(groupRef, {
        'memberIds': memberIds,
        'memberDetails': members,
        'members': members,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..update(logRef, {
        'restored': true,
        'restoredAt': FieldValue.serverTimestamp(),
      })
      ..set(restoreLogRef, {
        'logId': restoreLogRef.id,
        'groupId': groupId,
        'actionType': actionRestored,
        'createdBy': userId,
        'creatorName': userName,
        'memberIds': memberIds,
        'timestamp': FieldValue.serverTimestamp(),
        'restoreOf': logRef.id,
        'restoreType': 'MEMBER_REMOVED',
      });

    await batch.commit();
  }
}

class ActivityUndoException implements Exception {
  const ActivityUndoException(this.message);

  final String message;

  @override
  String toString() => message;
}
