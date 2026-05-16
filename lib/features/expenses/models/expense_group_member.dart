class ExpenseGroupMember {
  const ExpenseGroupMember({
    required this.uid,
    required this.name,
    this.profileImage,
    this.isCreator = false,
  });

  final String uid;
  final String name;
  final String? profileImage;
  final bool isCreator;

  factory ExpenseGroupMember.fromMap(Map<String, dynamic> map) {
    return ExpenseGroupMember(
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Member',
      profileImage: map['profileImage'] as String?,
      isCreator: map['isCreator'] as bool? ?? false,
    );
  }
}
