import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';

/// Shows remaining / over amount for custom or percentage splits.
class SplitRemainingLabel extends StatelessWidget {
  const SplitRemainingLabel({
    required this.splitType,
    required this.remainingCustom,
    required this.remainingPercent,
    required this.splitExceedsTotal,
    required this.hasAmount,
    super.key,
  });

  final SplitType splitType;
  final double remainingCustom;
  final double remainingPercent;
  final bool splitExceedsTotal;
  final bool hasAmount;

  @override
  Widget build(BuildContext context) {
    if (splitType == SplitType.equal || splitType == SplitType.shares) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final exceeds = splitExceedsTotal;
    final color = exceeds
        ? AppColors.errorColor(brightness)
        : AppColors.primaryColor(brightness);

    if (splitType == SplitType.percentage) {
      return Text(
        remainingPercent >= 0
            ? 'Remaining: ${remainingPercent.toStringAsFixed(1)}%'
            : 'Over by: ${(-remainingPercent).toStringAsFixed(1)}%',
        style: theme.textTheme.labelMedium?.copyWith(
          color: remainingPercent < -0.1
              ? AppColors.errorColor(brightness)
              : color,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (!hasAmount) return const SizedBox.shrink();
    return Text(
      remainingCustom >= 0
          ? 'Remaining: ${AppColors.currencySymbol}${remainingCustom.toStringAsFixed(2)}'
          : 'Over by: ${AppColors.currencySymbol}${(-remainingCustom).toStringAsFixed(2)}',
      style: theme.textTheme.labelMedium?.copyWith(
        color: exceeds ? AppColors.errorColor(brightness) : color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
