import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/expense_group_member.dart';
import '../providers/add_expense_provider.dart';

class SplitMembersSection extends ConsumerWidget {
  const SplitMembersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseProvider);
    final notifier = ref.read(addExpenseProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final share = state.perPersonShare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.purple.withValues(alpha: 0.12),
                AppColors.mint.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pie_chart_rounded, color: AppColors.purple, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.selectedCount > 0
                      ? 'Split equally among ${state.selectedCount} members'
                      : 'Select members to split',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (share > 0)
                Text(
                  '${AppColors.currencySymbol}${share.toStringAsFixed(2)}/each',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.mint,
                  ),
                ),
            ],
          ),
        ),
        if (state.membersError != null) ...[
          const SizedBox(height: 8),
          Text(
            state.membersError!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 14),
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
              brightness: brightness,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
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
    required this.brightness,
  });

  final ExpenseGroupMember member;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = selected ? AppColors.purple : AppColors.blue;
    final hasImage = member.profileImage != null &&
        member.profileImage!.isNotEmpty &&
        File(member.profileImage!).existsSync();

    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.purple.withValues(alpha: 0.2),
                        AppColors.blue.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: selected ? null : AppColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : AppColors.glassBorder(brightness),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accent.withValues(alpha: 0.15),
                  backgroundImage:
                      hasImage ? FileImage(File(member.profileImage!)) : null,
                  child: hasImage
                      ? null
                      : Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Text(
                  member.name.split(' ').first,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_circle_rounded, size: 16, color: accent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
