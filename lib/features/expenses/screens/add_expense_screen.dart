import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../dashboard/widgets/animated_fade_slide.dart';
import '../../groups/widgets/gradient_create_button.dart';
import '../../groups/widgets/premium_section_header.dart';
import '../../groups/widgets/section_card.dart';
import '../models/expense_group_member.dart';
import '../providers/add_expense_provider.dart';
import '../services/expense_service.dart';
import '../widgets/expense_split_inputs.dart';
import '../widgets/paid_by_selector.dart';
import '../widgets/receipt_image_picker.dart';
import '../widgets/split_members_section.dart';
import '../widgets/split_type_selector.dart';
import '../../groups/models/split_type.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({
    required this.user,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberIds,
    super.key,
  });

  final AppUser user;
  final String groupId;
  final String groupName;
  final List<ExpenseGroupMember> members;
  final List<String> memberIds;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addExpenseProvider.notifier).initialize(
            AddExpenseContext(
              groupId: widget.groupId,
              groupName: widget.groupName,
              members: widget.members,
              memberIds: widget.memberIds,
              user: widget.user,
            ),
          );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = ref.read(addExpenseProvider);
    if (state.isSubmitting) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: state.expenseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.blue,
                  secondary: AppColors.purple,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(addExpenseProvider.notifier).setExpenseDate(picked);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final notifier = ref.read(addExpenseProvider.notifier);
    notifier
      ..setTitle(_titleController.text)
      ..setAmount(_amountController.text)
      ..setNotes(_notesController.text);

    try {
      await notifier.submit();
      if (!mounted) return;
      showAppSnackBar(context, 'Expense saved successfully!');
      Navigator.of(context).pop(true);
    } on ExpenseServiceException catch (error) {
      if (!mounted) return;
      showAppSnackBar(context, error.message, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        expenseServiceErrorMessage(error),
        isError: true,
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addExpenseProvider);
    final notifier = ref.read(addExpenseProvider.notifier);

    if (!state.isInitialized) {
      return PremiumBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildAppBar(context),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          ),
        ),
      );
    }

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hPad = constraints.maxWidth >= 600 ? 28.0 : 20.0;
              final maxWidth =
                  constraints.maxWidth >= 800 ? 640.0 : double.infinity;

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 32),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedFadeSlide(
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PremiumSectionHeader(
                                    title: 'Expense Details',
                                    subtitle: widget.groupName,
                                    accent: AppColors.blue,
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _titleController,
                                    enabled: !state.isSubmitting,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onChanged: notifier.setTitle,
                                    decoration: InputDecoration(
                                      labelText: 'Expense title',
                                      hintText: 'Dinner, groceries, rent...',
                                      errorText: state.titleError,
                                      prefixIcon: Icon(
                                        Icons.label_outline_rounded,
                                        color: AppColors.blue.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
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
                                      hintText: '0.00',
                                      errorText: state.amountError,
                                      prefixIcon: const Padding(
                                        padding: EdgeInsets.only(left: 14, right: 8),
                                        child: Text(
                                          AppColors.currencySymbol,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.blue,
                                          ),
                                        ),
                                      ),
                                      prefixIconConstraints: const BoxConstraints(
                                        minWidth: 0,
                                        minHeight: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _notesController,
                                    enabled: !state.isSubmitting,
                                    maxLines: 2,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    onChanged: notifier.setNotes,
                                    decoration: InputDecoration(
                                      labelText: 'Notes (optional)',
                                      hintText: 'Add a short note...',
                                      alignLabelWithHint: true,
                                      prefixIcon: Icon(
                                        Icons.notes_rounded,
                                        color: AppColors.purple.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _DatePickerField(
                                    label: _formatDate(state.expenseDate),
                                    enabled: !state.isSubmitting,
                                    onTap: _pickDate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 60),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PremiumSectionHeader(
                                    title: 'Paid By',
                                    subtitle: 'Who paid for this expense?',
                                    accent: AppColors.cyan,
                                  ),
                                  const SizedBox(height: 14),
                                  const PaidBySelector(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 120),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PremiumSectionHeader(
                                    title: 'Split Type',
                                    subtitle: 'How should this expense be divided?',
                                    accent: AppColors.purple,
                                  ),
                                  const SizedBox(height: 14),
                                  const SplitTypeSelector(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 150),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  PremiumSectionHeader(
                                    title: 'Members',
                                    subtitle: state.splitType == SplitType.equal
                                        ? 'Equal split among selected members'
                                        : 'Select members and enter split details',
                                    accent: AppColors.mint,
                                  ),
                                  const SizedBox(height: 14),
                                  const SplitMembersSection(),
                                  const ExpenseSplitInputs(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 180),
                            child: SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const PremiumSectionHeader(
                                    title: 'Receipt',
                                    subtitle: 'Optional bill image',
                                    accent: AppColors.mint,
                                  ),
                                  const SizedBox(height: 14),
                                  const ReceiptImagePicker(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 240),
                            child: GradientCreateButton(
                              label: 'Save Expense',
                              isLoading: state.isSubmitting,
                              onPressed: state.isSubmitting ? null : _submit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Add Expense'),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder(brightness)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.amber.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: brightness == Brightness.dark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
