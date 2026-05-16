class GroupExpense {
  const GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.splits,
    this.createdAt,
  });

  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final String paidByName;
  final List<ExpenseSplit> splits;
  final DateTime? createdAt;

  /// Positive = current user should receive; negative = current user owes.
  double balanceImpactFor(String currentUserId) {
    if (paidBy == currentUserId) {
      return splits
          .where((s) => s.userId != currentUserId)
          .fold<double>(0, (t, s) => t + s.amount);
    }
    final owed = splits
        .where((s) => s.userId == currentUserId)
        .fold<double>(0, (t, s) => t + s.amount);
    return -owed;
  }
}

class ExpenseSplit {
  const ExpenseSplit({
    required this.userId,
    required this.userName,
    required this.amount,
  });

  final String userId;
  final String userName;
  final double amount;
}
