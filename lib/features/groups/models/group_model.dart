import '../../dashboard/models/group_overview.dart';
import 'group_member_detail.dart';
import 'group_json_helpers.dart';

class GroupModel {
  const GroupModel({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.description,
    required this.createdBy,
    required this.creatorName,
    required this.memberIds,
    required this.memberDetails,
    required this.totalExpense,
    this.createdAt,
    this.updatedAt,
    this.lastExpenseAt,
    this.groupType = 'room',
  });

  final String groupId;
  final String groupName;
  final String groupImage;
  final String description;
  final String createdBy;
  final String creatorName;
  final List<String> memberIds;
  final List<GroupMemberDetail> memberDetails;
  final double totalExpense;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastExpenseAt;
  final String groupType;

  int get memberCount => memberIds.length;

  DateTime? get lastActivityAt {
    if (lastExpenseAt != null && updatedAt != null) {
      return lastExpenseAt!.isAfter(updatedAt!) ? lastExpenseAt : updatedAt;
    }
    return lastExpenseAt ?? updatedAt ?? createdAt;
  }

  factory GroupModel.fromMap(String id, Map<String, dynamic> data) {
    final members = parseMemberDetails(data);
    return GroupModel(
      groupId: data['id'] as String? ?? data['groupId'] as String? ?? id,
      groupName: data['group_name'] as String? ??
          data['groupName'] as String? ??
          'Group',
      groupImage: data['group_image'] as String? ??
          data['groupImage'] as String? ??
          '',
      description: data['description'] as String? ?? '',
      createdBy: data['created_by'] as String? ??
          data['createdBy'] as String? ??
          '',
      creatorName: data['creator_name'] as String? ??
          data['creatorName'] as String? ??
          '',
      memberIds: parseMemberIds(data),
      memberDetails: members,
      totalExpense: (data['total_expense'] as num? ??
              data['totalExpense'] as num?)
          ?.toDouble() ??
          0,
      createdAt: timestampToDate(data['created_at'] ?? data['createdAt']),
      updatedAt: timestampToDate(data['updated_at'] ?? data['updatedAt']),
      lastExpenseAt:
          timestampToDate(data['last_expense_at'] ?? data['lastExpenseAt']),
      groupType: data['group_type'] as String? ??
          data['groupType'] as String? ??
          'room',
    );
  }

  GroupOverview toOverview({double yourBalance = 0}) {
    return GroupOverview(
      groupId: groupId,
      groupName: groupName,
      groupImage: groupImage,
      memberCount: memberCount,
      totalExpense: totalExpense,
      yourBalance: yourBalance,
      groupType: groupType,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
    );
  }
}
