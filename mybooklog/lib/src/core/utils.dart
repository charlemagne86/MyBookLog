// Small, dependency-free helpers shared across the app.

/// Rewrites a web address that starts with the insecure `http://` prefix so
/// it starts with the secure `https://` prefix instead.
///
/// Why this matters: modern phones refuse to download pictures over insecure
/// connections, so without this fix some book covers would silently fail to
/// appear. If there is no address at all, we return an empty piece of text so
/// the caller can show a placeholder icon instead of crashing.
String toHttpsUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://')) {
    return 'https://${url.substring('http://'.length)}';
  }
  return url;
}
