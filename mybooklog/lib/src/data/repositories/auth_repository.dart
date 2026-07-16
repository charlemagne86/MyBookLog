import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase Auth so screens depend on an interface, not the SDK directly
/// (makes them mockable in tests).
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Signs in; throws [AuthException] on failure, or if no session is returned.
  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const AuthException('Invalid credentials or user not found.');
    }
  }

  /// Creates an auth user. First/last name are passed as metadata so the
  /// server-side profile trigger provisions `public.users` (no client write).
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Maps auth errors to concise, user-facing messages.
  static String friendlyMessage(Object error) {
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login') || m.contains('invalid credentials')) {
        return 'Incorrect email or password.';
      }
      if (m.contains('email not confirmed')) {
        return 'Please confirm your email address before logging in.';
      }
      return error.message;
    }
    return 'Something went wrong. Please check your connection and retry.';
  }
}
