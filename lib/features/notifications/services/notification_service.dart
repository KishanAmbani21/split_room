import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../groups/models/create_group_input.dart';

class NotificationService {
  NotificationService({
    required FirebaseFirestore firestore,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  static const typeGroupCreated = 'GROUP_CREATED';

  Future<void> initializeForUser(String userId) async {
    await _requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).set(
        {'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    _messaging.onTokenRefresh.listen((newToken) {
      _firestore.collection('users').doc(userId).set(
        {'fcmToken': newToken, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  Future<void> notifyGroupCreated({
    required CreateGroupInput input,
    required String groupId,
  }) async {
    const title = 'New Group Added';
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final member in input.selectedMembers) {
      final message =
          '${input.creatorName} added you to ${input.groupName.trim()} group';
      final ref = _firestore.collection('notifications').doc();
      batch.set(ref, _notificationPayload(
        refId: ref.id,
        userId: member.uid,
        groupId: groupId,
        groupName: input.groupName.trim(),
        groupImage: input.groupImagePath ?? '',
        title: title,
        message: message,
        type: typeGroupCreated,
        createdBy: input.createdBy,
        createdAt: now,
      ));
    }

    await batch.commit();
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
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final memberId in memberIds) {
      if (memberId == excludeUserId) continue;
      final ref = _firestore.collection('notifications').doc();
      batch.set(ref, _notificationPayload(
        refId: ref.id,
        userId: memberId,
        groupId: groupId,
        groupName: groupName,
        groupImage: groupImage,
        title: title,
        message: message,
        type: type,
        createdBy: createdBy,
        createdAt: now,
      ));
    }

    await batch.commit();
  }

  Map<String, dynamic> _notificationPayload({
    required String refId,
    required String userId,
    required String groupId,
    required String groupName,
    required String groupImage,
    required String title,
    required String message,
    required String type,
    required String createdBy,
    required Object createdAt,
  }) {
    return {
      'notificationId': refId,
      'userId': userId,
      'groupId': groupId,
      'groupName': groupName,
      'groupImage': groupImage,
      'title': title,
      'message': message,
      'type': type,
      'actionType': type,
      'isRead': false,
      'read': false,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }

  Stream<List<AppNotificationDoc>> watchNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => AppNotificationDoc(id: d.id, data: d.data()))
          .toList();
      docs.sort((a, b) {
        final at = a.data['createdAt'];
        final bt = b.data['createdAt'];
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        if (at is Timestamp && bt is Timestamp) {
          return bt.compareTo(at);
        }
        return 0;
      });
      return docs.take(50).toList();
    });
  }

  Stream<int> watchUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      return snap.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] != true && data['read'] != true;
      }).length;
    });
  }

  Future<void> markRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'read': true,
    });
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['isRead'] == true || data['read'] == true) continue;
      batch.update(doc.reference, {'isRead': true, 'read': true});
    }
    await batch.commit();
  }
}

class AppNotificationDoc {
  const AppNotificationDoc({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}
