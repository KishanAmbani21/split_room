class GroupMemberBalance {
  const GroupMemberBalance({
    required this.userId,
    required this.name,
    required this.balance,
    this.profileImage,
    this.isCreator = false,
  });

  final String userId;
  final String name;
  final double balance;
  final String? profileImage;
  final bool isCreator;

  bool get receivesMoney => balance > 0.01;
  bool get owesMoney => balance < -0.01;
  bool get isSettled => !receivesMoney && !owesMoney;
}
