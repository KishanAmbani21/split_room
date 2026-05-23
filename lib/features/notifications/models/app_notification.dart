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
    required this.createdByName,
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
  final String createdByName;
  final DateTime? createdAt;
  final bool isRead;

  /// Short label for the action type.
  String get actionLabel {
    switch (type) {
      case 'EXPENSE_ADDED':
        return 'added an expense';
      case 'EXPENSE_UPDATED':
        return 'updated an expense';
      case 'EXPENSE_DELETED':
        return 'deleted an expense';
      case 'GROUP_CREATED':
        return 'created a group';
      case 'MEMBER_JOINED':
        return 'added a member';
      case 'MEMBER_REMOVED':
        return 'removed a member';
      case 'GROUP_UPDATED':
        return 'updated the group';
      default:
        return 'sent an update';
    }
  }

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> data, {
    String createdByName = 'Someone',
  }) {
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
      createdByName: createdByName,
      createdAt: parseDateTime(data['created_at'] ?? data['createdAt']),
      isRead: data['is_read'] as bool? ??
          data['isRead'] as bool? ??
          data['read'] as bool? ??
          false,
    );
  }
}
