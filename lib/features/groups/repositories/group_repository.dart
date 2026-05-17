import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_realtime_service.dart';
import '../models/create_group_input.dart';
import '../models/group_model.dart';

/// Supabase access for groups and group_members.
class GroupRepository {
  GroupRepository({
    SupabaseClient? client,
    SupabaseRealtimeService? realtime,
  })  : _client = client ?? Supabase.instance.client,
        _realtime = realtime ?? SupabaseRealtimeService();

  final SupabaseClient _client;
  final SupabaseRealtimeService _realtime;

  Stream<List<GroupModel>> watchGroupsForUser(String userId) {
    return _realtime.watchUserGroups(userId).map(
          (rows) => rows
              .map((r) => GroupModel.fromMap(r['id'] as String, r))
              .where(
                (g) =>
                    g.createdBy == userId || g.memberIds.contains(userId),
              )
              .toList(),
        );
  }

  /// All active member user IDs for a group (for notifications).
  Future<List<String>> fetchGroupMemberIds(String groupId) async {
    final rows = await _client
        .from('group_members')
        .select('user_id')
        .eq('group_id', groupId)
        .isFilter('deleted_at', null);
    return (rows as List)
        .map((r) => r['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<bool> groupNameExists(
    String groupName, {
    String? excludeGroupId,
  }) async {
    final lower = groupName.trim().toLowerCase();
    if (lower.isEmpty) return false;

    var query = _client
        .from('groups')
        .select('id')
        .eq('group_name_lower', lower)
        .isFilter('deleted_at', null);

    final rows = await query;
    for (final row in rows as List) {
      final id = row['id'] as String?;
      if (excludeGroupId != null && id == excludeGroupId) continue;
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>> fetchGroup(String groupId) async {
    final row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) {
      throw const GroupRepositoryException('Group not found.');
    }
    return Map<String, dynamic>.from(row);
  }

  Future<String> createGroup(CreateGroupInput input) async {
    final groupId = await _client.rpc(
      'create_group_atomic',
      params: {
        'p_group_name': input.groupName.trim(),
        'p_description': input.description.trim(),
        'p_group_image': input.groupImagePath ?? '',
        'p_group_type': input.groupType.name,
        'p_creator_name': input.creatorName,
        'p_currency': input.currencyCode,
        'p_member_details': input.memberDetails.map((m) => m.toMap()).toList(),
      },
    );
    return groupId.toString();
  }

  Future<void> addGroupMemberRecords({
    required String groupId,
    required String addedBy,
    required List<Map<String, dynamic>> newMembers,
  }) async {
    for (final member in newMembers) {
      final uid = member['uid'] as String? ?? '';
      if (uid.isEmpty) continue;
      await _client.from('group_members').upsert({
        'group_id': groupId,
        'user_id': uid,
        'user_name': member['name'] as String? ?? 'Member',
        'user_email': member['email'] as String? ?? '',
        'added_by': addedBy,
        'is_creator': member['isCreator'] as bool? ?? false,
      });
    }
  }
}

class GroupRepositoryException implements Exception {
  const GroupRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
