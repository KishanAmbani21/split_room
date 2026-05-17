import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/group_json_helpers.dart';
import '../services/group_service.dart';
import 'groups_providers.dart';

final editGroupProvider =
    NotifierProvider.autoDispose<EditGroupNotifier, EditGroupState>(
  EditGroupNotifier.new,
);

class EditGroupState {
  const EditGroupState({
    this.groupName = '',
    this.description = '',
    this.groupImagePath = '',
    this.memberCount = 0,
    this.isLoading = true,
    this.isSubmitting = false,
    this.nameError,
  });

  final String groupName;
  final String description;
  final String groupImagePath;
  final int memberCount;
  final bool isLoading;
  final bool isSubmitting;
  final String? nameError;

  EditGroupState copyWith({
    String? groupName,
    String? description,
    String? groupImagePath,
    int? memberCount,
    bool? isLoading,
    bool? isSubmitting,
    String? nameError,
    bool clearNameError = false,
  }) {
    return EditGroupState(
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      groupImagePath: groupImagePath ?? this.groupImagePath,
      memberCount: memberCount ?? this.memberCount,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
    );
  }
}

class EditGroupNotifier extends Notifier<EditGroupState> {
  String? _groupId;
  final _picker = ImagePicker();

  @override
  EditGroupState build() => const EditGroupState();

  Future<void> load(String groupId) async {
    _groupId = groupId;
    try {
      final data = await ref.read(groupServiceProvider).fetchGroup(groupId);
      state = state.copyWith(
        groupName: readGroupString(data, 'group_name', 'groupName'),
        description: readGroupString(data, 'description', 'description'),
        groupImagePath: readGroupString(data, 'group_image', 'groupImage'),
        memberCount: readMemberCount(data),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setGroupName(String v) =>
      state = state.copyWith(groupName: v, clearNameError: true);

  void setDescription(String v) => state = state.copyWith(description: v);

  Future<void> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file != null) {
      state = state.copyWith(groupImagePath: file.path);
    }
  }

  Future<void> save(String userId) async {
    final groupId = _groupId;
    if (groupId == null) {
      throw const GroupServiceException('Group not loaded.');
    }
    if (state.groupName.trim().isEmpty) {
      state = state.copyWith(nameError: 'Group name is required');
      throw const GroupServiceException('Please fix the highlighted fields.');
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(groupServiceProvider).updateGroup(
            groupId: groupId,
            groupName: state.groupName,
            description: state.description,
            groupImagePath: state.groupImagePath,
            updatedBy: userId,
          );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
