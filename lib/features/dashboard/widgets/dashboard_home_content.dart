import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/app_layout.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/dashboard_providers.dart';
import 'animated_fade_slide.dart';
import 'dashboard_header.dart';
import 'recent_activities_section.dart';
import 'recent_groups_section.dart';
import 'dashboard_analytics_section.dart';
import 'monthly_summary_cards.dart';
import 'pending_balances_section.dart';
import 'recent_expenses_section.dart';

class DashboardHomeContent extends ConsumerWidget {
  const DashboardHomeContent({
    required this.user,
    required this.onProfileTap,
    super.key,
  });

  final AppUser user;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider(user.uid));

    return dashboardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => _DashboardError(
        message: 'Could not load dashboard. Check connection and Firestore rules.',
        onRetry: () => ref.invalidate(dashboardDataProvider(user.uid)),
      ),
      data: (data) {
        return PremiumBackground(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(dashboardDataProvider(user.uid));
              await ref.read(dashboardDataProvider(user.uid).future);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppLayout.scrollPadding(context),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: AppLayout.contentMaxWidth(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedFadeSlide(
                            child: DashboardHeader(
                              user: user,
                              onProfileTap: onProfileTap,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 50),
                            child: MonthlySummaryCards(summary: data.summary),
                          ),
                          const SizedBox(height: 24),
                          if (data.hasPending)
                            AnimatedFadeSlide(
                              delay: const Duration(milliseconds: 70),
                              child: PendingBalancesSection(data: data),
                            ),
                          if (data.hasPending) const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 80),
                            child: DashboardAnalyticsSection(
                              data: data,
                              user: user,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 90),
                            child: RecentGroupsSection(data: data, user: user),
                          ),
                          const SizedBox(height: 24),
                          RecentExpensesSection(data: data),
                          const SizedBox(height: 24),
                          AnimatedFadeSlide(
                            delay: const Duration(milliseconds: 150),
                            child: RecentActivitiesSection(
                              data: data,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
