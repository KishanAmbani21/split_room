import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/selectable_user.dart';

class UsersService {
  UsersService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SelectableUser>> fetchAppUsers({required String excludeUid}) async {
    final rows = await _client
        .from('users')
        .select()
        .isFilter('deleted_at', null)
        .order('full_name');

    final users = (rows as List).map((row) {
      final data = Map<String, dynamic>.from(row as Map);
      return SelectableUser(
        uid: data['id'] as String? ?? '',
        name: data['full_name'] as String? ?? 'User',
        email: data['email'] as String? ?? '',
        profileImageUrl: data['profile_image_url'] as String?,
      );
    }).where((user) => user.uid != excludeUid && user.uid.isNotEmpty).toList();

    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }
}
