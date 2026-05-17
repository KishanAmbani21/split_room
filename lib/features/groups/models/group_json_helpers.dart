import '../../../core/utils/json_helpers.dart';
import 'group_member_detail.dart';

DateTime? timestampToDate(dynamic value) => parseDateTime(value);

List<GroupMemberDetail> parseMemberDetails(Map<String, dynamic> data) {
  final raw = data['member_details'] as List? ??
      data['memberDetails'] as List? ??
      data['members'] as List? ??
      [];
  return raw
      .map((m) => GroupMemberDetail.fromMap(Map<String, dynamic>.from(m as Map)))
      .where((m) => m.uid.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> memberDetailsToLegacyMaps(
  List<GroupMemberDetail> members,
) {
  return members.map((m) => m.toMap()).toList();
}

List<String> parseMemberIds(Map<String, dynamic> data) {
  return parseUuidList(data['member_ids'] ?? data['memberIds']);
}

String readGroupString(Map<String, dynamic> data, String snake, String camel,
    [String fallback = '']) {
  return data[snake] as String? ?? data[camel] as String? ?? fallback;
}

int readMemberCount(Map<String, dynamic> data) {
  return parseMemberIds(data).length;
}
