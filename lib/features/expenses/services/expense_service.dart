import 'package:supabase_flutter/supabase_flutter.dart';

import '../../groups/models/group_json_helpers.dart';
import '../../notifications/services/notification_service.dart';
import '../models/add_expense_input.dart';
import '../models/expense_group_member.dart';

class ExpenseService {
  ExpenseService({
    SupabaseClient? client,
    NotificationService? notificationService,
  })  : _client = client ?? Supabase.instance.client,
        _notifications = notificationService;

  final SupabaseClient _client;
  final NotificationService? _notifications;

  static const actionExpenseAdded = 'EXPENSE_ADDED';
  static const actionExpenseUpdated = 'EXPENSE_UPDATED';
  static const actionExpenseDeleted = 'EXPENSE_DELETED';

  Future<String> createExpense(AddExpenseInput input) async {
    final expenseId = await _client.rpc(
      'create_expense_atomic',
      params: {
        'p_group_id': input.groupId,
        'p_group_name': input.groupName,
        'p_title': input.title.trim(),
        'p_amount': input.amount,
        'p_paid_by': input.paidBy,
        'p_paid_by_name': input.paidByName,
        'p_category': inferExpenseCategory(input.title),
        'p_split_type': input.splitType.name,
        'p_notes': input.notes.trim(),
        'p_receipt_image': input.receiptImage,
        'p_expense_date': input.expenseDate?.toIso8601String(),
        'p_member_ids': input.memberIds,
        'p_splits': input.splits.map((s) => s.toMap()).toList(),
      },
    );

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

    return expenseId.toString();
  }

  Future<void> updateExpense({
    required String expenseId,
    required AddExpenseInput input,
    required double previousAmount,
    required String updatedByName,
  }) async {
    final amountDelta = input.amount - previousAmount;

    await _client.from('expenses').update({
      'group_name': input.groupName,
      'title': input.title.trim(),
      'amount': input.amount,
      'paid_by': input.paidBy,
      'paid_by_name': input.paidByName,
      'category': inferExpenseCategory(input.title),
      'split_type': input.splitType.name,
      'notes': input.notes.trim(),
      'receipt_image': input.receiptImage,
      'expense_date': input.expenseDate?.toIso8601String(),
      'member_ids': input.memberIds,
    }).eq('id', expenseId);

    await _client.from('expense_splits').delete().eq('expense_id', expenseId);
    await _client.from('expense_splits').insert(
      input.splits
          .map(
            (s) => {
              'expense_id': expenseId,
              'user_id': s.userId,
              'user_name': s.userName,
              'amount': s.amount,
            },
          )
          .toList(),
    );

    if (amountDelta.abs() > 0.001) {
      final group = await _client
          .from('groups')
          .select('total_expense')
          .eq('id', input.groupId)
          .single();
      final current =
          (group['total_expense'] as num?)?.toDouble() ?? 0;
      await _client.from('groups').update({
        'total_expense': current + amountDelta,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', input.groupId);
    }

    await _client.from('group_logs').insert({
      'group_id': input.groupId,
      'action_type': actionExpenseUpdated,
      'created_by': input.createdBy,
      'created_by_name': updatedByName,
      'member_ids': input.memberIds,
      'expense_data': input.toLogExpenseSnapshot(expenseId),
    });

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
    final expense = await _client
        .from('expenses')
        .select()
        .eq('id', expenseId)
        .maybeSingle();
    if (expense == null) {
      throw const ExpenseServiceException('Expense not found.');
    }

    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final groupId = expense['group_id'] as String? ?? '';
    final groupName = expense['group_name'] as String? ?? 'Group';
    final memberIds =
        List<String>.from((expense['member_ids'] as List?) ?? []);
    final title = expense['title'] as String? ?? 'Expense';

    final splits = await _client
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);
    final snapshot = {
      ...expense,
      'splits': splits,
      'expenseId': expenseId,
      'groupId': groupId,
    };

    await _client.from('expenses').delete().eq('id', expenseId);

    final group = await _client
        .from('groups')
        .select('total_expense, group_image')
        .eq('id', groupId)
        .maybeSingle();
    final current = (group?['total_expense'] as num?)?.toDouble() ?? 0;
    final groupImage = group?['group_image'] as String? ?? '';

    await _client.from('groups').update({
      'total_expense': current - amount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', groupId);

    await _client.from('group_logs').insert({
      'group_id': groupId,
      'action_type': actionExpenseDeleted,
      'created_by': deletedBy,
      'created_by_name': deletedByName,
      'member_ids': memberIds,
      'deleted_snapshot': snapshot,
    });

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
    final row = await _client
        .from('expenses')
        .select('*, expense_splits(*)')
        .eq('id', expenseId)
        .maybeSingle();
    if (row == null) {
      throw const ExpenseServiceException('Expense not found.');
    }
    return _expenseRowToLegacyMap(row);
  }

  Future<ExpenseGroupContext> loadGroupContext(String groupId) async {
    final row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) {
      throw const ExpenseServiceException('Group not found.');
    }

    final map = Map<String, dynamic>.from(row);
    final members = parseMemberDetails(map);
    final memberIds = parseMemberIds(map);

    return ExpenseGroupContext(
      groupId: row['id'] as String? ?? groupId,
      groupName: row['group_name'] as String? ?? 'Group',
      memberIds: memberIds,
      members: members
          .map(
            (m) => ExpenseGroupMember(
              uid: m.uid,
              name: m.name,
              profileImage: m.profileImage.isEmpty ? null : m.profileImage,
              isCreator: m.isCreator,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> _expenseRowToLegacyMap(Map<String, dynamic> row) {
    final splitsRaw = row['expense_splits'] as List? ?? [];
    final splits = splitsRaw.map((s) {
      final m = Map<String, dynamic>.from(s as Map);
      return {
        'userId': m['user_id'] ?? m['userId'],
        'userName': m['user_name'] ?? m['userName'],
        'amount': m['amount'],
      };
    }).toList();

    return {
      'expenseId': row['id'],
      'groupId': row['group_id'] ?? row['groupId'],
      'groupName': row['group_name'] ?? row['groupName'],
      'title': row['title'],
      'amount': row['amount'],
      'paidBy': row['paid_by'] ?? row['paidBy'],
      'paidByName': row['paid_by_name'] ?? row['paidByName'],
      'splitType': row['split_type'] ?? row['splitType'],
      'notes': row['notes'],
      'receiptImage': row['receipt_image'] ?? row['receiptImage'],
      'createdBy': row['created_by'] ?? row['createdBy'],
      'memberIds': row['member_ids'] ?? row['memberIds'],
      'splits': splits,
      'createdAt': row['created_at'] ?? row['createdAt'],
      'expenseDate': row['expense_date'] ?? row['expenseDate'],
    };
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
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'Permission denied. Check Supabase RLS policies.';
    }
    return error.message;
  }
  return 'Could not save expense. Please try again.';
}
