import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../dashboard/models/monthly_spending.dart';
import '../../models/group_details_data.dart';
import '../premium_section_header.dart';

class GroupAnalyticsCharts extends StatelessWidget {
  const GroupAnalyticsCharts({required this.data, super.key});

  final GroupDetailsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumSectionHeader(
          title: 'Group Analytics',
          subtitle: 'Spending distribution and trends',
          accent: AppColors.cyan,
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 640;
            const chartHeight = 220.0;

            final pieChart = GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By member share',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: chartHeight,
                    child: data.hasExpenses
                        ? _GroupPieChart(
                            expenseByMember: data.expenseByMember,
                          )
                        : const _ChartPlaceholder(
                            message: 'No expenses to chart yet',
                            icon: Icons.pie_chart_outline_rounded,
                          ),
                  ),
                ],
              ),
            );

            final barChart = GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly spending',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: chartHeight,
                    child: data.hasExpenses
                        ? _GroupBarChart(monthly: data.monthlySpending)
                        : const _ChartPlaceholder(
                            message: 'Add expenses to see trends',
                            icon: Icons.bar_chart_rounded,
                          ),
                  ),
                ],
              ),
            );

            if (stacked) {
              return Column(
                children: [
                  pieChart,
                  const SizedBox(height: 12),
                  barChart,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: pieChart),
                const SizedBox(width: 12),
                Expanded(child: barChart),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GroupPieChart extends StatelessWidget {
  const _GroupPieChart({required this.expenseByMember});

  final Map<String, double> expenseByMember;

  @override
  Widget build(BuildContext context) {
    final entries = expenseByMember.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const _ChartPlaceholder(
        message: 'No expense data',
        icon: Icons.pie_chart_outline_rounded,
      );
    }

    final total = entries.fold<double>(0, (s, e) => s + e.value);

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 42,
        sections: [
          for (var i = 0; i < entries.length; i++)
            PieChartSectionData(
              value: entries[i].value,
              color: AppColors.chartColors[i % AppColors.chartColors.length],
              radius: 52,
              title: '${((entries[i].value / total) * 100).round()}%',
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }
}

class _GroupBarChart extends StatelessWidget {
  const _GroupBarChart({required this.monthly});

  final List<MonthlySpending> monthly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxY = monthly.fold<double>(
      0,
      (m, item) => item.amount > m ? item.amount : m,
    );

    return BarChart(
      BarChartData(
        maxY: maxY <= 0 ? 100 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outline.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= monthly.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    monthly[index].monthLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
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
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.purple, AppColors.cyan],
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: scheme.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
          ),
        ],
      ),
    );
  }
}
