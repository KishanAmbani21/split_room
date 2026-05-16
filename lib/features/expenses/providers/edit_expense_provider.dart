import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../models/add_expense_input.dart';
import '../models/expense_group_member.dart';
import '../services/expense_service.dart';
import 'expense_providers.dart';

final editExpenseProvider =
    NotifierProvider.autoDispose<EditExpenseNotifier, EditExpenseState>(
  EditExpenseNotifier.new,
);

class EditExpenseContext {
  const EditExpenseContext({
    required this.expenseId,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberIds,
    required this.user,
    required this.previousAmount,
  });

  final String expenseId;
  final String groupId;
  final String groupName;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;
  final AppUser user;
  final double previousAmount;
}

class EditExpenseState {
  const EditExpenseState({
    this.title = '',
    this.amountText = '',
    this.notes = '',
    this.expenseDate,
    this.paidByUserId = '',
    this.selectedMemberIds = const {},
    this.receiptImagePath,
    this.members = const [],
    this.memberIds = const [],
    this.groupId = '',
    this.groupName = '',
    this.expenseId = '',
    this.splitType = SplitType.equal,
    this.customAmounts = const {},
    this.percentages = const {},
    this.isLoading = true,
    this.isSubmitting = false,
    this.titleError,
    this.amountError,
    this.membersError,
    this.splitError,
  });

  final String title;
  final String amountText;
  final String notes;
  final DateTime? expenseDate;
  final String paidByUserId;
  final Set<String> selectedMemberIds;
  final String? receiptImagePath;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;
  final String groupId;
  final String groupName;
  final String expenseId;
  final SplitType splitType;
  final Map<String, double> customAmounts;
  final Map<String, double> percentages;
  final bool isLoading;
  final bool isSubmitting;
  final String? titleError;
  final String? amountError;
  final String? membersError;
  final String? splitError;

  int get selectedCount => selectedMemberIds.length;

  double? get parsedAmount {
    final cleaned = amountText.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  List<ExpenseGroupMember> get selectedMembers =>
      members.where((m) => selectedMemberIds.contains(m.uid)).toList();

  double get customTotal =>
      selectedMembers.fold(0.0, (s, m) => s + (customAmounts[m.uid] ?? 0));

  double get percentTotal =>
      selectedMembers.fold(0.0, (s, m) => s + (percentages[m.uid] ?? 0));

  double get remainingCustom {
    final total = parsedAmount;
    if (total == null) return 0;
    return double.parse((total - customTotal).toStringAsFixed(2));
  }

  double get remainingPercent =>
      double.parse((100 - percentTotal).toStringAsFixed(1));

  bool get splitExceedsTotal {
    if (splitType != SplitType.custom || parsedAmount == null) return false;
    return customTotal > parsedAmount! + 0.001;
  }

  EditExpenseState copyWith({
    String? title,
    String? amountText,
    String? notes,
    DateTime? expenseDate,
    String? paidByUserId,
    Set<String>? selectedMemberIds,
    String? receiptImagePath,
    List<ExpenseGroupMember>? members,
    List<String>? memberIds,
    String? groupId,
    String? groupName,
    String? expenseId,
    SplitType? splitType,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
    bool? isLoading,
    bool? isSubmitting,
    String? titleError,
    String? amountError,
    String? membersError,
    String? splitError,
    bool clearTitleError = false,
    bool clearAmountError = false,
    bool clearMembersError = false,
    bool clearSplitError = false,
    bool clearReceipt = false,
  }) {
    return EditExpenseState(
      title: title ?? this.title,
      amountText: amountText ?? this.amountText,
      notes: notes ?? this.notes,
      expenseDate: expenseDate ?? this.expenseDate,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      receiptImagePath:
          clearReceipt ? null : (receiptImagePath ?? this.receiptImagePath),
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      expenseId: expenseId ?? this.expenseId,
      splitType: splitType ?? this.splitType,
      customAmounts: customAmounts ?? this.customAmounts,
      percentages: percentages ?? this.percentages,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      amountError: clearAmountError ? null : (amountError ?? this.amountError),
      membersError:
          clearMembersError ? null : (membersError ?? this.membersError),
      splitError: clearSplitError ? null : (splitError ?? this.splitError),
    );
  }
}

class EditExpenseNotifier extends Notifier<EditExpenseState> {
  final _imagePicker = ImagePicker();
  EditExpenseContext? _context;

  @override
  EditExpenseState build() => const EditExpenseState();

