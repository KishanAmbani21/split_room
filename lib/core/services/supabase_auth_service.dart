import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/models/app_user.dart';

class SupabaseAuthService {
  SupabaseAuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {'full_name': fullName.trim()},
    );

    final user = response.user;
    if (user == null) {
      throw const AppAuthException('Signup failed. Please try again.');
    }

    // Wait for persisted session (skipped when email confirmation is required).
    await _waitForSession(userId: user.id);

    await _upsertProfile(
      userId: user.id,
      email: normalizedEmail,
      fullName: fullName.trim(),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppAuthException('Login failed. Please try again.');
    }

    await _waitForSession(userId: user.id);

    final profile = await ensureUserProfile(user.id);
    if (profile == null) {
      throw const AppAuthException(
        'Could not load your profile. Please try again.',
      );
    }
  }

  Future<void> logout() => _client.auth.signOut();

  /// Loads profile after session is ready; creates row from auth metadata if missing.
  Future<AppUser?> ensureUserProfile(String userId) async {
    await _waitForSession(userId: userId);

    var profile = await fetchUserProfile(userId);
    if (profile != null) return profile;

    final authUser = _client.auth.currentUser;
    if (authUser == null || authUser.id != userId) return null;

    await _upsertProfile(
      userId: userId,
      email: authUser.email ?? '',
      fullName: _fullNameFromAuthUser(authUser),
    );

    return fetchUserProfile(userId);
  }

  Stream<AppUser?> watchUserProfile(String userId) async* {
    yield await ensureUserProfile(userId);

    yield* _client
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return AppUser.fromMap(rows.first);
        });
  }

  Future<AppUser?> fetchUserProfile(String userId) async {
    await _waitForSession(userId: userId);

    try {
      final row = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return null;
      return AppUser.fromMap(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuthService] fetchUserProfile: ${e.message}');
      }
      rethrow;
    }
  }

  /// Ensures JWT is attached before querying `public.users` (fixes cold-start race).
  Future<void> _waitForSession({String? userId}) async {
    if (_client.auth.currentSession != null) return;

    final completer = Completer<void>();
    late final StreamSubscription<AuthState> sub;

    sub = _client.auth.onAuthStateChange.listen((state) {
      final ready = state.session != null ||
          state.event == AuthChangeEvent.initialSession;
      if (ready && _client.auth.currentSession != null) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      await sub.cancel();
    }

    if (_client.auth.currentSession != null) return;
    if (userId != null && _client.auth.currentUser?.id == userId) return;
  }

  Future<void> _upsertProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'email': email.trim().toLowerCase(),
      'full_name': fullName,
      'status': 'active',
      'login_type': 'email',
      'device_type': 'android',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  String _fullNameFromAuthUser(User user) {
    final meta = user.userMetadata;
    final fromMeta = meta?['full_name'] as String? ?? meta?['name'] as String?;
    if (fromMeta != null && fromMeta.trim().isNotEmpty) {
      return fromMeta.trim();
    }
    return user.email?.split('@').first ?? 'User';
  }
}

class AppAuthException implements Exception {
  const AppAuthException(this.message);
  final String message;
}

String authErrorMessage(Object error) {
  if (error is AppAuthException) return error.message;

  if (error is AuthApiException) {
    switch (error.code) {
      case 'user_already_exists':
      case 'email_exists':
        return 'This email is already registered.';
      case 'invalid_credentials':
        return 'Invalid email or password.';
      case 'weak_password':
        return 'Use a stronger password with at least 6 characters.';
      default:
        return error.message;
    }
  }

  if (error is PostgrestException) {
    if (error.code == '42501') {
      return 'Permission denied loading profile. Check Supabase RLS policies.';
    }
    if (error.code == 'PGRST205') {
      return 'Database table "users" is missing. Open Supabase → SQL Editor '
          'and run supabase/migrations/000_quick_fix_users_table.sql';
    }
    return error.message;
  }

  return 'Something went wrong. Please try again.';
}
