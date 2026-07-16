import '../../core/utils.dart';

/// A book as it appears on the current user's shelf: shelf membership joined
/// with catalog display metadata.
class ShelfBook {
  final String bookId;
  final String title;
  final String? author;

  /// https-normalized cover URL; empty string when none.
  final String thumbnailUri;
  final bool isRead;

  const ShelfBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.thumbnailUri,
    required this.isRead,
  });

  /// Builds from a `bookshelf_items` row with an embedded `books_catalog`
  /// object (the shape returned by the PERF-1 embedded select).
  static ShelfBook fromJoinedRow(Map<String, dynamic> row) {
    final catalog = row['books_catalog'] as Map<String, dynamic>?;
    return ShelfBook(
      bookId: row['book_id'].toString(),
      title: (catalog?['title'] as String?) ?? '',
      author: catalog?['author'] as String?,
      thumbnailUri: toHttpsUrl(catalog?['thumbnail_uri'] as String?),
      isRead: parseReadValue(row['is_read']),
    );
  }

  ShelfBook copyWith({bool? isRead}) => ShelfBook(
    bookId: bookId,
    title: title,
    author: author,
    thumbnailUri: thumbnailUri,
    isRead: isRead ?? this.isRead,
  );

  /// Normalizes the mixed backend types (`bool`/`int`/`String`) `is_read` can
  /// arrive as into a stable bool.
  static bool parseReadValue(dynamic raw) {
    if (raw == true || raw == 1) return true;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  /// Whether this book matches a case-insensitive title/author search query.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    return title.toLowerCase().contains(q) ||
        (author ?? '').toLowerCase().contains(q);
  }
}
