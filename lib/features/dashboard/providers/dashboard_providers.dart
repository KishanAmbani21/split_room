import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';

export '../models/dashboard_data.dart';

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(firestore: ref.watch(firestoreProvider)),
);

final dashboardNavIndexProvider = NotifierProvider<DashboardNavIndex, int>(
  DashboardNavIndex.new,
);

class DashboardNavIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

/// Cached while dashboard is open — avoids refetching on every tab switch.
final dashboardDataProvider = FutureProvider.autoDispose
    .family<DashboardData, String>((ref, uid) {
  ref.keepAlive();
  return ref.watch(dashboardServiceProvider).fetchDashboard(uid);
});
