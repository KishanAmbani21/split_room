class RecentExpenseItem {
  const RecentExpenseItem({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.amount,
    required this.paidByName,
    required this.createdAt,
    required this.balanceImpact,
  });

  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final double amount;
  final String paidByName;
  final DateTime? createdAt;
  final double balanceImpact;
}
