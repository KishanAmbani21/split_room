import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../notifications/providers/notification_providers.dart';
import '../models/group_model.dart';
import '../models/selectable_user.dart';
import '../repositories/group_repository.dart';
import '../services/group_service.dart';
import '../services/users_service.dart';

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(firestore: ref.watch(firestoreProvider)),
);

final groupServiceProvider = Provider<GroupService>(
  (ref) => GroupService(
    repository: ref.watch(groupRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  ),
);

/// Realtime groups for the signed-in user (`memberIds` contains uid).
final userGroupsStreamProvider = StreamProvider.autoDispose
    .family<List<GroupModel>, String>((ref, userId) {
  return ref.watch(groupServiceProvider).watchUserGroups(userId);
});

final usersServiceProvider = Provider<UsersService>(
  (ref) => UsersService(firestore: ref.watch(firestoreProvider)),
);

final appUsersProvider = FutureProvider.autoDispose
    .family<List<SelectableUser>, String>((ref, excludeUid) {
  return ref.read(usersServiceProvider).fetchAppUsers(excludeUid: excludeUid);
});
