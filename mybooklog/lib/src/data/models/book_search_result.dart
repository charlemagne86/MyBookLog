import '../../core/utils.dart';

/// One book found by an internet search (via Google's book database),
/// tidied up into a predictable shape the app's screens can display.
///
/// A note on ISBNs: an ISBN is the unique product number printed on the back
/// of every published book. This app uses it as the fingerprint that tells
/// two books apart — it is how the app knows "you already have this one".
class BookSearchResult {
  final String? volumeId;
  final String title;
  final List<String> authors;

  /// https-normalized cover URL; empty string when none is available.
  final String thumbnail;

  /// Preferred ISBN (ISBN-13 over ISBN-10), or null when neither is present.
  final String? isbn;

  /// Everything below is optional detail for the book-details panel. Google
  /// omits these inconsistently (e.g. a real lookup of "The Hobbit" came back
  /// with no averageRating, ratingsCount, or subtitle at all) — callers must
  /// treat every one of them as "may be missing", never assume presence.
  final String? subtitle;
  final String? description;
  final String? publisher;

  /// As Google sends it — "2016", "2016-10", or "2016-10-25" — not parsed
  /// into a real date, since the granularity varies per book.
  final String? publishedDate;
  final int? pageCount;
  final List<String> categories;
  final double? averageRating;
  final int? ratingsCount;

  const BookSearchResult({
    required this.volumeId,
    required this.title,
    required this.authors,
    required this.thumbnail,
    required this.isbn,
    this.subtitle,
    this.description,
    this.publisher,
    this.publishedDate,
    this.pageCount,
    this.categories = const <String>[],
    this.averageRating,
    this.ratingsCount,
  });

  /// The author names as one readable line ("Jane Smith, John Doe"), or
  /// "Unknown author" when the search result had none.
  String get authorsLabel =>
      authors.isNotEmpty ? authors.join(', ') : 'Unknown author';

  /// Whether this result carries a usable ISBN (see the class note above).
  bool get hasIsbn => (isbn != null && isbn!.trim().isNotEmpty);

  /// Picks the best ISBN out of the identifiers Google sends back.
  ///
  /// Books often have two: a modern 13-digit one and an older 10-digit one.
  /// We prefer the 13-digit form, fall back to the 10-digit form, and answer
  /// "none" if neither exists. Written defensively because Google's data is
  /// sometimes incomplete or oddly shaped — bad entries are simply skipped.
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

  /// Converts one raw entry from Google's search response into our tidy
  /// format. If the entry is missing its core details entirely, we return
  /// nothing and the entry is dropped from the results list.
  static BookSearchResult? fromGoogleVolume(dynamic item) {
    if (item is! Map<String, dynamic>) return null;
    final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
    if (volumeInfo == null) return null;

    // Dig out the cover picture's web address, if one was provided.
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final thumb = imageLinks != null
        ? imageLinks['thumbnail'] as String?
        : null;

    // Google sends averageRating as either an int or a double depending on
    // the book; num covers both, then we widen to double for a stable type.
    final rawRating = volumeInfo['averageRating'] as num?;

    return BookSearchResult(
      volumeId: item['id'] as String?,
      title: volumeInfo['title'] as String? ?? 'No Title',
      authors:
          (volumeInfo['authors'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      // Normalize to https at ingest (PERF-5).
      thumbnail: toHttpsUrl(thumb),
      isbn: extractPreferredIsbn(volumeInfo['industryIdentifiers']),
      subtitle: volumeInfo['subtitle'] as String?,
      description: volumeInfo['description'] as String?,
      publisher: volumeInfo['publisher'] as String?,
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      categories:
          (volumeInfo['categories'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      averageRating: rawRating?.toDouble(),
      ratingsCount: volumeInfo['ratingsCount'] as int?,
    );
  }

  /// Converts a whole page of Google search results at once, quietly
  /// skipping any entries too broken to use.
  static List<BookSearchResult> listFromGoogleItems(List<dynamic> items) {
    final out = <BookSearchResult>[];
    for (final item in items) {
      final r = fromGoogleVolume(item);
      if (r != null) out.add(r);
    }
    return out;
  }

  /// A "fingerprint" used to spot duplicate search results (the same book
  /// often appears again when loading more pages of results). The ISBN is the
  /// fingerprint when we have one; otherwise the title-plus-authors combo
  /// stands in for it.
  String identityKey() {
    final trimmedIsbn = isbn?.trim();
    if (trimmedIsbn != null && trimmedIsbn.isNotEmpty) {
      return 'isbn:$trimmedIsbn';
    }
    return 'fallback:${volumeKey()}';
  }

  /// A looser grouping key — just title plus authors — used to recognize
  /// different editions of the SAME book (e.g. hardcover vs. paperback) among
  /// the search results.
  String volumeKey() {
    final t = title.trim().toLowerCase();
    final a = authors
        .map((x) => x.trim().toLowerCase())
        .where((x) => x.isNotEmpty)
        .join('|');
    return '$t::$a';
  }

  /// A quick check: does this ISBN look like the modern 13-digit kind?
  /// We only count the digits (ignoring dashes and spaces); we don't verify
  /// the number mathematically. Used to prefer 13-digit editions.
  static bool isLikelyIsbn13(String candidate) {
    return candidate.replaceAll(RegExp(r'[^0-9Xx]'), '').length == 13;
  }
}
