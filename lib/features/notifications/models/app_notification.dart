import '../../../core/utils/json_helpers.dart';

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
      userId: data['user_id'] as String? ?? data['userId'] as String? ?? '',
      groupId: data['group_id'] as String? ?? data['groupId'] as String? ?? '',
      groupName: data['group_name'] as String? ??
          data['groupName'] as String? ??
          'Group',
      groupImage: data['group_image'] as String? ??
          data['groupImage'] as String? ??
          '',
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? data['actionType'] as String? ?? '',
      createdBy: data['created_by'] as String? ?? data['createdBy'] as String? ?? '',
      createdAt: parseDateTime(data['created_at'] ?? data['createdAt']),
      isRead: data['is_read'] as bool? ?? data['isRead'] as bool? ?? data['read'] as bool? ?? false,
    );
  }
}
