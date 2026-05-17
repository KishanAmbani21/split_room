import 'package:supabase_flutter/supabase_flutter.dart';

import '../../dashboard/models/activity_log_item.dart';

/// Restores items deleted via [EXPENSE_DELETED] / [MEMBER_REMOVED] logs only.
class ActivityUndoService {
  ActivityUndoService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const actionRestored = 'ACTIVITY_RESTORED';

  Future<void> restoreDeleted({
    required ActivityLogItem item,
    required String userId,
    required String userName,
  }) async {
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

    switch (item.type) {
      case ActivityType.expenseDeleted:
        await _restoreExpense(data, userId, userName);
      case ActivityType.memberRemoved:
        await _restoreMember(data, userId, userName);
      default:
        throw const ActivityUndoException('Only deleted items can be restored.');
    }
  }

  Future<void> _restoreExpense(
    Map<String, dynamic> logData,
    String userId,
    String userName,
  ) async {
    final snapshot = logData['deleted_snapshot'] as Map?;
    if (snapshot == null) {
      throw const ActivityUndoException('Deleted expense data missing.');
    }

    final expense = Map<String, dynamic>.from(snapshot);
    final expenseId = expense['id'] as String? ??
        expense['expenseId'] as String? ??
        '';
    if (expenseId.isEmpty) {
      throw const ActivityUndoException('Expense id missing.');
    }

    final existing = await _client
        .from('expenses')
        .select('id')
        .eq('id', expenseId)
        .maybeSingle();
    if (existing != null) {
      throw const ActivityUndoException('Expense already exists.');
    }

    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final groupId = expense['group_id'] as String? ??
        expense['groupId'] as String? ??
        logData['group_id'] as String? ??
        '';

    final insertExpense = <String, dynamic>{
      'id': expenseId,
      'group_id': groupId,
      'group_name': expense['group_name'] ?? expense['groupName'],
      'title': expense['title'],
      'amount': amount,
      'paid_by': expense['paid_by'] ?? expense['paidBy'],
      'paid_by_name': expense['paid_by_name'] ?? expense['paidByName'],
      'category': expense['category'] ?? 'Other',
      'split_type': expense['split_type'] ?? expense['splitType'] ?? 'equal',
      'notes': expense['notes'] ?? '',
      'receipt_image': expense['receipt_image'] ?? expense['receiptImage'] ?? '',
      'created_by': expense['created_by'] ?? expense['createdBy'] ?? userId,
      'member_ids': expense['member_ids'] ?? expense['memberIds'] ?? [],
    };

    await _client.from('expenses').insert(insertExpense);

    final splits = expense['splits'] as List? ?? [];
    if (splits.isNotEmpty) {
      await _client.from('expense_splits').insert(
        splits.map((s) {
          final m = Map<String, dynamic>.from(s as Map);
          return {
            'expense_id': expenseId,
            'user_id': m['user_id'] ?? m['userId'],
            'user_name': m['user_name'] ?? m['userName'],
            'amount': m['amount'],
          };
        }).toList(),
      );
    }

    final group = await _client
        .from('groups')
        .select('total_expense')
        .eq('id', groupId)
        .single();
    final current = (group['total_expense'] as num?)?.toDouble() ?? 0;
    await _client.from('groups').update({
      'total_expense': current + amount,
    }).eq('id', groupId);

    await _client.from('group_logs').update({'restored': true}).eq('id', logData['id']);

    await _client.from('group_logs').insert({
      'group_id': groupId,
      'action_type': actionRestored,
      'created_by': userId,
      'created_by_name': userName,
      'member_ids': logData['member_ids'] ?? [],
    });
  }

  Future<void> _restoreMember(
    Map<String, dynamic> logData,
    String userId,
    String userName,
  ) async {
    final snapshot = logData['deleted_snapshot'] as Map?;
    if (snapshot == null) {
      throw const ActivityUndoException('Deleted member data missing.');
    }

    final member = Map<String, dynamic>.from(snapshot);
    final uid = member['uid'] as String? ?? '';
    final groupId = logData['group_id'] as String? ?? '';

    final group = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
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

    await _client.from('group_logs').update({'restored': true}).eq('id', logData['id']);

    await _client.from('group_logs').insert({
      'group_id': groupId,
      'action_type': actionRestored,
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
