import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';

// BUSINESS LOGIC:
// Services perform external integrations (API calls, authentication).
// Mocking services lets us test without internet or external account setup,
// and simulate error scenarios (API down, timeout, malformed response).
//
// TECHNICAL:
// These mocks stub service method returns using mocktail.

class MockGoogleBooksService extends Mock implements GoogleBooksService {}

// Setup helpers for Google Books Service scenarios
class GoogleBooksServiceSetupHelpers {
  // BUSINESS LOGIC:
  // Successful book search returns matching books from Google Books
  // TECHNICAL: Returns list of BookSearchResult with real API structure
  static void setupSuccessfulSearch(
    MockGoogleBooksService service, {
    required List<BookSearchResult> results,
  }) {
    when(() => service.searchBooks(query: any(named: 'query')))
        .thenAnswer((_) async => results);
  }

  // BUSINESS LOGIC:
  // Search returns no results (book not in catalog)
  // TECHNICAL: Returns empty list successfully
  static void setupEmptySearchResults(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query')))
        .thenAnswer((_) async => []);
  }

  // BUSINESS LOGIC:
  // Network timeout when searching (slow/no internet)
  // TECHNICAL: Throws TimeoutException
  static void setupSearchTimeout(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('Request timeout'),
    );
  }

  // BUSINESS LOGIC:
  // API returns error (service unavailable, rate limited, etc)
  // TECHNICAL: Throws with HTTP status code and message
  static void setupSearchApiError(
    MockGoogleBooksService service, {
    required int statusCode,
    required String message,
  }) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('API Error $statusCode: $message'),
    );
  }

  // BUSINESS LOGIC:
  // API returns malformed data (missing fields, corrupt JSON)
  // TECHNICAL: Throws with parsing error
  static void setupSearchMalformedData(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('Failed to parse search results'),
    );
  }

  // BUSINESS LOGIC:
  // Search returns very large dataset (1000+ books)
  // TECHNICAL: Returns list with many items for performance testing
  static void setupLargeSearchResults(
    MockGoogleBooksService service, {
    int count = 1000,
  }) {
    final results = List.generate(
      count,
      (i) => BookSearchResult(
        id: 'book-$i',
        title: 'Large Dataset Book $i',
        author: 'Author $i',
        isbn13: '978000000000$i',
        imageUrl: 'https://books.google.com/books/content?id=book$i',
      ),
    );
    when(() => service.searchBooks(query: any(named: 'query')))
        .thenAnswer((_) async => results);
  }

  // BUSINESS LOGIC:
  // Search returns books with special characters (Unicode)
  // TECHNICAL: Returns results with international characters in title/author
  static void setupSpecialCharacterResults(MockGoogleBooksService service) {
    final results = [
      BookSearchResult(
        id: 'special-1',
        title: 'Test™ 中文 العربية',
        author: 'Author™ 中文',
        isbn13: '9780123456789',
        imageUrl: 'https://books.google.com/books/content?id=special1',
      ),
      BookSearchResult(
        id: 'special-2',
        title: 'Señor García Márquez',
        author: 'José María de Pereda',
        isbn13: '9780123456790',
        imageUrl: 'https://books.google.com/books/content?id=special2',
      ),
    ];
    when(() => service.searchBooks(query: any(named: 'query')))
        .thenAnswer((_) async => results);
  }

  // BUSINESS LOGIC:
  // Search fails due to 401 Unauthorized (API key invalid)
  // TECHNICAL: Throws with authentication error
  static void setupUnauthorizedError(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('401: Unauthorized - Invalid API key'),
    );
  }

  // BUSINESS LOGIC:
  // Search fails due to 403 Forbidden (quota exceeded)
  // TECHNICAL: Throws with rate limit error
  static void setupForbiddenError(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('403: Forbidden - Rate limit exceeded'),
    );
  }

  // BUSINESS LOGIC:
  // Search fails due to 404 Not Found (endpoint gone)
  // TECHNICAL: Throws with 404 error
  static void setupNotFoundError(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('404: Not Found - Endpoint no longer available'),
    );
  }

  // BUSINESS LOGIC:
  // Search fails due to 500 Internal Server Error
  // TECHNICAL: Throws with server error
  static void setupServerError(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('500: Internal Server Error'),
    );
  }

  // BUSINESS LOGIC:
  // Search fails due to 503 Service Unavailable
  // TECHNICAL: Throws with service unavailable error
  static void setupServiceUnavailableError(MockGoogleBooksService service) {
    when(() => service.searchBooks(query: any(named: 'query'))).thenThrow(
      Exception('503: Service Unavailable'),
    );
  }
}

// Test data factories for BookSearchResult
class TestBookSearchResultFactory {
  // BUSINESS LOGIC:
  // Create a realistic search result matching Google Books API structure
  // TECHNICAL: Returns complete BookSearchResult with all fields populated
  static BookSearchResult createTestResult({
    String? volumeId,
    String title = 'Test Book',
    String author = 'Test Author',
    String? isbn,
    String thumbnail = 'https://books.google.com/books/content?id=test',
  }) {
    return BookSearchResult(
      volumeId: volumeId ?? 'book-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authors: [author],
      isbn: isbn ?? '9780123456789',
      thumbnail: thumbnail,
    );
  }

  // BUSINESS LOGIC:
  // Create multiple search results for batch testing
  // TECHNICAL: Returns list of N different books
  static List<BookSearchResult> createTestResults(int count) {
    return List.generate(
      count,
      (i) => createTestResult(
        volumeId: 'result-$i',
        title: 'Search Result $i',
        author: 'Author $i',
        isbn: '978000000000$i',
      ),
    );
  }

  // BUSINESS LOGIC:
  // Create result with very long title (edge case)
  // TECHNICAL: Returns result with 300+ character title
  static BookSearchResult createResultWithLongTitle() {
    final longTitle = 'A' * 300 + ' Very Long Book Title';
    return createTestResult(title: longTitle);
  }

  // BUSINESS LOGIC:
  // Create result with very long author name (edge case)
  // TECHNICAL: Returns result with 300+ character author
  static BookSearchResult createResultWithLongAuthor() {
    final longAuthor = 'A' * 300 + ' Author Name';
    return createTestResult(author: longAuthor);
  }

  // BUSINESS LOGIC:
  // Create result with special characters (Unicode handling)
  // TECHNICAL: Returns result with international characters
  static BookSearchResult createResultWithSpecialCharacters() {
    return createTestResult(
      title: 'Test™ 中文 العربية 🎉',
      author: 'José María García Márquez',
    );
  }

  // BUSINESS LOGIC:
  // Create result with missing ISBN (incomplete API data)
  // TECHNICAL: Returns result with null isbn
  static BookSearchResult createResultWithoutISBN() {
    return BookSearchResult(
      volumeId: 'no-isbn-book',
      title: 'Book Without ISBN',
      authors: ['Test Author'],
      isbn: null,
      thumbnail: 'https://books.google.com/books/content?id=no-isbn',
    );
  }

  // BUSINESS LOGIC:
  // Create result with missing thumbnail (no cover art)
  // TECHNICAL: Returns result with empty/placeholder image URL
  static BookSearchResult createResultWithoutImage() {
    return createTestResult(imageUrl: '');
  }
}
