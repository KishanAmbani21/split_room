import '../../groups/models/split_type.dart';
import '../models/add_expense_input.dart';
import '../models/expense_group_member.dart';

List<ExpenseSplitEntry> buildSplitsForType({
  required SplitType splitType,
  required double amount,
  required List<ExpenseGroupMember> members,
  Map<String, double>? customAmounts,
  Map<String, double>? percentages,
  Map<String, int>? shares,
}) {
  switch (splitType) {
    case SplitType.equal:
      return buildEqualSplits(amount, members);
    case SplitType.custom:
      return buildCustomSplits(members, customAmounts ?? {});
    case SplitType.percentage:
      return buildPercentageSplits(amount, members, percentages ?? {});
    case SplitType.shares:
      return buildSharesSplits(amount, members, shares ?? {});
  }
}

/// Split by share count (e.g. 2 shares vs 1 share).
List<ExpenseSplitEntry> buildSharesSplits(
  double amount,
  List<ExpenseGroupMember> members,
  Map<String, int> shares,
) {
  if (members.isEmpty) return [];

  final totalShares = members.fold<int>(
    0,
    (sum, m) => sum + (shares[m.uid] ?? 1).clamp(1, 999),
  );
  if (totalShares <= 0) return buildEqualSplits(amount, members);

  var allocated = 0.0;
  final splits = <ExpenseSplitEntry>[];

  for (var i = 0; i < members.length; i++) {
    final m = members[i];
    final count = (shares[m.uid] ?? 1).clamp(1, 999);
    final share = i == members.length - 1
        ? double.parse((amount - allocated).toStringAsFixed(2))
        : double.parse((amount * count / totalShares).toStringAsFixed(2));
    allocated += share;
    splits.add(ExpenseSplitEntry(userId: m.uid, userName: m.name, amount: share));
  }
  return splits;
}
