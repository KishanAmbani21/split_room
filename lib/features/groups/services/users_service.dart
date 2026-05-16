import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/selectable_user.dart';

class UsersService {
  const UsersService({required FirebaseFirestore firestore}) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<List<SelectableUser>> fetchAppUsers({required String excludeUid}) async {
    final snapshot = await _firestore.collection('users').get();

    final users = snapshot.docs.map((doc) {
      final data = doc.data();
      return SelectableUser(
        uid: data['uid'] as String? ?? doc.id,
        name: data['full_name'] as String? ?? data['name'] as String? ?? 'User',
        email: data['email'] as String? ?? '',
        profileImageUrl: data['profile_image'] as String? ??
            data['profileImage'] as String? ??
            data['avatar_url'] as String?,
      );
    }).where((user) => user.uid != excludeUid).toList();

    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }
}
