import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/shelf_book.dart';

/// Raised when a shelf operation is attempted without an authenticated user.
class NotAuthenticatedException implements Exception {
  const NotAuthenticatedException();
  @override
  String toString() => 'User not authenticated. Please log in.';
}

/// All reads/writes for the current user's bookshelf.
class BookshelfRepository {
  BookshelfRepository(this._client);
  final SupabaseClient _client;

  String get _uid {
    final user = _client.auth.currentUser;
    if (user == null) throw const NotAuthenticatedException();
    return user.id;
  }

  /// Loads the shelf in a single embedded query (PERF-1).
  Future<List<ShelfBook>> fetchShelf() async {
    final rows = await _client
        .from('bookshelf_items')
        .select('*, books_catalog(id, title, author, thumbnail_uri)')
        .eq('bookshelf_user_id', _uid);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map(ShelfBook.fromJoinedRow).toList();
  }

  /// Adds a book via the atomic `add_book_to_shelf` RPC (SEC-3 / BUG-1).
  /// Returns true if the book was already on the shelf (no-op add).
  Future<bool> addBook({
    required String isbn,
    required String title,
    required String author,
    required String? thumbnail,
  }) async {
    final result = await _client.rpc(
      'add_book_to_shelf',
      params: {
        'p_isbn': isbn,
        'p_title': title,
        'p_author': author,
        'p_thumbnail_uri': thumbnail,
      },
    );
    return result is Map && result['already_on_shelf'] == true;
  }

  Future<void> removeBook(String bookId) async {
    await _client
        .from('bookshelf_items')
        .delete()
        .eq('bookshelf_user_id', _uid)
        .eq('book_id', bookId);
  }

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
}
