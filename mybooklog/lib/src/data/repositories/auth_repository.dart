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

  /// BUSINESS LOGIC:
  /// Step 1 of "Forgot password": the user gives us their email and we ask
  /// the server to send them a 6-digit code. Importantly, this succeeds even
  /// if no account exists for that email — the server stays silent so that
  /// nobody can use this form to discover which emails have accounts.
  ///
  /// TECHNICAL:
  /// Calls Supabase's resetPasswordForEmail. We do NOT pass a redirect link,
  /// because the app uses the code-entry ("OTP") flow instead of email links:
  /// the reset email's template shows the {{ .Token }} code, and the user
  /// types it into the app. The email is trimmed first, same as sign-in.
  Future<void> requestPasswordReset({required String email}) =>
      _client.auth.resetPasswordForEmail(email.trim());

  /// BUSINESS LOGIC:
  /// Step 2 of "Forgot password": the user types the 6-digit code from the
  /// email. If it matches, this proves they own the mailbox, and the server
  /// signs them in — which is what authorizes the password change that
  /// follows immediately after.
  ///
  /// TECHNICAL:
  /// Calls verifyOTP with type "recovery" (the password-reset flavor of
  /// one-time codes). A wrong or expired code raises an AuthException that
  /// friendlyMessage() translates. On success Supabase stores a session, and
  /// the router's auth listener fires — the forgot-password screen is exempt
  /// from redirects (see app_router.dart) so the flow is not interrupted
  /// before the new password is saved.
  Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) => _client.auth.verifyOTP(
    type: OtpType.recovery,
    email: email.trim(),
    token: code.trim(),
  );

  /// BUSINESS LOGIC:
  /// Step 3 of "Forgot password": save the user's newly chosen password.
  /// Only works when a session exists (i.e. right after the code above was
  /// accepted), so a stranger cannot change a password without the code.
  ///
  /// TECHNICAL:
  /// Calls updateUser on the current session. Password strength is enforced
  /// by the screen (same validatePassword rules as signup) before this is
  /// ever called; the server applies its own minimum-length check too.
  Future<void> updatePassword({required String newPassword}) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

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
      // Password-reset codes: the server says "Token has expired or is
      // invalid" (or similar) when the 6-digit code is wrong or too old.
      if (m.contains('token') && (m.contains('expired') || m.contains('invalid'))) {
        return 'That code is incorrect or has expired. '
            'Check the code or request a new one.';
      }
      // The server throttles repeated reset requests and code attempts to
      // stop guessing attacks ("rate limit" / "for security purposes ...").
      if (m.contains('rate limit') ||
          m.contains('security purposes') ||
          m.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return error.message;
    }
    // Anything unexpected (e.g. no internet) gets a generic, calm message.
    return 'Something went wrong. Please check your connection and retry.';
  }
}
