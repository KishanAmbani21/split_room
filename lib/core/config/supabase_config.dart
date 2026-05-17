/// Supabase connection settings.
///
/// Edit the two constants below with values from:
/// Supabase Dashboard → Project Settings → API
///
/// - **Project URL** → [supabaseUrl]
/// - **anon / publishable key** → [supabaseAnonKey]
library;

// ---------------------------------------------------------------------------
// Paste your Supabase credentials here (keep these editable)
// ---------------------------------------------------------------------------

/// Example: `https://your-project-ref.supabase.co`
const String supabaseUrl = 'https://zdakhvfjvjbcqfarppms.supabase.co';

/// Example: `eyJhbG...` or `sb_publishable_...`
const String supabaseAnonKey =
    'sb_publishable_wV3EtuHBqb3Vxt_yiUQszA_DLYjZt5K';

// ---------------------------------------------------------------------------

/// Optional overrides via `--dart-define` (CI / flavors without editing source).
///
/// ```bash
/// flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
/// ```
abstract final class SupabaseConfig {
  SupabaseConfig._();

  static String get url {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    return fromEnv.isNotEmpty ? fromEnv : supabaseUrl;
  }

  static String get anonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    return fromEnv.isNotEmpty ? fromEnv : supabaseAnonKey;
  }

  /// Validates URL and key before [Supabase.initialize].
  static void validate() {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isScheme('https') || uri.host.isEmpty) {
      throw SupabaseConfigException(
        'Invalid supabaseUrl. Paste your Project URL in '
        'lib/core/config/supabase_config.dart',
      );
    }

    if (anonKey.trim().isEmpty ||
        anonKey.contains('your-anon-key') ||
        anonKey.contains('YOUR_')) {
      throw SupabaseConfigException(
        'Invalid supabaseAnonKey. Paste your anon key in '
        'lib/core/config/supabase_config.dart',
      );
    }
  }
}

/// Thrown when [SupabaseConfig] values are missing or invalid.
final class SupabaseConfigException implements Exception {
  const SupabaseConfigException(this.message);

  final String message;

  @override
  String toString() => 'SupabaseConfigException: $message';
}
