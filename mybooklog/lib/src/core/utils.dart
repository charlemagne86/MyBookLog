// Small, dependency-free helpers shared across the app.

/// Rewrites a `http://` URL to `https://` so images are not blocked by
/// cleartext-traffic policies on Android/iOS release builds. Returns an empty
/// string for null/empty input.
String toHttpsUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  return url;
}