  Future<void> load(EditExpenseContext context) async {
    _context = context;
    final data = await ref
        .read(expenseServiceProvider)
        .fetchExpense(context.expenseId);

    final splitMembers =
        List<String>.from(data['splitMembers'] as List? ?? []);
    final splitTypeName = data['splitType'] as String? ?? 'equal';
    final splitType = SplitType.values.firstWhere(
      (t) => t.name == splitTypeName,
      orElse: () => SplitType.equal,
    );

    final splitsRaw = data['splits'] as List? ?? [];
    final customAmounts = <String, double>{};
    final percentages = <String, double>{};
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;

    for (final s in splitsRaw) {
      final map = Map<String, dynamic>.from(s as Map);
      final uid = map['userId'] as String? ?? '';
      final share = (map['amount'] as num?)?.toDouble() ?? 0;
      if (splitType == SplitType.custom) {
        customAmounts[uid] = share;
      } else if (splitType == SplitType.percentage && amount > 0) {
        percentages[uid] = (share / amount * 100);
      }
    }

    state = EditExpenseState(
      expenseId: context.expenseId,
      groupId: context.groupId,
      groupName: context.groupName,
      members: context.members,
      memberIds: context.memberIds,
      title: data['title'] as String? ?? '',
      amountText: amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2),
      notes: data['notes'] as String? ?? '',
      paidByUserId: data['paidBy'] as String? ?? context.user.uid,
      selectedMemberIds: splitMembers.toSet(),
      receiptImagePath: data['receiptImage'] as String?,
      expenseDate: (data['expenseDate'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
      splitType: splitType,
      customAmounts: customAmounts,
      percentages: percentages,
      isLoading: false,
    );
  }

  void setTitle(String v) =>
      state = state.copyWith(title: v, clearTitleError: true);
  void setAmount(String v) =>
      state = state.copyWith(amountText: v, clearAmountError: true, clearSplitError: true);
  void setNotes(String v) => state = state.copyWith(notes: v);
  void setExpenseDate(DateTime d) => state = state.copyWith(expenseDate: d);
  void setPaidBy(String id) => state = state.copyWith(paidByUserId: id);
  void setSplitType(SplitType t) =>
      state = state.copyWith(splitType: t, clearSplitError: true);

  void setCustomAmount(String uid, double v) {
    final map = Map<String, double>.from(state.customAmounts);
    map[uid] = v;
    state = state.copyWith(customAmounts: map, clearSplitError: true);
  }

  void setPercentage(String uid, double v) {
    final map = Map<String, double>.from(state.percentages);
    map[uid] = v;
    state = state.copyWith(percentages: map, clearSplitError: true);
  }

  void toggleMember(String uid) {
    final ids = Set<String>.from(state.selectedMemberIds);
    if (ids.contains(uid)) {
      if (ids.length <= 1) return;
      ids.remove(uid);
    } else {
      ids.add(uid);
    }
    state = state.copyWith(selectedMemberIds: ids, clearMembersError: true);
  }

  Future<void> pickReceiptImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) state = state.copyWith(receiptImagePath: file.path);
  }

  void clearReceiptImage() => state = state.copyWith(clearReceipt: true);

  String get paidByName {
    for (final m in state.members) {
      if (m.uid == state.paidByUserId) return m.name;
    }
    return 'Member';
  }

  bool validate() {
    var valid = true;
    String? titleError;
    String? amountError;
    String? membersError;
    String? splitError;

    if (state.title.trim().isEmpty) {
      titleError = 'Expense title is required';
      valid = false;
    }

    final amount = state.parsedAmount;
    if (amount == null || amount <= 0) {
      amountError = 'Enter a valid amount greater than 0';
      valid = false;
    }

    if (state.selectedMemberIds.isEmpty) {
      membersError = 'Select at least one member';
      valid = false;
    }

    if (amount != null) {
      if (state.splitType == SplitType.custom) {
        if (state.customTotal > amount + 0.001) {
          splitError = 'Split amounts exceed the total expense';
          valid = false;
        } else if ((state.customTotal - amount).abs() > 0.02) {
          splitError = 'Allocate the full amount (remaining ${AppColors.currencySymbol}${state.remainingCustom.toStringAsFixed(2)})';
          valid = false;
        }
      } else if (state.splitType == SplitType.percentage) {
        if (state.percentTotal > 100.1) {
          splitError = 'Percentages exceed 100%';
          valid = false;
        } else if ((state.percentTotal - 100).abs() > 0.1) {
          splitError = 'Percentages must add up to 100%';
          valid = false;
        }
      }
    }

    state = state.copyWith(
      titleError: titleError,
      amountError: amountError,
      membersError: membersError,
      splitError: splitError,
      clearTitleError: titleError == null,
      clearAmountError: amountError == null,
      clearMembersError: membersError == null,
      clearSplitError: splitError == null,
    );
    return valid;
  }

  List<ExpenseSplitEntry> _buildSplits(double amount) {
    final members = state.selectedMembers;
    switch (state.splitType) {
      case SplitType.equal:
        return buildEqualSplits(amount, members);
      case SplitType.custom:
        return buildCustomSplits(members, state.customAmounts);
      case SplitType.percentage:
        return buildPercentageSplits(amount, members, state.percentages);
    }
  }

  Future<void> submit() async {
    final ctx = _context;
    if (ctx == null) {
      throw const ExpenseServiceException('Session expired.');
    }
    if (!validate()) {
      throw const ExpenseServiceException('Please fix the highlighted fields.');
    }

    final amount = state.parsedAmount!;
    state = state.copyWith(isSubmitting: true);
    try {
      final input = AddExpenseInput(
        groupId: state.groupId,
        groupName: state.groupName,
        title: state.title,
        amount: amount,
        paidBy: state.paidByUserId,
        paidByName: paidByName,
        splitMembers: state.selectedMembers.map((m) => m.uid).toList(),
        splits: _buildSplits(amount),
        memberIds: state.memberIds,
        createdBy: ctx.user.uid,
        createdByName:
            ctx.user.fullName.isEmpty ? 'You' : ctx.user.fullName,
        splitType: state.splitType,
        notes: state.notes,
        receiptImage: state.receiptImagePath ?? '',
        expenseDate: state.expenseDate,
      );

      await ref.read(expenseServiceProvider).updateExpense(
            expenseId: ctx.expenseId,
            input: input,
            previousAmount: ctx.previousAmount,
            updatedByName: input.createdByName,
          );
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
