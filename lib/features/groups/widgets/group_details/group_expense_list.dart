import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../expenses/providers/expense_providers.dart';
import '../../../expenses/services/expense_service.dart';
import '../../models/group_details_data.dart';
import '../../models/group_expense.dart';
import 'group_details_empty_state.dart';
import 'splitwise_expense_tile.dart';

enum ExpenseFilter { overall, paidByMe, othersPaid }

class GroupExpenseList extends ConsumerWidget {
  const GroupExpenseList({
    required this.data,
    required this.currentUserId,
    required this.filter,
    required this.userName,
    required this.onEditExpense,
    this.onExpenseChanged,
    super.key,
  });

  final GroupDetailsData data;
  final String currentUserId;
  final String userName;
  final ExpenseFilter filter;
  final void Function(GroupExpense expense) onEditExpense;
  final VoidCallback? onExpenseChanged;

  List<GroupExpense> get _filtered {
    final expenses = List<GroupExpense>.from(data.expenses);
    switch (filter) {
      case ExpenseFilter.overall:
        return expenses;
      case ExpenseFilter.paidByMe:
        return expenses.where((e) => e.paidBy == currentUserId).toList();
      case ExpenseFilter.othersPaid:
        return expenses.where((e) => e.paidBy != currentUserId).toList();
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    GroupExpense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          'Delete "${expense.title}"? You can restore it from Activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(expenseServiceProvider).deleteExpense(
            expenseId: expense.id,
            deletedBy: currentUserId,
            deletedByName: userName,
          );
      if (!context.mounted) return;
      showAppSnackBar(context, 'Expense deleted');
      onExpenseChanged?.call();
    } on ExpenseServiceException catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!context.mounted) return;
      showAppSnackBar(context, expenseServiceErrorMessage(e), isError: true);
    }
  }

  double get _filteredTotal =>
      _filtered.fold<double>(0, (sum, e) => sum + e.amount);

  bool get _showFullPaidAmount =>
      filter == ExpenseFilter.paidByMe || filter == ExpenseFilter.othersPaid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _filtered;
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          GroupDetailsEmptyState(message: _emptyMessage),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: items.length + (_showFullPaidAmount ? 1 : 0),
      separatorBuilder: (_, index) {
        if (_showFullPaidAmount && index == 0) {
          return const SizedBox(height: 8);
        }
        return Divider(
          height: 1,
          indent: 72,
          color: AppColors.glassBorder(brightness).withValues(alpha: 0.6),
        );
      },
      itemBuilder: (context, index) {
        if (_showFullPaidAmount && index == 0) {
          final label = filter == ExpenseFilter.paidByMe
              ? 'Total you paid'
              : 'Total others paid';
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${AppColors.currencySymbol}${_filteredTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor(brightness),
                  ),
                ),
              ],
            ),
          );
        }

        final expenseIndex = _showFullPaidAmount ? index - 1 : index;
        final expense = items[expenseIndex];
        return SplitwiseExpenseTile(
          expense: expense,
          currentUserId: currentUserId,
          members: data.members,
          showFullPaidAmount: _showFullPaidAmount,
          onEdit: () => onEditExpense(expense),
          onDelete: () => _delete(context, ref, expense),
        );
      },
    );
  }

  String get _emptyMessage {
    switch (filter) {
      case ExpenseFilter.overall:
        return 'No expenses yet. Tap Add Expense to record one.';
      case ExpenseFilter.paidByMe:
        return 'No expenses paid by you yet.';
      case ExpenseFilter.othersPaid:
        return 'No expenses paid by others yet.';
    }
  }
}
