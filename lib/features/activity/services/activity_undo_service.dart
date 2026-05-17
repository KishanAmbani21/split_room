import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/models/activity_log_item.dart';

/// Restores items from [EXPENSE_DELETED] / [GROUP_DELETED] / [MEMBER_REMOVED] logs.
class ActivityUndoService {
  ActivityUndoService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> restoreDeleted({
    required ActivityLogItem item,
    required String userId,
    required String userName,
  }) async {
    switch (item.type) {
      case ActivityType.expenseDeleted:
        await _client.rpc('restore_expense_from_log', params: {'p_log_id': item.id});
      case ActivityType.groupDeleted:
        await _client.rpc('restore_group_from_log', params: {'p_log_id': item.id});
      case ActivityType.memberRemoved:
        await _restoreMember(item, userId, userName);
      default:
        throw const ActivityUndoException('Only deleted items can be restored.');
    }
  }

  Future<void> _restoreMember(
    ActivityLogItem item,
    String userId,
    String userName,
  ) async {
    final logRow = await _client
        .from('group_logs')
        .select()
        .eq('id', item.id)
        .maybeSingle();
    if (logRow == null) {
      throw const ActivityUndoException('Activity not found.');
    }

    final data = Map<String, dynamic>.from(logRow);
    if (data['restored'] == true) {
      throw const ActivityUndoException('Already restored.');
    }

    final snapshot = data['deleted_snapshot'] as Map?;
    if (snapshot == null) {
      throw const ActivityUndoException('Deleted member data missing.');
    }

    final member = Map<String, dynamic>.from(snapshot);
    final uid = member['uid'] as String? ?? '';
    final groupId = data['group_id'] as String? ?? '';

    final group = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();
    if (group == null) {
      throw const ActivityUndoException('Group no longer exists.');
    }

    final memberIds = List<String>.from(
      (group['member_ids'] as List?)?.map((e) => e.toString()) ?? [],
    );
    if (!memberIds.contains(uid)) {
      memberIds.add(uid);
    }

    final details = List<Map<String, dynamic>>.from(
      (group['member_details'] as List?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          [],
    );
    if (!details.any((m) => m['uid'] == uid)) {
      details.add(member);
    }

    await _client.from('groups').update({
      'member_ids': memberIds,
      'member_details': details,
    }).eq('id', groupId);

    await _client.from('group_members').upsert({
      'group_id': groupId,
      'user_id': uid,
      'user_name': member['name'] ?? 'Member',
      'user_email': member['email'] ?? '',
      'added_by': userId,
    });

    await _client.from('group_logs').update({'restored': true}).eq('id', item.id);

    await _client.from('group_logs').insert({
      'group_id': groupId,
      'action_type': 'ACTIVITY_RESTORED',
      'created_by': userId,
      'created_by_name': userName,
      'member_ids': memberIds,
    });
  }
}

class ActivityUndoException implements Exception {
  const ActivityUndoException(this.message);
  final String message;
  @override
  String toString() => message;
}

String activityUndoErrorMessage(Object error) {
  if (error is ActivityUndoException) return error.message;
  if (error is PostgrestException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty) return msg;
    return 'Could not restore. Please try again.';
  }
  return 'Could not restore. Please try again.';
}
