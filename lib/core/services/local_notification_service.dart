import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows alerts in the Android notification shade (including while app is open).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'room_expense_updates';
  static const _androidChannelName = 'Expense updates';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _androidChannelId,
          _androidChannelName,
          description: 'Group expenses, members, and settlements',
          importance: Importance.high,
        ),
      );
      await android.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (e) {
        if (kDebugMode) debugPrint('[LocalNotification] init failed: $e');
        return;
      }
    }

    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Group expenses, members, and settlements',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
