import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/supabase/supabase_bootstrap.dart';
import 'core/supabase/supabase_init_error_app.dart';
import 'firebase_options.dart';
import 'shared/providers/app_providers.dart';

/// Background FCM handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface uncaught async errors in debug builds.
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('[Uncaught] $error\n$stack');
    }
    return true;
  };

  try {
    await _bootstrapApp();
  } catch (error, stackTrace) {
    if (kDebugMode) {
      debugPrint('[Startup failed] $error\n$stackTrace');
    }
    runApp(SupabaseInitErrorApp(error: error, stackTrace: stackTrace));
    return;
  }

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const RoomExpenseApp(),
    ),
  );
}

/// Initializes Firebase (FCM only) and Supabase before the UI loads in parallel.
Future<void> _bootstrapApp() async {
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.android).then((_) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }),
    SupabaseBootstrap.initialize(),
  ]);
}
