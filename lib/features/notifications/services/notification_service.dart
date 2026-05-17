import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fcm_push_service.dart';
import '../../../core/services/supabase_realtime_service.dart';
import '../../groups/models/create_group_input.dart';

class NotificationService {
  NotificationService({
    SupabaseClient? client,
    SupabaseRealtimeService? realtime,
    FcmPushService? fcmPush,
    FirebaseMessaging? messaging,
  })  : _client = client ?? Supabase.instance.client,
        _realtime = realtime ?? SupabaseRealtimeService(),
        _fcmPush = fcmPush ?? FcmPushService(),
        _messaging = messaging ?? FirebaseMessaging.instance;

  final SupabaseClient _client;
  final SupabaseRealtimeService _realtime;
  final FcmPushService _fcmPush;
  final FirebaseMessaging _messaging;

  String? _activeUserId;
  String? _lastPersistedToken;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initializedForSession = false;

  static const typeGroupCreated = 'GROUP_CREATED';

  Future<void> initializeForUser(String userId) async {
    if (userId.isEmpty) return;

    if (_activeUserId != userId) {
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
      _lastPersistedToken = null;
      _initializedForSession = false;
      _activeUserId = userId;
    }

    if (_initializedForSession) return;
    _initializedForSession = true;

    await _requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _persistFcmTokenIfNeeded(userId, token);
    }

    _tokenRefreshSub ??= _messaging.onTokenRefresh.listen((newToken) {
      final uid = _activeUserId;
      if (uid == null || uid.isEmpty) return;
      unawaited(_persistFcmTokenIfNeeded(uid, newToken));
    });
  }

  void resetSession() {
    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = null;
    _activeUserId = null;
    _lastPersistedToken = null;
    _initializedForSession = false;
  }

  Future<void> _persistFcmTokenIfNeeded(String userId, String token) async {
    if (_lastPersistedToken == token && _activeUserId == userId) return;

    final row = await _client
        .from('users')
        .select('fcm_token')
        .eq('id', userId)
        .maybeSingle();
    final existing = row?['fcm_token'] as String?;
    if (existing == token) {
      _lastPersistedToken = token;
      return;
    }

    await _client.from('users').update({'fcm_token': token}).eq('id', userId);
    _lastPersistedToken = token;
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<void> notifyGroupCreated({
    required CreateGroupInput input,
    required String groupId,
  }) async {
    const title = 'New Group Added';
    final recipients = input.selectedMembers.map((m) => m.uid).toList();
    await _createNotifications(
      userIds: recipients,
      groupId: groupId,
      groupName: input.groupName.trim(),
      groupImage: input.groupImagePath ?? '',
      title: title,
      message:
          '${input.creatorName} added you to ${input.groupName.trim()} group',
      type: typeGroupCreated,
      createdBy: input.createdBy,
    );
  }

  Future<void> notifyGroupMembers({
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
    final targets =
        memberIds.where((id) => id != excludeUserId && id.isNotEmpty).toList();
    await _createNotifications(
      userIds: targets,
      groupId: groupId,
      groupName: groupName,
      groupImage: groupImage,
      title: title,
      message: message,
      type: type,
      createdBy: createdBy,
    );
  }

  Future<void> _createNotifications({
    required List<String> userIds,
    required String groupId,
    required String groupName,
    required String groupImage,
    required String title,
    required String message,
    required String type,
    required String createdBy,
  }) async {
    if (userIds.isEmpty) return;

    final rows = userIds
        .map(
          (userId) => {
            'user_id': userId,
            'group_id': groupId,
            'group_name': groupName,
            'group_image': groupImage,
            'title': title,
            'message': message,
            'type': type,
            'created_by': createdBy,
            'is_read': false,
          },
        )
        .toList();

    await _client.from('notifications').insert(rows);

    await _fcmPush.sendToUsers(
      userIds: userIds,
      title: title,
      body: message,
      data: {
        'groupId': groupId,
        'type': type,
      },
    );
  }

  Stream<List<AppNotificationDoc>> watchNotifications(String userId) {
    return _realtime.watchUserNotifications(userId).map(
          (rows) => rows
              .map((d) => AppNotificationDoc(id: d['id'] as String, data: d))
              .toList(),
        );
  }

  Stream<int> watchUnreadCount(String userId) {
    return watchNotifications(userId).map(
      (docs) => docs.where((d) => d.data['is_read'] != true).length,
    );
  }

  Future<void> markRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }
}

class AppNotificationDoc {
  const AppNotificationDoc({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
