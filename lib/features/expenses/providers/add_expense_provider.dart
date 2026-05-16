import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../models/add_expense_input.dart';
import '../models/expense_group_member.dart';
import '../services/expense_service.dart';
import 'expense_providers.dart';

final addExpenseProvider =
    NotifierProvider.autoDispose<AddExpenseNotifier, AddExpenseState>(
  AddExpenseNotifier.new,
);

class AddExpenseContext {
  const AddExpenseContext({
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberIds,
    required this.user,
  });

  final String groupId;
  final String groupName;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;
  final AppUser user;
}

class AddExpenseState {
  const AddExpenseState({
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
    this.splitType = SplitType.equal,
    this.customAmounts = const {},
    this.percentages = const {},
    this.isInitialized = false,
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
  final SplitType splitType;
  final Map<String, double> customAmounts;
  final Map<String, double> percentages;
  final bool isInitialized;
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

  ExpenseGroupMember? memberById(String uid) {
    for (final m in members) {
      if (m.uid == uid) return m;
    }
    return null;
  }

  String get paidByName =>
      memberById(paidByUserId)?.name ??
      (paidByUserId.isEmpty ? 'Someone' : 'Member');

  List<ExpenseGroupMember> get selectedMembers =>
      members.where((m) => selectedMemberIds.contains(m.uid)).toList();

  double get perPersonShare {
    final amount = parsedAmount;
    if (amount == null || selectedCount == 0) return 0;
    return amount / selectedCount;
  }

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

  AddExpenseState copyWith({
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
    SplitType? splitType,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
    bool? isInitialized,
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
    return AddExpenseState(
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
      splitType: splitType ?? this.splitType,
      customAmounts: customAmounts ?? this.customAmounts,
      percentages: percentages ?? this.percentages,
      isInitialized: isInitialized ?? this.isInitialized,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      titleError: clearTitleError ? null : (titleError ?? this.titleError),
      amountError: clearAmountError ? null : (amountError ?? this.amountError),
      membersError:
          clearMembersError ? null : (membersError ?? this.membersError),
      splitError: clearSplitError ? null : (splitError ?? this.splitError),
    );
  }
}

class AddExpenseNotifier extends Notifier<AddExpenseState> {
  final _imagePicker = ImagePicker();
  AddExpenseContext? _context;

  @override
  AddExpenseState build() => AddExpenseState(expenseDate: DateTime.now());

  void initialize(AddExpenseContext context) {
    if (state.isInitialized) return;
    _context = context;
    final allIds = context.members.map((m) => m.uid).toSet();
    state = state.copyWith(
      groupId: context.groupId,
      groupName: context.groupName,
      members: context.members,
      memberIds: context.memberIds,
      paidByUserId: context.user.uid,
      selectedMemberIds: allIds,
      isInitialized: true,
    );
  }

  void setTitle(String value) =>
      state = state.copyWith(title: value, clearTitleError: true);

  void setAmount(String value) =>
      state = state.copyWith(amountText: value, clearAmountError: true);

  void setNotes(String value) => state = state.copyWith(notes: value);

  void setExpenseDate(DateTime date) =>
      state = state.copyWith(expenseDate: date);

  void setPaidBy(String userId) =>
      state = state.copyWith(paidByUserId: userId);

  void setSplitType(SplitType type) =>
      state = state.copyWith(splitType: type, clearSplitError: true);

  void setCustomAmount(String uid, double value) {
    final map = Map<String, double>.from(state.customAmounts);
    map[uid] = value;
    state = state.copyWith(customAmounts: map, clearSplitError: true);
  }

  void setPercentage(String uid, double value) {
    final map = Map<String, double>.from(state.percentages);
    map[uid] = value;
    state = state.copyWith(percentages: map, clearSplitError: true);
  }

  void toggleMember(String userId) {
    final ids = Set<String>.from(state.selectedMemberIds);
    if (ids.contains(userId)) {
      if (ids.length <= 1) return;
      ids.remove(userId);
    } else {
      ids.add(userId);
    }
    state = state.copyWith(
      selectedMemberIds: ids,
      clearMembersError: true,
      clearSplitError: true,
    );
  }

  void selectAllMembers() {
    state = state.copyWith(
      selectedMemberIds: state.members.map((m) => m.uid).toSet(),
      clearMembersError: true,
    );
  }

  Future<void> pickReceiptImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file != null) {
      state = state.copyWith(receiptImagePath: file.path);
    }
  }

  void clearReceiptImage() => state = state.copyWith(clearReceipt: true);

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
      membersError = 'Select at least one member to split with';
      valid = false;
    }

    if (amount != null && state.selectedMemberIds.isNotEmpty) {
      switch (state.splitType) {
        case SplitType.equal:
          break;
        case SplitType.custom:
          if (state.splitExceedsTotal) {
            splitError = 'Split amounts exceed the total expense';
            valid = false;
          } else if (state.remainingCustom.abs() > 0.02) {
            splitError =
                'Remaining: ${AppColors.currencySymbol}${state.remainingCustom.toStringAsFixed(2)}';
            valid = false;
          }
        case SplitType.percentage:
          if (state.percentTotal > 100.1) {
            splitError = 'Percentages exceed 100%';
            valid = false;
          } else if (state.remainingPercent.abs() > 0.1) {
            splitError = 'Remaining: ${state.remainingPercent.toStringAsFixed(1)}%';
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

  Future<String> submit() async {
    final ctx = _context;
    if (ctx == null) {
      throw const ExpenseServiceException('Session expired. Please try again.');
    }
    if (!validate()) {
      throw const ExpenseServiceException('Please fix the highlighted fields.');
    }

    final amount = state.parsedAmount!;
    final splits = _buildSplits(amount);

    state = state.copyWith(isSubmitting: true);
    try {
      final input = AddExpenseInput(
        groupId: state.groupId,
        groupName: state.groupName,
        title: state.title,
        amount: amount,
        paidBy: state.paidByUserId,
        paidByName: state.paidByName,
        splitMembers: state.selectedMembers.map((m) => m.uid).toList(),
        splits: splits,
        memberIds: state.memberIds,
        createdBy: ctx.user.uid,
        createdByName:
            ctx.user.fullName.isEmpty ? 'You' : ctx.user.fullName,
        splitType: state.splitType,
        notes: state.notes,
        receiptImage: state.receiptImagePath ?? '',
        expenseDate: state.expenseDate,
      );

      return await ref.read(expenseServiceProvider).createExpense(input);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
