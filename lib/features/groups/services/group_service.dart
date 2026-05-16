import 'package:cloud_firestore/cloud_firestore.dart';

import '../../notifications/services/notification_service.dart';
import '../models/create_group_input.dart';
import '../models/group_firestore_helpers.dart';
import '../models/group_member_detail.dart';
import '../models/group_model.dart';
import '../models/selectable_user.dart';
import '../repositories/group_repository.dart';

class GroupService {
  GroupService({
    required GroupRepository repository,
    NotificationService? notificationService,
  })  : _repository = repository,
        _notifications = notificationService;

  final GroupRepository _repository;
  final NotificationService? _notifications;

  static const actionGroupCreated = 'GROUP_CREATED';
  static const actionGroupUpdated = 'GROUP_UPDATED';
  static const actionMemberJoined = 'MEMBER_JOINED';

  Stream<List<GroupModel>> watchUserGroups(String userId) =>
      _repository.watchGroupsForUser(userId);

  Future<bool> groupNameExists(
    String groupName, {
    String? excludeGroupId,
  }) =>
      _repository.groupNameExists(groupName, excludeGroupId: excludeGroupId);

  Future<Map<String, dynamic>> fetchGroup(String groupId) =>
      _repository.fetchGroup(groupId);

  Future<String> createGroup(CreateGroupInput input) async {
    if (await _repository.groupNameExists(input.groupName)) {
      throw const GroupServiceException('Group name already exists');
    }

    final groupId = await _repository.createGroup(input);

    await _notifications?.notifyGroupCreated(
      input: input,
      groupId: groupId,
    );

    return groupId;
  }

  Future<void> updateGroup({
    required String groupId,
    required String groupName,
    required String description,
    String? groupImagePath,
    required String updatedBy,
  }) async {
    if (await _repository.groupNameExists(groupName, excludeGroupId: groupId)) {
      throw const GroupServiceException('Group name already exists');
    }

    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('groups').doc(groupId);
    final updates = <String, dynamic>{
      'groupName': groupName.trim(),
      'groupNameLower': groupName.trim().toLowerCase(),
      'description': description.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (groupImagePath != null) {
      updates['groupImage'] = groupImagePath;
    }
    await ref.update(updates);

    final snap = await ref.get();
    final data = snap.data() ?? {};
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    final resolvedName =
        data['groupName'] as String? ?? groupName.trim();
    final groupImage = data['groupImage'] as String? ?? '';

    final logRef = firestore.collection('group_logs').doc();
    await logRef.set({
      'logId': logRef.id,
      'groupId': groupId,
      'actionType': actionGroupUpdated,
      'actionMessage': 'Group "$resolvedName" was updated',
      'createdBy': updatedBy,
      'createdByName': 'Member',
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _notifications?.notifyGroupMembers(
      memberIds: memberIds,
      excludeUserId: updatedBy,
      groupId: groupId,
      groupName: resolvedName,
      groupImage: groupImage,
      type: actionGroupUpdated,
      title: 'Group Updated',
      message: 'Group "$resolvedName" was updated',
      createdBy: updatedBy,
    );
  }

  Future<void> addMembers({
    required String groupId,
    required List<SelectableUser> newMembers,
    required String addedBy,
    required String addedByName,
  }) async {
    if (newMembers.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final groupRef = firestore.collection('groups').doc(groupId);
    final snap = await groupRef.get();
    if (!snap.exists) {
      throw const GroupServiceException('Group not found.');
    }

    final data = snap.data()!;
    final memberIds = List<String>.from(data['memberIds'] as List? ?? []);
    final details = parseMemberDetails(data);

    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();
    final newMemberMaps = <Map<String, dynamic>>[];

    for (final user in newMembers) {
      if (memberIds.contains(user.uid)) continue;
      memberIds.add(user.uid);
      final map = {...user.toMemberMap(), 'isCreator': false};
      details.add(GroupMemberDetail.fromMap(map));
      newMemberMaps.add(map);

      final logRef = firestore.collection('group_logs').doc();
      batch.set(logRef, {
        'logId': logRef.id,
        'groupId': groupId,
        'actionType': actionMemberJoined,
        'actionMessage': '$addedByName added ${user.name}',
        'createdBy': addedBy,
        'createdByName': addedByName,
        'memberIds': memberIds,
        'createdAt': now,
        'timestamp': now,
        'memberData': user.toMemberMap(),
      });
    }

    final memberMaps = memberDetailsToLegacyMaps(details);
    batch.update(groupRef, {
      'memberIds': memberIds,
      'memberDetails': memberMaps,
      'members': memberMaps,
      'updatedAt': now,
    });

    await batch.commit();
    await _repository.addGroupMemberRecords(
      groupId: groupId,
      addedBy: addedBy,
      newMembers: newMemberMaps,
    );

    final groupName = data['groupName'] as String? ?? 'Group';
    final groupImage = data['groupImage'] as String? ?? '';
    final names = newMembers.map((m) => m.name).join(', ');
    await _notifications?.notifyGroupMembers(
      memberIds: memberIds,
      excludeUserId: addedBy,
      groupId: groupId,
      groupName: groupName,
      groupImage: groupImage,
      type: actionMemberJoined,
      title: 'Member Added',
      message: '$addedByName added $names',
      createdBy: addedBy,
    );
  }
}

class GroupServiceException implements Exception {
  const GroupServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

String groupServiceErrorMessage(Object error) {
  if (error is GroupServiceException) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied. Deploy Firestore rules and try again.';
      case 'unavailable':
        return 'Firestore is unavailable. Check your connection.';
      default:
        return error.message ?? 'Could not complete request.';
    }
  }
  return 'Could not complete request. Please try again.';
}
