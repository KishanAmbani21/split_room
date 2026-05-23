import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/theme/app_colors.dart';
import '../providers/dashboard_providers.dart';

class DashboardDateFilter extends ConsumerWidget {
  const DashboardDateFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardDateRangeProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            icon: Icons.calendar_month_rounded,
            label: range == null ? 'All time' : _rangeLabel(range),
            selected: range != null,
            onTap: () => _pickDate(context, ref),
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            icon: Icons.today_rounded,
            label: 'Today',
            selected: _isToday(range),
            onTap: () {
              final now = DateTime.now();
              ref
                  .read(dashboardDateRangeProvider.notifier)
                  .setRange(DateTimeRange(start: now, end: now));
            },
          ),
          const SizedBox(width: 8),
          _FilterChipButton(
            icon: Icons.view_week_rounded,
            label: 'This month',
            selected: _isThisMonth(range),
            onTap: () {
              final now = DateTime.now();
              ref
                  .read(dashboardDateRangeProvider.notifier)
                  .setRange(
                    DateTimeRange(
                      start: DateTime(now.year, now.month, 1),
                      end: DateTime(now.year, now.month + 1, 0),
                    ),
                  );
            },
          ),
          if (range != null) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
              label: const Text('Clear'),
              onPressed: () =>
                  ref.read(dashboardDateRangeProvider.notifier).setRange(null),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dashboardDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: current,
      helpText: 'Select dates',
      saveText: 'Apply',
    );
    if (picked == null) return;
    ref.read(dashboardDateRangeProvider.notifier).setRange(picked);
  }

  static bool _isToday(DateTimeRange? range) {
    if (range == null) return false;
    final now = DateTime.now();
    return _sameDay(range.start, now) && _sameDay(range.end, now);
  }

  static bool _isThisMonth(DateTimeRange? range) {
    if (range == null) return false;
    final now = DateTime.now();
    return range.start.year == now.year &&
        range.start.month == now.month &&
        range.start.day == 1 &&
        range.end.year == now.year &&
        range.end.month == now.month &&
        range.end.day == DateTime(now.year, now.month + 1, 0).day;
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _rangeLabel(DateTimeRange range) {
    if (_sameDay(range.start, range.end)) {
      return _dateLabel(range.start);
    }
    return '${_dateLabel(range.start)} - ${_dateLabel(range.end)}';
  }

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = AppColors.primaryColor(theme.brightness);

    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? primary : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: selected ? primary : theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      side: BorderSide(
        color: selected
            ? primary.withValues(alpha: 0.5)
            : theme.colorScheme.outline.withValues(alpha: 0.25),
      ),
      onPressed: onTap,
    );
  }
}
