// Small, dependency-free helpers shared across the app.

/// Rewrites a web address that starts with the insecure `http://` prefix so
/// it starts with the secure `https://` prefix instead.
///
/// Why this matters: modern phones refuse to download pictures over insecure
/// connections, so without this fix some book covers would silently fail to
/// appear. If there is no address at all, we return an empty piece of text so
/// the caller can show a placeholder icon instead of crashing.
/// BUSINESS LOGIC:
/// Checks whether a chosen password is strong enough. The same rules apply
/// everywhere a password is chosen — creating an account and resetting a
/// forgotten password — so users never see two different standards.
///
/// The rules: at least 8 characters, containing at least one letter, one
/// number, and one special character (like ! or ?). If a rule is broken,
/// this returns the message to show under the password box; if the password
/// is fine, it returns nothing.
///
/// TECHNICAL:
/// Lives here (not on a screen) so both SignUpScreen and ForgotPasswordScreen
/// share one implementation. Returns null on success — the shape Flutter's
/// form validators expect.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
  final hasNumber = RegExp(r'[0-9]').hasMatch(value);
  final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>\_]').hasMatch(value);
  if (!hasLetter || !hasNumber || !hasSpecial) {
    return 'Password must have at least 1 letter, 1 number, and 1 special character.';
  }
  if (value.length < 8) return 'Password must be at least 8 characters.';
  return null;
}

String toHttpsUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  return url;
}
