import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../providers/add_expense_provider.dart';

class ExpenseSplitInputs extends ConsumerWidget {
  const ExpenseSplitInputs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseProvider);
    if (state.splitType == SplitType.equal) return const SizedBox.shrink();

    final notifier = ref.read(addExpenseProvider.notifier);
    final theme = Theme.of(context);
    final errorColor = AppColors.errorColor(theme.brightness);

    final isPercent = state.splitType == SplitType.percentage;
    final isShares = state.splitType == SplitType.shares;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Text(
          isShares
              ? 'Shares per member (higher = pays more)'
              : isPercent
                  ? 'Percentage per member'
                  : 'Exact amount per member',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final member in state.selectedMembers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: isShares
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          key: ValueKey('share_${member.uid}'),
                          enabled: !state.isSubmitting,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          initialValue:
                              '${state.shares[member.uid] ?? 1}',
                          decoration: const InputDecoration(
                            labelText: 'Shares',
                            suffixText: '×',
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v.trim()) ?? 1;
                            notifier.setShare(
                              member.uid,
                              parsed.clamp(1, 99),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : TextFormField(
                    key: ValueKey('${state.splitType.name}_${member.uid}'),
                    enabled: !state.isSubmitting,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    initialValue: isPercent
                        ? _formatVal(state.percentages[member.uid])
                        : _formatVal(state.customAmounts[member.uid]),
                    decoration: InputDecoration(
                      labelText: member.name,
                      suffixText: isPercent ? '%' : AppColors.currencySymbol,
                      errorText: !isPercent && state.splitExceedsTotal
                          ? 'Exceeds total'
                          : null,
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
        if (isShares && state.parsedAmount != null)
          Text(
            'Total shares: ${state.totalShares} → '
            '${AppColors.currencySymbol}${state.perShareAmount.toStringAsFixed(2)} per share',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primaryColor(theme.brightness),
              fontWeight: FontWeight.w700,
            ),
          )
        else
          _RemainingLabel(state: state, isPercent: isPercent),
        if (state.splitExceedsTotal)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Entered amounts exceed the total expense',
              style: theme.textTheme.bodySmall?.copyWith(color: errorColor),
            ),
          )
        else if (state.splitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              state.splitError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.splitExceedsTotal ? errorColor : null,
              ),
            ),
          ),
      ],
    );
  }

  static String? _formatVal(double? v) {
    if (v == null || v == 0) return null;
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  }
}

class _RemainingLabel extends StatelessWidget {
  const _RemainingLabel({required this.state, required this.isPercent});

  final AddExpenseState state;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final exceeds = state.splitExceedsTotal;
    final color = exceeds
        ? AppColors.errorColor(brightness)
        : AppColors.primaryColor(brightness);

    if (isPercent) {
      final remaining = state.remainingPercent;
      return Text(
        remaining >= 0
            ? 'Remaining: ${remaining.toStringAsFixed(1)}%'
            : 'Over by: ${(-remaining).toStringAsFixed(1)}%',
        style: theme.textTheme.labelMedium?.copyWith(
          color: remaining < -0.1 ? AppColors.errorColor(brightness) : color,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (state.parsedAmount == null) return const SizedBox.shrink();
    final remaining = state.remainingCustom;
    return Text(
      remaining >= 0
          ? 'Remaining: ${AppColors.currencySymbol}${remaining.toStringAsFixed(2)}'
          : 'Over by: ${AppColors.currencySymbol}${(-remaining).toStringAsFixed(2)}',
      style: theme.textTheme.labelMedium?.copyWith(
        color: exceeds ? AppColors.errorColor(brightness) : color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
