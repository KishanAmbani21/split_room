import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../../groups/widgets/premium_section_header.dart';
import '../models/expense_group_member.dart';
import '../providers/edit_expense_provider.dart';
import 'split_preview_banner.dart';

/// Split type cards for edit expense (same UX as add expense).
class EditSplitTypeSelector extends ConsumerWidget {
  const EditSplitTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editExpenseProvider);
    final notifier = ref.read(editExpenseProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final type in SplitType.values) ...[
          _SplitTypeCard(
            type: type,
            selected: state.splitType == type,
            enabled: !state.isSubmitting,
            brightness: Theme.of(context).brightness,
            onTap: () => notifier.setSplitType(type),
          ),
          if (type != SplitType.values.last) const SizedBox(height: 8),
        ],
        if (state.splitError != null) ...[
          const SizedBox(height: 8),
          Text(
            state.splitError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.error,
                ),
          ),
        ],
      ],
    );
  }
}

class _SplitTypeCard extends StatelessWidget {
  const _SplitTypeCard({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.brightness,
    required this.onTap,
  });

  final SplitType type;
  final bool selected;
  final bool enabled;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.glassBorder(brightness),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                type.icon,
                color: selected
                    ? AppColors.primaryColor(brightness)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(type.subtitle, style: theme.textTheme.bodySmall),
                    if (selected)
                      Text(
                        type.exampleHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primaryColor(brightness),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor(brightness),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditSplitMembersSection extends ConsumerWidget {
  const EditSplitMembersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editExpenseProvider);
    final notifier = ref.read(editExpenseProvider.notifier);
    final share = state.perPersonShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.people_rounded, color: AppColors.purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.selectedCount > 0
                      ? '${state.selectedCount} members in this split'
                      : 'Select members',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (state.splitType == SplitType.equal && share > 0)
                Text(
                  '${AppColors.currencySymbol}${share.toStringAsFixed(2)}/each',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.mint,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: state.members.map((member) {
            final selected = state.selectedMemberIds.contains(member.uid);
            return _MemberChip(
              member: member,
              selected: selected,
              enabled: !state.isSubmitting,
              onTap: () => notifier.toggleMember(member.uid),
            );
          }).toList(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: state.isSubmitting ? null : notifier.selectAllMembers,
            icon: const Icon(Icons.select_all_rounded, size: 18),
            label: const Text('Select all'),
          ),
        ),
      ],
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({
    required this.member,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final ExpenseGroupMember member;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? AppColors.purple : AppColors.blue;
    final hasImage = member.profileImage != null &&
        member.profileImage!.isNotEmpty &&
        File(member.profileImage!).existsSync();

    return FilterChip(
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      avatar: CircleAvatar(
        radius: 12,
        backgroundImage:
            hasImage ? FileImage(File(member.profileImage!)) : null,
        child: hasImage
            ? null
            : Text(member.name.isNotEmpty ? member.name[0] : '?'),
      ),
      label: Text(member.name.split(' ').first),
      selectedColor: accent.withValues(alpha: 0.2),
      checkmarkColor: accent,
    );
  }
}

class EditExpenseSplitInputs extends ConsumerWidget {
  const EditExpenseSplitInputs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editExpenseProvider);
    if (state.splitType == SplitType.equal) return const SizedBox.shrink();

    final notifier = ref.read(editExpenseProvider.notifier);
    final isPercent = state.splitType == SplitType.percentage;
    final isShares = state.splitType == SplitType.shares;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        for (final member in state.selectedMembers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: isShares
                ? Row(
                    children: [
                      Expanded(child: Text(member.name)),
                      SizedBox(
                        width: 100,
                        child: TextFormField(
                          enabled: !state.isSubmitting,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          initialValue: '${state.shares[member.uid] ?? 1}',
                          decoration: const InputDecoration(
                            labelText: 'Shares',
                            suffixText: '×',
                          ),
                          onChanged: (v) => notifier.setShare(
                            member.uid,
                            int.tryParse(v.trim()) ?? 1,
                          ),
                        ),
                      ),
                    ],
                  )
                : TextFormField(
                    enabled: !state.isSubmitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    initialValue: isPercent
                        ? _fmt(state.percentages[member.uid])
                        : _fmt(state.customAmounts[member.uid]),
                    decoration: InputDecoration(
                      labelText: member.name,
                      suffixText: isPercent ? '%' : AppColors.currencySymbol,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.trim()) ?? 0;
                      if (isPercent) {
                        notifier.setPercentage(member.uid, parsed);
                      } else {
                        notifier.setCustomAmount(member.uid, parsed);
                      }
                    },
                  ),
          ),
        if (state.splitError != null)
          Text(
            state.splitError!,
            style: const TextStyle(color: AppColors.error),
          ),
      ],
    );
  }

  static String? _fmt(double? v) {
    if (v == null || v == 0) return null;
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  }
}

/// Full split block for edit screen (type + members + inputs + preview).
class EditExpenseSplitBlock extends ConsumerWidget {
  const EditExpenseSplitBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editExpenseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionHeader(
          title: 'Split Type',
          subtitle: 'How should this expense be divided?',
          accent: AppColors.purple,
        ),
        const SizedBox(height: 14),
        const EditSplitTypeSelector(),
        const SizedBox(height: 16),
        const PremiumSectionHeader(
          title: 'Members',
          subtitle: 'Who is part of this expense?',
          accent: AppColors.mint,
        ),
        const SizedBox(height: 14),
        const EditSplitMembersSection(),
        const EditExpenseSplitInputs(),
        SplitPreviewBanner(
          amount: state.parsedAmount,
          splitType: state.splitType,
          selectedMembers: state.selectedMembers,
          customAmounts: state.customAmounts,
          percentages: state.percentages,
          shares: state.shares,
        ),
      ],
    );
  }
}
