import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/supabase_realtime_service.dart';
import '../../core/services/fcm_push_service.dart';
import '../models/app_user.dart';
import '../../features/auth/data/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('SharedPreferences must be overridden.'),
);

final themeModeProvider = NotifierProvider<ThemeModeController, bool>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<bool> {
  static const _themeKey = 'is_dark_theme';

  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_themeKey) ?? false;
  }

  void setDarkMode(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_themeKey, value);
  }
}

/// Injected Supabase client — use in repositories / services (data layer).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => AppSupabase.client,
);

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>(
  (ref) => SupabaseAuthService(client: ref.watch(supabaseClientProvider)),
);

final supabaseRealtimeServiceProvider = Provider<SupabaseRealtimeService>(
  (ref) => SupabaseRealtimeService(client: ref.watch(supabaseClientProvider)),
);

final fcmPushServiceProvider = Provider<FcmPushService>(
  (ref) => FcmPushService(client: ref.watch(supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(authService: ref.watch(supabaseAuthServiceProvider)),
);

final authStateProvider = StreamProvider<Session?>((ref) {
  return ref
      .watch(supabaseAuthServiceProvider)
      .authStateChanges
      .map((state) => state.session);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.user.id;
});

/// Profile for dashboard — waits for session, creates row if DB trigger missed it.
final userDocumentProvider = StreamProvider.autoDispose.family<AppUser?, String>((
  ref,
  uid,
) {
  return ref.watch(supabaseAuthServiceProvider).watchUserProfile(uid);
});
