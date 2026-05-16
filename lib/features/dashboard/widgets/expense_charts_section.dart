import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../groups/group_details_route.dart';
import '../models/dashboard_data.dart';
import '../models/group_overview.dart';
import '../models/monthly_spending.dart';
import 'dashboard_empty_state.dart';
import 'group_spending_card.dart';
import 'section_title.dart';

class ExpenseChartsSection extends StatelessWidget {
  const ExpenseChartsSection({
    required this.data,
    required this.user,
    super.key,
  });

  final DashboardData data;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!data.hasGroups) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Group Analytics'),
          const SizedBox(height: 12),
          DashboardEmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No groups yet',
            subtitle: 'Create a group to see expense charts and analytics.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Group Analytics',
          subtitle: 'Spending breakdown across your groups',
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 640;
            final chartHeight = 220.0;

            final pieChart = GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By group',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: chartHeight,
                    child: data.hasExpenses
                        ? _PieChartWidget(
                            expenseByGroup: data.expenseByGroup,
                            groups: data.groups,
                            colors: AppColors.chartColors,
                          )
                        : _ChartPlaceholder(
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
                        ? _BarChartWidget(monthly: data.monthlySpending)
                        : _ChartPlaceholder(
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
        const SizedBox(height: 16),
        const SectionTitle(title: 'Your groups'),
        const SizedBox(height: 10),
        if (data.groups.isEmpty)
          const DashboardEmptyState(
            icon: Icons.groups_outlined,
            title: 'No group cards',
            subtitle: 'Join or create a group to see spending cards.',
          )
        else
          ...data.groups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GroupSpendingCard(
                group: group,
                onTap: () => openGroupDetailsScreen(
                  context,
                  user: user,
                  groupId: group.groupId,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  const _PieChartWidget({
    required this.expenseByGroup,
    required this.groups,
    required this.colors,
  });

  final Map<String, double> expenseByGroup;
  final List<GroupOverview> groups;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final entries = expenseByGroup.entries.where((e) => e.value > 0).toList();
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
              color: colors[i % colors.length],
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

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({required this.monthly});

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
                if (index < 0 || index >= monthly.length) return const SizedBox.shrink();
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
                    colors: [AppColors.blue, AppColors.cyan],
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
