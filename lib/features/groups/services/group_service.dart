import 'package:supabase_flutter/supabase_flutter.dart';

import '../../notifications/services/notification_service.dart';
import '../models/create_group_input.dart';
import '../models/group_json_helpers.dart';
import '../models/group_member_detail.dart';
import '../models/group_model.dart';
import '../models/selectable_user.dart';
import '../repositories/group_repository.dart';

class GroupService {
  GroupService({
    required GroupRepository repository,
    SupabaseClient? client,
    NotificationService? notificationService,
  })  : _repository = repository,
        _client = client ?? Supabase.instance.client,
        _notifications = notificationService;

  final GroupRepository _repository;
  final SupabaseClient _client;
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

    final updates = <String, dynamic>{
      'group_name': groupName.trim(),
      'group_name_lower': groupName.trim().toLowerCase(),
      'description': description.trim(),
    };
    if (groupImagePath != null) {
      updates['group_image'] = groupImagePath;
    }

    await _client.from('groups').update(updates).eq('id', groupId);

    final data = await _repository.fetchGroup(groupId);
    final memberIds = parseMemberIds(data);
    final resolvedName = data['group_name'] as String? ?? groupName.trim();
    final groupImage = data['group_image'] as String? ?? '';

    await _client.from('group_logs').insert({
      'group_id': groupId,
      'action_type': actionGroupUpdated,
      'action_message': 'Group "$resolvedName" was updated',
      'created_by': updatedBy,
      'created_by_name': 'Member',
      'member_ids': memberIds,
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

    final data = await _repository.fetchGroup(groupId);
    var memberIds = List<String>.from(parseMemberIds(data));
    final details = parseMemberDetails(data);
    final newMemberMaps = <Map<String, dynamic>>[];

    for (final user in newMembers) {
      if (memberIds.contains(user.uid)) continue;
      memberIds.add(user.uid);
      final map = {...user.toMemberMap(), 'isCreator': false};
      details.add(GroupMemberDetail.fromMap(map));
      newMemberMaps.add(map);

      await _client.from('group_logs').insert({
        'group_id': groupId,
        'action_type': actionMemberJoined,
        'action_message': '$addedByName added ${user.name}',
        'created_by': addedBy,
        'created_by_name': addedByName,
        'member_ids': memberIds,
        'member_data': user.toMemberMap(),
      });
    }

    await _client.from('groups').update({
      'member_ids': memberIds,
      'member_details': memberDetailsToLegacyMaps(details),
    }).eq('id', groupId);

    await _repository.addGroupMemberRecords(
      groupId: groupId,
      addedBy: addedBy,
      newMembers: newMemberMaps,
    );

    final groupName = data['group_name'] as String? ?? 'Group';
    final groupImage = data['group_image'] as String? ?? '';
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
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'Permission denied. Check Supabase RLS policies.';
    }
    return error.message;
  }
  return 'Could not complete request. Please try again.';
}
