import '../../core/utils/json_helpers.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.status,
    required this.loginType,
    required this.deviceType,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.fcmToken,
  });

  final String uid;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final String? fcmToken;
  final String status;
  final String loginType;
  final String deviceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['id'] as String? ?? data['uid'] as String? ?? '',
      fullName: data['full_name'] as String? ??
          data['fullName'] as String? ??
          data['name'] as String? ??
          '',
      email: data['email'] as String? ?? '',
      profileImageUrl: data['profile_image_url'] as String? ??
          data['profile_image'] as String? ??
          data['profileImage'] as String? ??
          data['avatar_url'] as String?,
      fcmToken: data['fcm_token'] as String? ?? data['fcmToken'] as String?,
      status: data['status'] as String? ?? 'active',
      loginType: data['login_type'] as String? ??
          data['loginType'] as String? ??
          'email',
      deviceType: data['device_type'] as String? ??
          data['deviceType'] as String? ??
          'android',
      createdAt: parseDateTime(data['created_at'] ?? data['createdAt']),
      updatedAt: parseDateTime(data['updated_at'] ?? data['updatedAt']),
    );
  }
}
