import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  final String uid;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final String status;
  final String loginType;
  final String deviceType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: data['uid'] as String? ?? doc.id,
      fullName: data['full_name'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      profileImageUrl: data['profile_image'] as String? ??
          data['profileImage'] as String? ??
          data['avatar_url'] as String?,
      status: data['status'] as String? ?? 'active',
      loginType: data['login_type'] as String? ?? 'email',
      deviceType: data['device_type'] as String? ?? 'android',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
