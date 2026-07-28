/// Real book fixtures fetched from Google Books API for integration testing.
///
/// BUSINESS LOGIC:
/// Integration tests need realistic data to simulate new-user experience.
/// Instead of hardcoding fake books, fetch real books from Google Books API.
/// This validates API integration while testing UI behavior.
///
/// TECHNICAL:
/// 1. Query Google Books API during test setup
/// 2. Cache results for performance (2-3 sec first run, 50ms after)
/// 3. Convert to ShelfBook format for testing
/// 4. Fall back to minimal data if API unavailable (offline testing)

import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';

class RealBookFixtures {
  static final GoogleBooksService _googleBooks = GoogleBooksService();
  static List<ShelfBook>? _cachedTestBooks;
  static List<BookSearchResult>? _cachedSearchResults;

  /// Fetch real books from Google Books API
  /// Used to populate test mocks with realistic data
  /// Caches results for performance across multiple tests
  static Future<List<ShelfBook>> getTestBooks() async {
    // Return cached if available (performance optimization)
    if (_cachedTestBooks != null) {
      return _cachedTestBooks!;
    }

    try {
      // Fetch real books from Google Books API
      // Search for "classic novels" to get diverse, well-known books
      final results = await _googleBooks.search('classic novels');

      // Convert BookSearchResult to ShelfBook for bookshelf testing
      // Take first 5 results for a diverse test set
      _cachedTestBooks = results.take(5).map((book) {
        return ShelfBook(
          bookId: book.isbn ?? 'test-${results.indexOf(book)}',
          title: book.title,
          author: book.author ?? 'Unknown Author',
          thumbnailUri: book.thumbnailUri?.toString() ?? '',
          isRead: false,
        );
      }).toList();

      return _cachedTestBooks!;
    } catch (e) {
      // Fallback: if API unavailable (offline), use minimal test data
      // This ensures tests can still run without network
      return _getFallbackBooks();
    }
  }

  /// Get raw BookSearchResult objects from API (for search test results)
  static Future<List<BookSearchResult>> getSearchResults() async {
    if (_cachedSearchResults != null) {
      return _cachedSearchResults!;
    }

    try {
      _cachedSearchResults = await _googleBooks.search('science fiction');
      return _cachedSearchResults!.take(5).toList();
    } catch (e) {
      return _getFallbackSearchResults();
    }
  }

  /// Fallback test books if Google Books API is unavailable
  /// Used when testing offline or if API is down
  /// Minimal but realistic data to keep tests functional
  static List<ShelfBook> _getFallbackBooks() {
    return [
      ShelfBook(
        bookId: '9780743273565',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        thumbnailUri:
            'https://books.google.com/books/content?id=4XjjJqKPx7MC&printsec=frontcover&img=1',
        isRead: false,
      ),
      ShelfBook(
        bookId: '9780061120084',
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        thumbnailUri:
            'https://books.google.com/books/content?id=PGR2AwAAQBAJ&printsec=frontcover&img=1',
        isRead: false,
      ),
      ShelfBook(
        bookId: '9780451524934',
        title: '1984',
        author: 'George Orwell',
        thumbnailUri:
            'https://books.google.com/books/content?id=chiYEAAAQBAJ&printsec=frontcover&img=1',
        isRead: false,
      ),
      ShelfBook(
        bookId: '9780316769174',
        title: 'The Catcher in the Rye',
        author: 'J.D. Salinger',
        thumbnailUri:
            'https://books.google.com/books/content?id=Ou4GDAAAQBAJ&printsec=frontcover&img=1',
        isRead: false,
      ),
      ShelfBook(
        bookId: '9780142437261',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        thumbnailUri:
            'https://books.google.com/books/content?id=1q_xPwAACAAJ&printsec=frontcover&img=1',
        isRead: false,
      ),
    ];
  }

  /// Fallback search results
  static List<BookSearchResult> _getFallbackSearchResults() {
    return [
      BookSearchResult(
        isbn: '9780553293357',
        title: 'Dune',
        author: 'Frank Herbert',
        description: 'Epic science fiction classic',
        thumbnailUri: Uri.parse(
            'https://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1'),
      ),
      BookSearchResult(
        isbn: '9780451450524',
        title: 'Foundation',
        author: 'Isaac Asimov',
        description: 'Landmark science fiction',
        thumbnailUri: Uri.parse(
            'https://books.google.com/books/content?id=L1DhqwAACAAJ&printsec=frontcover&img=1'),
      ),
      BookSearchResult(
        isbn: '9780316902778',
        title: 'Neuromancer',
        author: 'William Gibson',
        description: 'Cyberpunk classic',
        thumbnailUri: Uri.parse(
            'https://books.google.com/books/content?id=eYnBzSJtcPEC&printsec=frontcover&img=1'),
      ),
      BookSearchResult(
        isbn: '9780375507258',
        title: 'The Left Hand of Darkness',
        author: 'Ursula K. Le Guin',
        description: 'Science fiction masterpiece',
        thumbnailUri: Uri.parse(
            'https://books.google.com/books/content?id=pEGlmPg3C2EC&printsec=frontcover&img=1'),
      ),
      BookSearchResult(
        isbn: '9780441017683',
        title: 'Ender\'s Game',
        author: 'Orson Scott Card',
        description: 'Award-winning science fiction',
        thumbnailUri: Uri.parse(
            'https://books.google.com/books/content?id=yDH2zFEKheYC&printsec=frontcover&img=1'),
      ),
    ];
  }

  /// Clear cache (useful for test isolation if needed)
  static void clearCache() {
    _cachedTestBooks = null;
    _cachedSearchResults = null;
  }
}
