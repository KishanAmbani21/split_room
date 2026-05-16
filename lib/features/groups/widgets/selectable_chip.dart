import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../models/group_type.dart';

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
    this.accent = AppColors.blue,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  static Color accentFor(GroupType type) {
    switch (type) {
      case GroupType.room:
        return AppColors.blue;
      case GroupType.friends:
        return AppColors.purple;
      case GroupType.trip:
        return AppColors.cyan;
      case GroupType.office:
        return AppColors.amber;
      case GroupType.other:
        return AppColors.mint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: selected ? 1.03 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.2),
                        accent.withValues(alpha: 0.08),
                      ],
                    )
                  : null,
              color: selected
                  ? null
                  : Colors.white.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.06 : 0.7,
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? accent : accent.withValues(alpha: 0.25),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? accent : accent.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? accent : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
