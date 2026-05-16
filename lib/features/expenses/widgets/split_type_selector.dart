import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../../groups/models/split_type.dart';
import '../providers/add_expense_provider.dart';

class SplitTypeSelector extends ConsumerWidget {
  const SplitTypeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addExpenseProvider);
    final notifier = ref.read(addExpenseProvider.notifier);
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final type in SplitType.values) ...[
          _SplitTypeCard(
            type: type,
            selected: state.splitType == type,
            enabled: !state.isSubmitting,
            brightness: brightness,
            onTap: () => notifier.setSplitType(type),
          ),
          if (type != SplitType.values.last) const SizedBox(height: 8),
        ],
        if (state.splitError != null) ...[
          const SizedBox(height: 8),
          Text(
            state.splitError!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
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
    final accent = selected
        ? AppColors.primaryColor(brightness)
        : AppColors.glassBorder(brightness);

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
              color: selected ? AppColors.primary : accent,
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
                    Text(
                      type.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: brightness == Brightness.dark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryColor(brightness),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
