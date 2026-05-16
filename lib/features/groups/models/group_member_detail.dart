/// Member embedded in a group document (`memberDetails` / legacy `members`).
class GroupMemberDetail {
  const GroupMemberDetail({
    required this.uid,
    required this.name,
    this.email = '',
    this.profileImage = '',
    this.isCreator = false,
  });

  final String uid;
  final String name;
  final String email;
  final String profileImage;
  final bool isCreator;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'profileImage': profileImage,
        'isCreator': isCreator,
      };

  factory GroupMemberDetail.fromMap(Map<String, dynamic> map) {
    return GroupMemberDetail(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Member',
      email: map['email'] as String? ?? '',
      profileImage: map['profileImage'] as String? ?? '',
      isCreator: map['isCreator'] as bool? ?? false,
    );
  }
}
