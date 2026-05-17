import '../../../shared/theme/app_colors.dart';
import 'group_member_detail.dart';
import 'group_type.dart';
import 'selectable_user.dart';

class CreateGroupInput {
  const CreateGroupInput({
    required this.groupName,
    required this.description,
    required this.groupType,
    required this.createdBy,
    required this.creatorName,
    required this.creatorEmail,
    required this.selectedMembers,
    this.groupImagePath,
  });

  final String groupName;
  final String description;
  final String? groupImagePath;
  final GroupType groupType;
  final String createdBy;
  final String creatorName;
  final String creatorEmail;
  final List<SelectableUser> selectedMembers;

  List<String> get memberIds {
    final ids = <String>{createdBy, ...selectedMembers.map((m) => m.uid)};
    return ids.toList();
  }

  List<GroupMemberDetail> get memberDetails => [
        GroupMemberDetail(
          uid: createdBy,
          name: creatorName,
          email: creatorEmail,
          isCreator: true,
        ),
        ...selectedMembers.map(
          (m) => GroupMemberDetail(
            uid: m.uid,
            name: m.name,
            email: m.email,
            profileImage: m.profileImageUrl ?? '',
          ),
        ),
      ];

  String get currencyCode => AppColors.currencyCode;

  String get normalizedName => groupName.trim().toLowerCase();

  String get activityLogMessage =>
      '$creatorName created ${groupName.trim()} group';

  Map<String, dynamic> toGroupDocument(String groupId) => {
        'groupId': groupId,
        'groupName': groupName.trim(),
        'groupNameLower': normalizedName,
        'groupImage': groupImagePath ?? '',
        'description': description.trim(),
        'createdBy': createdBy,
        'creatorName': creatorName,
        'memberIds': memberIds,
        'memberDetails': memberDetails.map((m) => m.toMap()).toList(),
        'members': memberDetails.map((m) => m.toMap()).toList(),
        'totalExpense': 0,
        'groupType': groupType.name,
        'splitType': 'equal',
        'currency': AppColors.currencyCode,
        'createdAt': null,
        'updatedAt': null,
      };

  Map<String, dynamic> fullSnapshot(String groupId) => {
        ...toGroupDocument(groupId),
        'createdAt': null,
        'updatedAt': null,
      };
}
