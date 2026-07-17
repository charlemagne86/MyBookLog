import '../../core/utils.dart';

/// One book as it appears on the user's shelf.
///
/// It bundles together the details needed to draw the book on screen —
/// its title, author, cover picture, and whether the user has marked it as
/// read — combined from the two places the database stores them (the user's
/// personal shelf list, and the shared catalog of book details).
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

  /// Builds a ShelfBook from one raw row of database results.
  ///
  /// The row contains the shelf entry itself plus a nested block of catalog
  /// details (title, author, cover). Missing pieces are handled gently: a
  /// missing title becomes empty text and a missing cover becomes an empty
  /// address, so a slightly incomplete record never crashes the app.
  static ShelfBook fromJoinedRow(Map<String, dynamic> row) {
    final catalog = row['books_catalog'] as Map<String, dynamic>?;
    return ShelfBook(
      bookId: row['book_id'].toString(),
      title: (catalog?['title'] as String?) ?? '',
      author: catalog?['author'] as String?,
      // Upgrade the cover picture's address to the secure form phones accept.
      thumbnailUri: toHttpsUrl(catalog?['thumbnail_uri'] as String?),
      isRead: parseReadValue(row['is_read']),
    );
  }

  /// Makes an identical copy of this book, optionally with a different
  /// read/unread flag. Used when the user toggles "read" so the screen can
  /// swap in the updated version without re-downloading anything.
  ShelfBook copyWith({bool? isRead}) => ShelfBook(
    bookId: bookId,
    title: title,
    author: author,
    thumbnailUri: thumbnailUri,
    isRead: isRead ?? this.isRead,
  );

  /// Interprets the "has this been read?" value from the database.
  ///
  /// Depending on how the data arrives, "yes" can show up as a true/false
  /// value, the number 1, or the word "true". This accepts all of those and
  /// answers anything unrecognized with "not read", the safe default.
  static bool parseReadValue(dynamic raw) {
    if (raw == true || raw == 1) return true;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  /// Answers: does this book match what the user typed in the shelf's search
  /// box? A match is when the typed text appears anywhere in the title or the
  /// author's name, ignoring capital letters.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    return title.toLowerCase().contains(q) ||
        (author ?? '').toLowerCase().contains(q);
  }
}
