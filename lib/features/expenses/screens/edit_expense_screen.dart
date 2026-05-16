import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../groups/models/group_expense.dart';
import '../../groups/models/split_type.dart';
import '../../groups/widgets/gradient_create_button.dart';
import '../../groups/widgets/premium_section_header.dart';
import '../../groups/widgets/section_card.dart';
import '../models/expense_group_member.dart';
import '../providers/edit_expense_provider.dart';
import '../services/expense_service.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  const EditExpenseScreen({
    required this.user,
    required this.expense,
    required this.groupName,
    required this.members,
    required this.memberIds,
    super.key,
  });

  final AppUser user;
  final GroupExpense expense;
  final String groupName;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editExpenseProvider.notifier).load(
            EditExpenseContext(
              expenseId: widget.expense.id,
              groupId: widget.expense.groupId,
              groupName: widget.groupName,
              members: widget.members,
              memberIds: widget.memberIds,
              user: widget.user,
              previousAmount: widget.expense.amount,
            ),
          );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(editExpenseProvider.notifier);
    notifier
      ..setTitle(_titleController.text)
      ..setAmount(_amountController.text)
      ..setNotes(_notesController.text);
    try {
      await notifier.submit();
      if (!mounted) return;
      showAppSnackBar(context, 'Expense updated successfully!');
      Navigator.pop(context, true);
    } on ExpenseServiceException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, expenseServiceErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editExpenseProvider);
    final notifier = ref.read(editExpenseProvider.notifier);

    if (!state.isLoading &&
        _titleController.text.isEmpty &&
        state.title.isNotEmpty) {
      _titleController.text = state.title;
      _amountController.text = state.amountText;
      _notesController.text = state.notes;
    }

    return PremiumBackground(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Edit Expense'),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 32,
                  ),
                  child: Column(
                    children: [
                      SectionCard(
                        child: Column(
                          children: [
                            PremiumSectionHeader(
                              title: 'Details',
                              subtitle: state.groupName,
                              accent: AppColors.blue,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _titleController,
                              enabled: !state.isSubmitting,
                              onChanged: notifier.setTitle,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                errorText: state.titleError,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _amountController,
                              enabled: !state.isSubmitting,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,2}'),
                                ),
                              ],
                              onChanged: notifier.setAmount,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                errorText: state.amountError,
                                prefixText: AppColors.currencySymbol,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _notesController,
                              enabled: !state.isSubmitting,
                              maxLines: 2,
                              onChanged: notifier.setNotes,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const PremiumSectionHeader(
                              title: 'Paid by',
                              accent: AppColors.cyan,
                            ),
                            const SizedBox(height: 10),
                            ...state.members.map(
                              (m) => RadioListTile<String>(
                                value: m.uid,
                                groupValue: state.paidByUserId,
                                onChanged: state.isSubmitting
                                    ? null
                                    : (v) => notifier.setPaidBy(v!),
                                title: Text(m.name),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const PremiumSectionHeader(
                              title: 'Split',
                              accent: AppColors.purple,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: SplitType.values.map((type) {
                                final selected = state.splitType == type;
                                return ChoiceChip(
                                  label: Text(type.label),
                                  selected: selected,
                                  onSelected: state.isSubmitting
                                      ? null
                                      : (selected) {
                                          if (selected) {
                                            notifier.setSplitType(type);
                                          }
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.members.map((m) {
                                final selected =
                                    state.selectedMemberIds.contains(m.uid);
                                return FilterChip(
                                  label: Text(m.name),
                                  selected: selected,
                                  onSelected: state.isSubmitting
                                      ? null
                                      : (_) => notifier.toggleMember(m.uid),
                                );
                              }).toList(),
                            ),
                            if (state.splitType != SplitType.equal) ...[
                              const SizedBox(height: 12),
                              for (final member in state.selectedMembers)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: TextFormField(
                                    enabled: !state.isSubmitting,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: member.name,
                                      suffixText: state.splitType ==
                                              SplitType.percentage
                                          ? '%'
                                          : AppColors.currencySymbol,
                                    ),
                                    onChanged: (v) {
                                      final parsed =
                                          double.tryParse(v.trim()) ?? 0;
                                      if (state.splitType ==
                                          SplitType.percentage) {
                                        notifier.setPercentage(
                                          member.uid,
                                          parsed,
                                        );
                                      } else {
                                        notifier.setCustomAmount(
                                          member.uid,
                                          parsed,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              Text(
                                state.splitType == SplitType.percentage
                                    ? 'Remaining: ${state.remainingPercent.toStringAsFixed(1)}%'
                                    : 'Remaining: ${AppColors.currencySymbol}${state.remainingCustom.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: state.splitExceedsTotal
                                          ? AppColors.error
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                            if (state.splitError != null)
                              Text(
                                state.splitError!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradientCreateButton(
                        label: 'Save Changes',
                        isLoading: state.isSubmitting,
                        onPressed: state.isSubmitting || state.splitExceedsTotal
                            ? null
                            : _submit,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
