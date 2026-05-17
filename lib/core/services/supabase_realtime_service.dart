import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase Realtime subscriptions.
class SupabaseRealtimeService {
  SupabaseRealtimeService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeChannel _channel(String name) {
    return _channels.putIfAbsent(name, () => _client.channel(name));
  }

  /// Groups where the user is a member (via group_members).
  Stream<List<Map<String, dynamic>>> watchUserGroups(String userId) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> emit() async {
      final rows = await _client
          .from('group_members')
          .select('group_id, groups(*)')
          .eq('user_id', userId)
          .isFilter('deleted_at', null);
      final groups = <Map<String, dynamic>>[];
      for (final row in rows as List) {
        final g = row['groups'];
        if (g is Map<String, dynamic> && g['deleted_at'] == null) {
          groups.add(g);
        }
      }
      groups.sort((a, b) {
        final at = _activityTime(a);
        final bt = _activityTime(b);
        return bt.compareTo(at);
      });
      if (!controller.isClosed) controller.add(groups);
    }

    final channel = _channel('user_groups_$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'groups',
        callback: (_) => emit(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'group_members',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => emit(),
      )
      ..subscribe();

    emit();
    controller.onCancel = () async {
      await _client.removeChannel(channel);
      _channels.remove('user_groups_$userId');
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> watchGroupExpenses(String groupId) {
    return _tableStream(
      channelName: 'expenses_$groupId',
      table: 'expenses',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      fetch: () => _client
          .from('expenses')
          .select('*, expense_splits(*)')
          .eq('group_id', groupId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false),
    );
  }

  Stream<List<Map<String, dynamic>>> watchGroupLogs(String groupId) {
    return _tableStream(
      channelName: 'logs_$groupId',
      table: 'group_logs',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'group_id',
        value: groupId,
      ),
      fetch: () => _client
          .from('group_logs')
          .select()
          .eq('group_id', groupId)
          .isFilter('deleted_at', null)
          .order('timestamp', ascending: false)
          .limit(50),
    );
  }

  Stream<Map<String, dynamic>?> watchGroup(String groupId) {
    final controller = StreamController<Map<String, dynamic>?>.broadcast();

    Future<void> emit() async {
      final row = await _client
          .from('groups')
          .select()
          .eq('id', groupId)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (!controller.isClosed) controller.add(row);
    }

    final channel = _channel('group_$groupId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'groups',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: groupId,
        ),
        callback: (_) => emit(),
      )
      ..subscribe();

    emit();
    controller.onCancel = () async {
      await _client.removeChannel(channel);
      _channels.remove('group_$groupId');
    };

    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> watchUserNotifications(String userId) {
    return _tableStream(
      channelName: 'notifications_$userId',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      fetch: () => _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(50),
    );
  }

  Stream<List<Map<String, dynamic>>> _tableStream({
    required String channelName,
    required String table,
    PostgresChangeFilter? filter,
    required Future<dynamic> Function() fetch,
  }) {
    final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

    Future<void> emit() async {
      final rows = await fetch();
      final list = (rows as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!controller.isClosed) controller.add(list);
    }

    final channel = _channel(channelName)
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: filter,
        callback: (_) => emit(),
      )
      ..subscribe();

    emit();
    controller.onCancel = () async {
      await _client.removeChannel(channel);
      _channels.remove(channelName);
    };

    return controller.stream;
  }

  DateTime _activityTime(Map<String, dynamic> g) {
    final last = parseDateTime(g['last_expense_at']) ??
        parseDateTime(g['updated_at']) ??
        parseDateTime(g['created_at']);
    return last ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> dispose() async {
    for (final channel in _channels.values) {
      await _client.removeChannel(channel);
    }
    _channels.clear();
  }
}
