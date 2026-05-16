import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.message,
    required this.type,
    required this.createdBy,
    this.groupImage = '',
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String groupId;
  final String groupName;
  final String groupImage;
  final String title;
  final String message;
  final String type;
  final String createdBy;
  final DateTime? createdAt;
  final bool isRead;

  factory AppNotification.fromMap(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      groupName: data['groupName'] as String? ?? 'Group',
      groupImage: data['groupImage'] as String? ?? '',
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? data['actionType'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isRead: data['isRead'] as bool? ?? data['read'] as bool? ?? false,
    );
  }
}
