import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/fcm_push_service.dart';
import '../../../core/services/local_notification_service.dart';
import '../../../core/services/supabase_realtime_service.dart';
import '../../groups/models/create_group_input.dart';
import '../models/app_notification.dart';

class NotificationService {
  NotificationService({
    SupabaseClient? client,
    SupabaseRealtimeService? realtime,
    FcmPushService? fcmPush,
    FirebaseMessaging? messaging,
    LocalNotificationService? localNotifications,
  })  : _client = client ?? Supabase.instance.client,
        _realtime = realtime ?? SupabaseRealtimeService(),
        _fcmPush = fcmPush ?? FcmPushService(),
        _messaging = messaging ?? FirebaseMessaging.instance,
        _local = localNotifications ?? LocalNotificationService.instance;

  final SupabaseClient _client;
  final SupabaseRealtimeService _realtime;
  final FcmPushService _fcmPush;
  final FirebaseMessaging _messaging;
  final LocalNotificationService _local;

  String? _activeUserId;
  String? _lastPersistedToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  bool _initializedForSession = false;

  static const typeGroupCreated = 'GROUP_CREATED';

  Future<void> initializeForUser(String userId) async {
    if (userId.isEmpty) return;

    if (_activeUserId != userId) {
      await _tokenRefreshSub?.cancel();
      await _foregroundMessageSub?.cancel();
      _tokenRefreshSub = null;
      _foregroundMessageSub = null;
      _lastPersistedToken = null;
      _initializedForSession = false;
      _activeUserId = userId;
    }

    if (_initializedForSession) return;
    _initializedForSession = true;

    await _local.initialize();
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

    await _foregroundMessageSub?.cancel();
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showTrayNotification(message));
    });
  }

  void resetSession() {
    unawaited(_tokenRefreshSub?.cancel());
    unawaited(_foregroundMessageSub?.cancel());
    _tokenRefreshSub = null;
    _foregroundMessageSub = null;
    _activeUserId = null;
    _lastPersistedToken = null;
    _initializedForSession = false;
  }

  Future<void> _showTrayNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title'] as String? ??
        'RoomSplit';
    final body = notification?.body ??
        message.data['body'] as String? ??
        message.data['message'] as String? ??
        '';
    if (body.isEmpty) return;

    await _local.show(
      title: title,
      body: body,
      payload: message.data['groupId'] as String?,
    );
  }

  Future<void> _persistFcmTokenIfNeeded(String userId, String token) async {
    if (_lastPersistedToken == token && _activeUserId == userId) return;

    try {
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
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] token save failed: $e');
    }
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
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
      createdByName: input.creatorName,
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
    String createdByName = 'Someone',
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
      createdByName: createdByName,
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
    required String createdByName,
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

    try {
      await _client.from('notifications').insert(rows);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] insert failed: $e');
      rethrow;
    }

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

  /// Loads notifications once (used for first paint + on realtime refresh).
  Future<List<AppNotification>> fetchNotificationList(String userId) async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(50);

    return _mapRows(rows as List);
  }

  /// Emits immediately, then on each realtime change.
  Stream<List<AppNotification>> watchNotificationList(String userId) async* {
    try {
      yield await fetchNotificationList(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notification] fetch failed: $e');
      yield [];
    }

    await for (final _ in _realtime.watchUserNotifications(userId)) {
      try {
        yield await fetchNotificationList(userId);
      } catch (e) {
        if (kDebugMode) debugPrint('[Notification] refresh failed: $e');
        yield [];
      }
    }
  }

  Stream<int> watchUnreadCount(String userId) {
    return watchNotificationList(userId).map(
      (items) => items.where((n) => !n.isRead).length,
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

  Future<List<AppNotification>> _mapRows(List<dynamic> rows) async {
    if (rows.isEmpty) return [];

    final creatorIds = <String>{};
    for (final raw in rows) {
      final data = Map<String, dynamic>.from(raw as Map);
      final id = data['created_by'] as String? ?? data['createdBy'] as String?;
      if (id != null && id.isNotEmpty) creatorIds.add(id);
    }

    final nameById = <String, String>{};
    if (creatorIds.isNotEmpty) {
      try {
        final users = await _client
            .from('users')
            .select('id, full_name')
            .inFilter('id', creatorIds.toList());
        for (final u in users as List) {
          final map = Map<String, dynamic>.from(u as Map);
          final uid = map['id']?.toString() ?? '';
          if (uid.isEmpty) continue;
          nameById[uid] =
              map['full_name'] as String? ?? map['fullName'] as String? ?? 'Member';
        }
      } catch (_) {
        // Names are optional for display.
      }
    }

    return rows.map((raw) {
      final data = Map<String, dynamic>.from(raw as Map);
      final id = data['id']?.toString() ?? '';
      final createdBy =
          data['created_by'] as String? ?? data['createdBy'] as String? ?? '';
      return AppNotification.fromMap(
        id,
        data,
        createdByName: nameById[createdBy] ?? 'Someone',
      );
    }).where((n) => n.id.isNotEmpty).toList();
  }
}

class AppNotificationDoc {
  const AppNotificationDoc({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
