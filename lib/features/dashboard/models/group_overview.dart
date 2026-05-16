class GroupOverview {
  const GroupOverview({
    required this.groupId,
    required this.groupName,
    required this.groupImage,
    required this.memberCount,
    required this.totalExpense,
    required this.yourBalance,
    required this.groupType,
    this.createdAt,
    this.lastActivityAt,
  });

  final String groupId;
  final String groupName;
  final String groupImage;
  final int memberCount;
  final double totalExpense;
  final double yourBalance;
  final String groupType;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;

  bool get youAreOwed => yourBalance > 0;
  bool get youOwe => yourBalance < 0;
}
