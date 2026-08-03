import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shelf_book.dart';

/// Raised when a shelf operation is attempted without an authenticated user.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
  @override
  String toString() => 'User not authenticated. Please log in.';
}

/// The single gateway for everything stored on the user's bookshelf:
/// loading the list of books, adding one, removing one, and marking one as
/// read or unread. Every screen that touches the shelf goes through here.
class BookshelfRepository {
  BookshelfRepository(this._client);
  final SupabaseClient _client;

  /// The unique ID of the logged-in user. If somehow nobody is logged in,
  /// we stop immediately with a clear error rather than touching the wrong
  /// (or no) data.
  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  /// Fetches the user's entire shelf from the database.
  ///
  /// This asks for the shelf entries AND each book's title, author, and cover
  /// picture in one combined request (rather than one request per book),
  /// which keeps loading fast even for a large shelf. (PERF-1)
  Future<List<ShelfBook>> fetchShelf() async {
    final rows = await _client
        .from('bookshelf_items')
        .select(
          '*, books_catalog(id, title, author, thumbnail_uri, description, '
          'page_count, published_date, publisher, categories, '
          'google_average_rating, google_ratings_count)',
        )
        .eq('bookshelf_user_id', _uid);
    // Convert each raw database row into a typed ShelfBook object the
    // screens can display.
    return List<Map<String, dynamic>>.from(
      rows,
    ).map(ShelfBook.fromJoinedRow).toList();
  }

  /// Adds a book to the shelf.
  ///
  /// The heavy lifting happens inside the database in a single, all-or-nothing
  /// step (`add_book_to_shelf`): the book is filed into the shared catalog if
  /// it isn't there yet, then linked to this user's shelf. Doing both together
  /// means a mid-operation failure can never leave things half-done.
  /// Returns true if the book was ALREADY on the shelf (nothing was changed) —
  /// the screen uses that to tell the user "you already have this one".
  /// (SEC-3 / BUG-1)
  Future<bool> addBook({
    required String isbn,
    required String title,
    required String author,
    required String? thumbnail,
    String? description,
    int? pageCount,
    String? publishedDate,
    String? publisher,
    List<String>? categories,
    double? googleAverageRating,
    int? googleRatingsCount,
  }) async {
    final result = await _client.rpc(
      'add_book_to_shelf',
      params: {
        'p_isbn': isbn,
        'p_title': title,
        'p_author': author,
        'p_thumbnail_uri': thumbnail,
        'p_description': description,
        'p_page_count': pageCount,
        'p_published_date': publishedDate,
        'p_publisher': publisher,
        'p_categories': categories,
        'p_google_average_rating': googleAverageRating,
        'p_google_ratings_count': googleRatingsCount,
      },
    );
    return result is Map && result['already_on_shelf'] == true;
  }

  /// Takes a book off this user's shelf. The book itself stays in the shared
  /// catalog (other users may have it too); only this user's link to it is
  /// deleted.
  Future<void> removeBook(String bookId) async {
    await _client
        .from('bookshelf_items')
        .delete()
        .eq('bookshelf_user_id', _uid)
        .eq('book_id', bookId);
  }

  /// Marks a book as read or unread. When marking as read we also record
  /// today's date; when marking as unread the date is cleared again.
  Future<void> setReadStatus(String bookId, {required bool isRead}) async {
    await _client
        .from('bookshelf_items')
        .update({
          'is_read': isRead,
          'marked_read_on': isRead ? DateTime.now().toIso8601String() : null,
        })
        .eq('bookshelf_user_id', _uid)
        .eq('book_id', bookId);
  }

  /// Saves the user's own 1-5 star rating for a book on their shelf.
  Future<void> setRating(String bookId, {required int? rating}) async {
    await _client
        .from('bookshelf_items')
        .update({'rating': rating})
        .eq('bookshelf_user_id', _uid)
        .eq('book_id', bookId);
  }
}
