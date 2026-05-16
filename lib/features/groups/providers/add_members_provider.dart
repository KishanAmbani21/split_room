import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/selectable_user.dart';
import '../services/group_service.dart';
import 'groups_providers.dart';

final addMembersProvider =
    NotifierProvider.autoDispose<AddMembersNotifier, AddMembersState>(
  AddMembersNotifier.new,
);

class AddMembersState {
  const AddMembersState({
    this.searchQuery = '',
    this.selectedIds = const {},
    this.isLoading = true,
    this.isSubmitting = false,
    this.users = const [],
  });

  final String searchQuery;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSubmitting;
  final List<SelectableUser> users;

  List<SelectableUser> get filteredUsers {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  List<SelectableUser> get selectedUsers =>
      users.where((u) => selectedIds.contains(u.uid)).toList();

  AddMembersState copyWith({
    String? searchQuery,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSubmitting,
    List<SelectableUser>? users,
  }) {
    return AddMembersState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      users: users ?? this.users,
    );
  }
}

class AddMembersNotifier extends Notifier<AddMembersState> {
  String? _groupId;

  @override
  AddMembersState build() => const AddMembersState();

  Future<void> initialize(String groupId, String currentUserId) async {
    _groupId = groupId;
    final group = await ref.read(groupServiceProvider).fetchGroup(groupId);
    final memberIds = Set<String>.from(group['memberIds'] as List? ?? []);
    final users = await ref.read(appUsersProvider(currentUserId).future);
    final available = users.where((u) => !memberIds.contains(u.uid)).toList();
    state = state.copyWith(users: available, isLoading: false);
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void toggle(SelectableUser user) {
    final ids = Set<String>.from(state.selectedIds);
    if (ids.contains(user.uid)) {
      ids.remove(user.uid);
    } else {
      ids.add(user.uid);
    }
    state = state.copyWith(selectedIds: ids);
  }

  Future<void> submit(String addedBy, String addedByName) async {
    final groupId = _groupId;
    if (groupId == null) {
      throw const GroupServiceException('Group not loaded.');
    }
    if (state.selectedIds.isEmpty) {
      throw const GroupServiceException('Select at least one member.');
    }
    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(groupServiceProvider).addMembers(
            groupId: groupId,
            newMembers: state.selectedUsers,
            addedBy: addedBy,
            addedByName: addedByName,
          );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
