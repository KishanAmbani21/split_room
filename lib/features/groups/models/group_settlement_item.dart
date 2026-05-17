/// Pairwise balance between the current user and another group member.
class GroupSettlementItem {
  const GroupSettlementItem({
    required this.userId,
    required this.name,
    required this.amount,
    this.profileImage,
  });

  final String userId;
  final String name;
  final double amount;
  final String? profileImage;
}
