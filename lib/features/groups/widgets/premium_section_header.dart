import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
    this.accent = AppColors.blue,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
