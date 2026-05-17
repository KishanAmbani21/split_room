import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/services/firestore_write_logger.dart';

import '../models/create_group_input.dart';
import '../models/group_model.dart';

/// Firestore access for groups and group_members.
class GroupRepository {
  GroupRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  CollectionReference<Map<String, dynamic>> get _groupMembers =>
      _firestore.collection('group_members');

  CollectionReference<Map<String, dynamic>> get _groupLogs =>
      _firestore.collection('group_logs');

  /// Realtime: all groups where [userId] is in memberIds.
  Stream<List<GroupModel>> watchGroupsForUser(String userId) {
    return _groups
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs
          .map(GroupModel.fromFirestore)
          .toList();
      groups.sort((a, b) {
        final at = a.lastActivityAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastActivityAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return groups;
    });
  }

  Future<bool> groupNameExists(
    String groupName, {
    String? excludeGroupId,
  }) async {
    final trimmed = groupName.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();

    for (final snap in [
      await _groups.where('groupNameLower', isEqualTo: lower).limit(2).get(),
      await _groups.where('groupName', isEqualTo: trimmed).limit(2).get(),
    ]) {
      for (final doc in snap.docs) {
        if (excludeGroupId != null && doc.id == excludeGroupId) continue;
        return true;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> fetchGroup(String groupId) async {
    final snap = await _groups.doc(groupId).get();
    if (!snap.exists) {
      throw const GroupRepositoryException('Group not found.');
    }
    return snap.data()!;
  }

  /// Atomic create: group doc + group_members rows + group_logs entry.
  Future<String> createGroup(CreateGroupInput input) async {
    final groupRef = _groups.doc();
    final groupId = groupRef.id;
    final now = FieldValue.serverTimestamp();
    final groupData = input.toGroupDocument(groupId);

    final batch = _firestore.batch()
      ..set(groupRef, {
        ...groupData,
        'createdAt': now,
        'updatedAt': now,
      });

    for (final member in input.memberDetails) {
      final memberRef = _groupMembers.doc('${groupId}_${member.uid}');
      batch.set(memberRef, {
        'groupMemberId': memberRef.id,
        'groupId': groupId,
        'userId': member.uid,
        'userName': member.name,
        'userEmail': member.email,
        'joinedAt': now,
        'addedBy': input.createdBy,
      });
    }

    final logRef = _groupLogs.doc();
    final snapshot = input.fullSnapshot(groupId);
    batch.set(logRef, {
      'logId': logRef.id,
      'groupId': groupId,
      'actionType': 'GROUP_CREATED',
      'actionMessage': input.activityLogMessage,
      'createdBy': input.createdBy,
      'createdByName': input.creatorName,
      'createdAt': now,
      'timestamp': now,
      'memberIds': input.memberIds,
      'fullDataSnapshot': snapshot,
      'groupData': snapshot,
    });

    await batch.commit();
    FirestoreWriteLogger.log(
      'batch',
      collection: 'groups',
      documentId: groupId,
      reason: 'create group',
    );
    return groupId;
  }

  Future<void> addGroupMemberRecords({
    required String groupId,
    required String addedBy,
    required List<Map<String, dynamic>> newMembers,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();
    for (final member in newMembers) {
      final uid = member['uid'] as String? ?? '';
      if (uid.isEmpty) continue;
      final ref = _groupMembers.doc('${groupId}_$uid');
      batch.set(ref, {
        'groupMemberId': ref.id,
        'groupId': groupId,
        'userId': uid,
        'userName': member['name'] as String? ?? 'Member',
        'userEmail': member['email'] as String? ?? '',
        'joinedAt': now,
        'addedBy': addedBy,
      }, SetOptions(merge: true));
    }
    await batch.commit();
    FirestoreWriteLogger.log(
      'batch',
      collection: 'group_members',
      reason: 'add ${newMembers.length} members',
    );
  }
}

class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
