import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(firestore: ref.watch(firestoreProvider)),
);

final unreadNotificationCountProvider = StreamProvider.autoDispose
    .family<int, String>((ref, userId) {
  return ref.watch(notificationServiceProvider).watchUnreadCount(userId);
});
