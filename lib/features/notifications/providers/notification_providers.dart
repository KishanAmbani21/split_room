import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    client: ref.watch(supabaseClientProvider),
    realtime: ref.watch(supabaseRealtimeServiceProvider),
    fcmPush: ref.watch(fcmPushServiceProvider),
  ),
);

final notificationInitProvider = FutureProvider.autoDispose
    .family<void, String>((ref, userId) async {
  await ref.read(notificationServiceProvider).initializeForUser(userId);
});

final unreadNotificationCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).watchUnreadCount(userId);
});
