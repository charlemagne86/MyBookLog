/// Centralized, compile-time application configuration.
///
/// Values are injected at build time via `--dart-define` (or
/// `--dart-define-from-file=env.json`) so that secrets never live in source
/// control. See `env.example.json` for the expected keys.
///
/// Example:
/// ```
/// flutter run --dart-define-from-file=env.json
/// ```
class AppConfig {
  AppConfig._();

  /// Google Books API key. Intentionally has NO fallback: the key must be
  /// supplied at build time. Book search is disabled if it is missing, which
  /// [hasGoogleBooksApiKey] surfaces to the UI.
  static const String googleBooksApiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
  );

  /// Supabase project URL. The publishable (anon) key and URL are designed to
  /// be shipped in client apps, so a default is provided for convenience; it
  /// can still be overridden per build.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://asqdogadhpwqpeekvxny.supabase.co',
  );

  /// Supabase publishable (anon) key — safe to ship; protected by RLS.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_pEhvPEbg84LgQlNm9kfsUg_f-AThaqn',
  );

  /// Whether a Google Books API key was provided at build time.
  static bool get hasGoogleBooksApiKey => googleBooksApiKey.isNotEmpty;
}
