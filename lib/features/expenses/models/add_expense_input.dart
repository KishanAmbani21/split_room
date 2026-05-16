import '../../groups/models/split_type.dart';
import 'expense_group_member.dart';

class AddExpenseInput {
  const AddExpenseInput({
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.paidByName,
    required this.splitMembers,
    required this.splits,
    required this.memberIds,
    required this.createdBy,
    required this.createdByName,
    this.splitType = SplitType.equal,
    this.notes = '',
    this.receiptImage = '',
    this.expenseDate,
  });

  final String groupId;
  final String groupName;
  final String title;
  final double amount;
  final String paidBy;
  final String paidByName;
  final List<String> splitMembers;
  final List<ExpenseSplitEntry> splits;
  final List<String> memberIds;
  final String createdBy;
  final String createdByName;
  final SplitType splitType;
  final String notes;
  final String receiptImage;
  final DateTime? expenseDate;

  Map<String, dynamic> toExpenseMap(String expenseId) => {
        'expenseId': expenseId,
        'groupId': groupId,
        'groupName': groupName,
        'title': title.trim(),
        'amount': amount,
        'paidBy': paidBy,
        'paidByName': paidByName,
        'splitMembers': splitMembers,
        'splits': splits.map((s) => s.toMap()).toList(),
        'splitType': splitType.name,
        'notes': notes.trim(),
        'receiptImage': receiptImage,
        'createdAt': null,
        'createdBy': createdBy,
        'memberIds': memberIds,
      };

  Map<String, dynamic> toLogExpenseSnapshot(String expenseId) => {
        'expenseId': expenseId,
        'title': title.trim(),
        'amount': amount,
        'paidBy': paidBy,
        'paidByName': paidByName,
        'splitMembers': splitMembers,
      };
}

class ExpenseSplitEntry {
  const ExpenseSplitEntry({
    required this.userId,
    required this.userName,
    required this.amount,
  });

  final String userId;
  final String userName;
  final double amount;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'amount': amount,
      };
}

/// Builds equal splits; last member absorbs rounding remainder.
List<ExpenseSplitEntry> buildEqualSplits(
  double amount,
  List<ExpenseGroupMember> members,
) {
  if (members.isEmpty) return [];

  final count = members.length;
  final baseShare = (amount / count * 100).round() / 100;
  var allocated = 0.0;
  final splits = <ExpenseSplitEntry>[];

  for (var i = 0; i < members.length; i++) {
    final share = i == count - 1
        ? double.parse((amount - allocated).toStringAsFixed(2))
        : baseShare;
    allocated += share;
    splits.add(
      ExpenseSplitEntry(
        userId: members[i].uid,
        userName: members[i].name,
        amount: share,
      ),
    );
  }

  return splits;
}

List<ExpenseSplitEntry> buildPercentageSplits(
  double amount,
  List<ExpenseGroupMember> members,
  Map<String, double> percentages,
) {
  if (members.isEmpty) return [];
  var allocated = 0.0;
  final splits = <ExpenseSplitEntry>[];

  for (var i = 0; i < members.length; i++) {
    final m = members[i];
    final pct = percentages[m.uid] ?? 0;
    final share = i == members.length - 1
        ? double.parse((amount - allocated).toStringAsFixed(2))
        : double.parse((amount * pct / 100).toStringAsFixed(2));
    allocated += share;
    splits.add(ExpenseSplitEntry(userId: m.uid, userName: m.name, amount: share));
  }
  return splits;
}

List<ExpenseSplitEntry> buildCustomSplits(
  List<ExpenseGroupMember> members,
  Map<String, double> amounts,
) {
  return members
      .map(
        (m) => ExpenseSplitEntry(
          userId: m.uid,
          userName: m.name,
          amount: amounts[m.uid] ?? 0,
        ),
      )
      .toList();
}
