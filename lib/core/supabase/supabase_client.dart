import 'package:supabase_flutter/supabase_flutter.dart';

/// Single access point for the Supabase client (clean architecture data layer).
///
/// Use via Riverpod: `ref.watch(supabaseClientProvider)` in
/// `lib/shared/providers/app_providers.dart`, or call [AppSupabase.client]
/// after [SupabaseBootstrap.initialize] in `main.dart`.
abstract final class AppSupabase {
  AppSupabase._();

  /// Whether [SupabaseBootstrap.initialize] completed successfully.
  static bool isInitialized = false;

  /// Live Supabase client. Throws if called before initialization.
  static SupabaseClient get client {
    if (!isInitialized) {
      throw StateError(
        'Supabase is not initialized. Call SupabaseBootstrap.initialize() '
        'in main() before using AppSupabase.client.',
      );
    }
    return Supabase.instance.client;
  }

  /// Signed-in user id, or `null` when logged out.
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Auth session stream for UI / providers.
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
