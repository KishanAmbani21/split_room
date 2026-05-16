import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_member_detail.dart';

DateTime? timestampToDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  return null;
}

List<GroupMemberDetail> parseMemberDetails(Map<String, dynamic> data) {
  final raw = data['memberDetails'] as List? ?? data['members'] as List? ?? [];
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
