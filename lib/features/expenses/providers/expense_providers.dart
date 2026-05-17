import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../groups/providers/groups_providers.dart';
import '../../notifications/providers/notification_providers.dart';
import '../services/expense_service.dart';

final expenseServiceProvider = Provider<ExpenseService>(
  (ref) => ExpenseService(
    client: ref.watch(supabaseClientProvider),
    notificationService: ref.watch(notificationServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  ),
);
