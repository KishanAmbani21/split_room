import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'supabase_client.dart';

/// Initializes the Supabase SDK once at app startup.
abstract final class SupabaseBootstrap {
  SupabaseBootstrap._();

  /// Connects to Supabase using [SupabaseConfig].
  ///
  /// Call from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<void> initialize() async {
    try {
      SupabaseConfig.validate();

      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      AppSupabase.isInitialized = true;

      if (kDebugMode) {
        debugPrint('[Supabase] Connected to ${SupabaseConfig.url}');
      }
    } on SupabaseConfigException {
      rethrow;
    } catch (error, stackTrace) {
      AppSupabase.isInitialized = false;
      Error.throwWithStackTrace(
        SupabaseInitException(
          'Failed to initialize Supabase. Check your URL and anon key in '
          'lib/core/config/supabase_config.dart',
          error,
        ),
        stackTrace,
      );
    }
  }
}

/// Wraps failures during [SupabaseBootstrap.initialize].
final class SupabaseInitException implements Exception {
  const SupabaseInitException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    final detail = cause != null ? ' ($cause)' : '';
    return 'SupabaseInitException: $message$detail';
  }
}
