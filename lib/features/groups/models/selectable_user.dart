class SelectableUser {
  const SelectableUser({
    required this.uid,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  final String uid;
  final String name;
  final String email;
  final String? profileImageUrl;

  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  Map<String, dynamic> toMemberMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'profileImage': profileImageUrl,
      };
}
