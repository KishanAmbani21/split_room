import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/expense_group_member.dart';
import '../providers/add_expense_provider.dart';

class PaidBySelector extends ConsumerWidget {
  const PaidBySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseProvider);
    final notifier = ref.read(addExpenseProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...state.members.map((member) {
          final selected = state.paidByUserId == member.uid;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PaidByTile(
              member: member,
              selected: selected,
              enabled: !state.isSubmitting,
              onTap: () => notifier.setPaidBy(member.uid),
              brightness: brightness,
            ),
          );
        }),
      ],
    );
  }
}

class _PaidByTile extends StatelessWidget {
  const _PaidByTile({
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
    final accent = selected ? AppColors.blue : AppColors.purple;
    final hasImage = member.profileImage != null &&
        member.profileImage!.isNotEmpty &&
        File(member.profileImage!).existsSync();

    return AnimatedScale(
      scale: selected ? 1.01 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.blue.withValues(alpha: 0.16),
                        AppColors.cyan.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: selected ? null : AppColors.glassFill(brightness),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? accent : AppColors.glassBorder(brightness),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: selected
                        ? const LinearGradient(
                            colors: [AppColors.blue, AppColors.cyan],
                          )
                        : null,
                    border: selected
                        ? null
                        : Border.all(
                            color: AppColors.blue.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
