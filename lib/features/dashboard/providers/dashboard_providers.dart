import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../../shared/providers/app_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';

export '../models/dashboard_data.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(
    client: ref.watch(supabaseClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  ),
);

final dashboardNavIndexProvider = NotifierProvider<DashboardNavIndex, int>(
  DashboardNavIndex.new,
);

class DashboardNavIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final dashboardDataProvider = FutureProvider.autoDispose
    .family<DashboardData, String>((ref, uid) {
      ref.keepAlive();
      return ref.watch(dashboardServiceProvider).fetchDashboard(uid);
    });

final dashboardDateRangeProvider =
    NotifierProvider<DashboardDateRangeController, DateTimeRange?>(
      DashboardDateRangeController.new,
    );

class DashboardDateRangeController extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void setRange(DateTimeRange? range) => state = range;
}

final filteredDashboardDataProvider = FutureProvider.autoDispose
    .family<DashboardData, String>((ref, uid) {
      ref.keepAlive();
      final range = ref.watch(dashboardDateRangeProvider);
      return ref
          .watch(dashboardServiceProvider)
          .fetchDashboard(uid, start: range?.start, end: range?.end);
    });
