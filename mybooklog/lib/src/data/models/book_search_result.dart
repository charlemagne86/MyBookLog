import '../../core/utils.dart';

/// A single candidate book returned by the Google Books API, normalized into a
/// typed shape the UI and add-to-shelf flow can consume.
class BookSearchResult {
  final String? volumeId;
  final String title;
  final List<String> authors;

  /// https-normalized cover URL; empty string when none is available.
  final String thumbnail;

  /// Preferred ISBN (ISBN-13 over ISBN-10), or null when neither is present.
  final String? isbn;

  const BookSearchResult({
    required this.volumeId,
    required this.title,
    required this.authors,
    required this.thumbnail,
    required this.isbn,
  });

  String get authorsLabel =>
      authors.isNotEmpty ? authors.join(', ') : 'Unknown author';

  bool get hasIsbn => (isbn != null && isbn!.trim().isNotEmpty);

  /// Extracts the preferred ISBN from Google Books `industryIdentifiers`.
  /// Prefers ISBN_13, then ISBN_10; null if neither exists. Defensive against
  /// the dynamic, sometimes-malformed shapes Google returns.
  static String? extractPreferredIsbn(dynamic rawIdentifiers) {
    final list = rawIdentifiers as List<dynamic>?;
    String? isbn13;
    String? isbn10;
    if (list != null) {
      for (final raw in list) {
        if (raw is! Map) continue;
        final type = raw['type']?.toString().trim().toUpperCase();
        final value = raw['identifier']?.toString().trim();
        if (value == null || value.isEmpty) continue;
        if (type == 'ISBN_13') {
          isbn13 ??= value;
        } else if (type == 'ISBN_10') {
          isbn10 ??= value;
        }
        if (isbn13 != null && isbn10 != null) break;
      }
    }
    return isbn13 ?? isbn10;
  }

  /// Builds a result from a single Google Books `items[]` entry, or null when
  /// the entry has no usable `volumeInfo`.
  static BookSearchResult? fromGoogleVolume(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final thumb = imageLinks != null
        ? imageLinks['thumbnail'] as String?
        : null;
    return BookSearchResult(
      volumeId: item['id'] as String?,
      title: volumeInfo['title'] as String? ?? 'No Title',
      authors:
          (volumeInfo['authors'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      // Normalize to https at ingest (PERF-5).
      thumbnail: toHttpsUrl(thumb),
      isbn: extractPreferredIsbn(volumeInfo['industryIdentifiers']),
    );
  }

  /// Maps a Google Books `items` array to normalized results, skipping unusable
  /// entries.
  static List<BookSearchResult> listFromGoogleItems(List<dynamic> items) {
    final out = <BookSearchResult>[];
    for (final item in items) {
      final r = fromGoogleVolume(item);
      if (r != null) out.add(r);
    }
    return out;
  }

  /// Cross-page de-duplication key: ISBN when present, else title+authors.
  String identityKey() {
    final trimmedIsbn = isbn?.trim();
    if (trimmedIsbn != null && trimmedIsbn.isNotEmpty) {
      return 'isbn:$trimmedIsbn';
    }
    return 'fallback:${volumeKey()}';
  }

  /// Title+authors grouping key for same-logical-volume heuristics.
  String volumeKey() {
    final t = title.trim().toLowerCase();
    final a = authors
        .map((x) => x.trim().toLowerCase())
        .where((x) => x.isNotEmpty)
        .join('|');
    return '$t::$a';
  }

  /// True when the normalized ISBN looks like an ISBN-13 (digit-count only, not
  /// a checksum). Used to prefer ISBN-13 siblings.
  static bool isLikelyIsbn13(String candidate) {
    return candidate.replaceAll(RegExp(r'[^0-9Xx]'), '').length == 13;
  }
}
