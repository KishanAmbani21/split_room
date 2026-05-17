export '../../../core/services/supabase_auth_service.dart'
    show AppAuthException, authErrorMessage;

import '../../../core/services/supabase_auth_service.dart';

/// Auth facade — Supabase Auth + public.users profile.
class AuthRepository {
  AuthRepository({SupabaseAuthService? authService})
      : _auth = authService ?? SupabaseAuthService();

  final SupabaseAuthService _auth;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) =>
      _auth.signUp(fullName: fullName, email: email, password: password);

  Future<void> login({required String email, required String password}) =>
      _auth.login(email: email, password: password);

  Future<void> logout() => _auth.logout();
}
