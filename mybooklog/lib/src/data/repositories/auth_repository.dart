import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles everything to do with user accounts: signing in, signing up, and
/// signing out.
///
/// It is a thin wrapper around the Supabase authentication service. Screens
/// talk to this class instead of the raw service, which keeps account logic
/// in one place and makes the screens testable with a pretend version.
class AuthRepository {
  AuthRepository(this._client);
  final SupabaseClient _client;

  /// The user's current login "session", or null if nobody is logged in.
  Session? get currentSession => _client.auth.currentSession;

  /// The currently logged-in user, or null if nobody is logged in.
  User? get currentUser => _client.auth.currentUser;

  /// A live feed of login/logout events; the router listens to this to know
  /// when to move the user between the login screen and the bookshelf.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Checks the email and password with the server and signs the user in.
  /// If the details are wrong, an error is raised for the screen to display.
  /// (Stray spaces around the email are trimmed off first — a common typo.)
  Future<void> signIn({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const AuthException('Invalid credentials or user not found.');
    }
  }

  /// Creates a brand-new account. The first and last name travel along with
  /// the signup request, and the database itself creates the user's profile
  /// row and empty bookshelf the moment the account appears — the app never
  /// writes those records directly, which is safer.
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

  /// Signs the user out and ends their session.
  Future<void> signOut() => _client.auth.signOut();

  /// Translates raw technical error messages into short, friendly sentences
  /// suitable for showing on screen (e.g. "Incorrect email or password."
  /// instead of a server error code).
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
    // Anything unexpected (e.g. no internet) gets a generic, calm message.
    return 'Something went wrong. Please check your connection and retry.';
  }
}
