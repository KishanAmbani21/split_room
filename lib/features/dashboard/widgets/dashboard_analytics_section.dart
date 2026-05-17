import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../models/dashboard_data.dart';
import 'section_title.dart';

class DashboardAnalyticsSection extends StatelessWidget {
  const DashboardAnalyticsSection({
    required this.data,
    required this.user,
    super.key,
  });

  final DashboardData data;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = data.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Analytics',
          subtitle: 'Spending insights at a glance',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final statRow = [
              _MiniStat(
                label: AppStrings.totalPending,
                value: summary.needToPay,
                icon: Icons.schedule_rounded,
                color: AppColors.error,
              ),
              _MiniStat(
                label: AppStrings.totalWillReceive,
                value: summary.willReceive,
                icon: Icons.south_west_rounded,
                color: AppColors.success,
              ),
            ];

            return Column(
              children: [
                wide
                    ? Row(
                        children: [
                          Expanded(child: statRow[0]),
                          const SizedBox(width: 10),
                          Expanded(child: statRow[1]),
                        ],
                      )
                    : Column(
                        children: [
                          statRow[0],
                          const SizedBox(height: 10),
                          statRow[1],
                        ],
                      ),
                const SizedBox(height: 12),
                wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _CategoryChart(data: data)),
                          const SizedBox(width: 10),
                          Expanded(child: _MonthlyChart(data: data)),
                        ],
                      )
                    : Column(
                        children: [
                          _CategoryChart(data: data),
                          const SizedBox(height: 10),
                          _MonthlyChart(data: data),
                        ],
                      ),
                if (data.mostActiveGroup != null) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.secondaryColor(
                            theme.brightness,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Most active group',
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                data.mostActiveGroup!.groupName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${AppColors.currencySymbol}${data.mostActiveGroup!.totalExpense.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor(theme.brightness),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        color: AppColors.primaryColor(theme.brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Top category this month',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        data.topCategoryThisMonth,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  '${AppColors.currencySymbol}${value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<PieChartSectionData> _pieSections(List<MapEntry<String, double>> entries) {
  final total = entries.fold<double>(0, (s, e) => s + e.value);
  return [
    for (var i = 0; i < entries.length; i++)
      PieChartSectionData(
        value: entries[i].value,
        color: AppColors.chartColors[i % AppColors.chartColors.length],
        radius: 48,
        title: total > 0
            ? '${((entries[i].value / total) * 100).round()}%'
            : '',
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
  ];
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final entries =
        data.expenseByCategory.entries.where((e) => e.value > 0).toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your share by category',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: entries.isEmpty
                ? const Center(child: Text('No data yet'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: _pieSections(entries),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final monthly = data.monthlySpending;
    final maxY = monthly.fold<double>(
      0,
      (m, item) => item.amount > m ? item.amount : m,
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your monthly share',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 100 : maxY * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= monthly.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          monthly[i].monthLabel,
                          style: const TextStyle(fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < monthly.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: monthly[i].amount,
                          color: AppColors.primary,
                          width: 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
