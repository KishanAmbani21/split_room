import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/app_user.dart';
import '../models/create_group_input.dart';
import '../models/group_type.dart';
import '../models/selectable_user.dart';
import '../services/group_service.dart';
import 'groups_providers.dart';

final createGroupProvider =
    NotifierProvider.autoDispose<CreateGroupNotifier, CreateGroupState>(
  CreateGroupNotifier.new,
);

enum MembersTab { appUsers, contacts }

class CreateGroupState {
  const CreateGroupState({
    this.groupName = '',
    this.description = '',
    this.groupType = GroupType.room,
    this.groupImagePath,
    this.selectedMemberIds = const {},
    this.memberSearchQuery = '',
    this.membersTab = MembersTab.appUsers,
    this.isInitialized = false,
    this.isSubmitting = false,
    this.nameError,
  });

  final String groupName;
  final String description;
  final GroupType groupType;
  final String? groupImagePath;
  final Set<String> selectedMemberIds;
  final String memberSearchQuery;
  final MembersTab membersTab;
  final bool isInitialized;
  final bool isSubmitting;
  final String? nameError;

  int get selectedCount => selectedMemberIds.length;

  CreateGroupState copyWith({
    String? groupName,
    String? description,
    GroupType? groupType,
    String? groupImagePath,
    Set<String>? selectedMemberIds,
    String? memberSearchQuery,
    MembersTab? membersTab,
    bool? isInitialized,
    bool? isSubmitting,
    String? nameError,
    bool clearNameError = false,
  }) {
    return CreateGroupState(
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      groupType: groupType ?? this.groupType,
      groupImagePath: groupImagePath ?? this.groupImagePath,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      memberSearchQuery: memberSearchQuery ?? this.memberSearchQuery,
      membersTab: membersTab ?? this.membersTab,
      isInitialized: isInitialized ?? this.isInitialized,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
    );
  }
}

class CreateGroupNotifier extends Notifier<CreateGroupState> {
  final _imagePicker = ImagePicker();
  AppUser? _creator;

  @override
  CreateGroupState build() => const CreateGroupState();

  void initialize(AppUser creator) {
    if (state.isInitialized) return;
    _creator = creator;
    state = state.copyWith(isInitialized: true);
  }

  void setGroupName(String value) =>
      state = state.copyWith(groupName: value, clearNameError: true);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setGroupType(GroupType type) => state = state.copyWith(groupType: type);

  void setMemberSearchQuery(String query) =>
      state = state.copyWith(memberSearchQuery: query);

  void setMembersTab(MembersTab tab) => state = state.copyWith(membersTab: tab);

  void toggleMember(SelectableUser user) {
    final ids = Set<String>.from(state.selectedMemberIds);
    if (ids.contains(user.uid)) {
      ids.remove(user.uid);
    } else {
      ids.add(user.uid);
    }
    state = state.copyWith(selectedMemberIds: ids);
  }

  Future<void> pickGroupImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      state = state.copyWith(groupImagePath: file.path);
    }
  }

  bool validate() {
    if (state.groupName.trim().isEmpty) {
      state = state.copyWith(nameError: 'Group name is required');
      return false;
    }
    state = state.copyWith(clearNameError: true);
    return true;
  }

  void resetForm() {
    state = const CreateGroupState(
      isInitialized: true,
    );
  }

  Future<String> submit(List<SelectableUser> allUsers) async {
    final creator = _creator;
    if (creator == null) {
      throw const GroupServiceException('Session expired. Please sign in again.');
    }
    if (!validate()) {
      throw const GroupServiceException('Please fix the highlighted fields.');
    }

    final selectedMembers = allUsers
        .where((u) => state.selectedMemberIds.contains(u.uid))
        .toList();

    state = state.copyWith(isSubmitting: true);
    try {
      final exists = await ref
          .read(groupServiceProvider)
          .groupNameExists(state.groupName);
      if (exists) {
        throw const GroupServiceException('Group name already exists');
      }

      final input = CreateGroupInput(
        groupName: state.groupName,
        description: state.description,
        groupImagePath: state.groupImagePath,
        groupType: state.groupType,
        createdBy: creator.uid,
        creatorName: creator.fullName.isEmpty ? 'You' : creator.fullName,
        creatorEmail: creator.email,
        selectedMembers: selectedMembers,
      );
      return await ref.read(groupServiceProvider).createGroup(input);
    } catch (error) {
      throw GroupServiceException(groupServiceErrorMessage(error));
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
