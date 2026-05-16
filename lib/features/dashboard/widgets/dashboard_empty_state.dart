import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.actionLabel,
    this.onAction,
    this.accent = AppColors.blue,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.1),
            AppColors.glassFill(brightness),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.08)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brightness == Brightness.dark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
