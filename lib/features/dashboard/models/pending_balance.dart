class PendingBalance {
  const PendingBalance({
    required this.userId,
    required this.name,
    required this.amount,
    required this.isOwedToYou,
    this.groupId,
    this.groupName,
  });

  final String userId;
  final String name;
  final double amount;
  final bool isOwedToYou;
  final String? groupId;
  final String? groupName;
}
