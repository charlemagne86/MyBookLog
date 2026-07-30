import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';

class MockGoogleBooksService extends Mock implements GoogleBooksService {}

class GoogleBooksServiceSetupHelpers {
  static void setupSuccessfulSearch(
    MockGoogleBooksService service, {
    required List<BookSearchResult> results,
  }) {
    when(
      () => service.search(any()),
    ).thenAnswer((_) async => GoogleBooksPage(results: results, totalItems: results.length));
  }

  static void setupEmptySearchResults(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenAnswer((_) async => const GoogleBooksPage(results: [], totalItems: 0));
  }

  static void setupSearchTimeout(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(Exception('Request timeout'));
  }

  static void setupSearchApiError(
    MockGoogleBooksService service, {
    required int statusCode,
    required String message,
  }) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('API Error $statusCode: $message'));
  }

  static void setupSearchMalformedData(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(Exception('Failed to parse search results'));
  }

  static void setupLargeSearchResults(
    MockGoogleBooksService service, {
    int count = 1000,
  }) {
    final results = List.generate(
      count,
      (i) => BookSearchResult(
        volumeId: 'book-$i',
        title: 'Large Dataset Book $i',
        authors: ['Author $i'],
        thumbnail: 'https://books.google.com/books/content?id=book$i',
        isbn: '978000000000${i % 10}',
      ),
    );
    when(
      () => service.search(any()),
    ).thenAnswer((_) async => GoogleBooksPage(results: results, totalItems: results.length));
  }

  static void setupSpecialCharacterResults(MockGoogleBooksService service) {
    final results = [
      BookSearchResult(
        volumeId: 'special-1',
        title: 'Test™ 中文 العربية',
        authors: ['Author™ 中文'],
        thumbnail: 'https://books.google.com/books/content?id=special1',
        isbn: '9780123456789',
      ),
      BookSearchResult(
        volumeId: 'special-2',
        title: 'Señor García Márquez',
        authors: ['José María de Pereda'],
        thumbnail: 'https://books.google.com/books/content?id=special2',
        isbn: '9780123456790',
      ),
    ];
    when(
      () => service.search(any()),
    ).thenAnswer((_) async => GoogleBooksPage(results: results, totalItems: results.length));
  }

  static void setupUnauthorizedError(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('401: Unauthorized - Invalid API key'));
  }

  static void setupForbiddenError(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('403: Forbidden - Rate limit exceeded'));
  }

  static void setupNotFoundError(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('404: Not Found - Endpoint no longer available'));
  }

  static void setupServerError(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('500: Internal Server Error'));
  }

  static void setupServiceUnavailableError(MockGoogleBooksService service) {
    when(
      () => service.search(any()),
    ).thenThrow(GoogleBooksException('503: Service Unavailable'));
  }
}

class TestBookSearchResultFactory {
  static BookSearchResult createTestResult({
    String? volumeId,
    String title = 'Test Book',
    List<String>? authors,
    String thumbnail = 'https://books.google.com/books/content?id=test',
    String? isbn,
  }) {
    return BookSearchResult(
      volumeId: volumeId ?? 'book-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      authors: authors ?? ['Test Author'],
      thumbnail: thumbnail,
      isbn: isbn ?? '9780123456789',
    );
  }

  static List<BookSearchResult> createTestResults(int count) {
    return List.generate(
      count,
      (i) => createTestResult(
        volumeId: 'result-$i',
        title: 'Search Result $i',
        authors: ['Author $i'],
        isbn: '978000000000${i % 10}',
      ),
    );
  }

  static BookSearchResult createResultWithLongTitle() {
    final longTitle = 'A' * 300;
    return createTestResult(title: longTitle);
  }

  static BookSearchResult createResultWithLongAuthor() {
    final longAuthor = 'A' * 300;
    return createTestResult(authors: [longAuthor]);
  }

  static BookSearchResult createResultWithSpecialCharacters() {
    return createTestResult(
      title: 'Test™ 中文 العربية 🎉',
      authors: ['José María García Márquez'],
    );
  }

  static BookSearchResult createResultWithoutISBN() {
    return BookSearchResult(
      volumeId: 'no-isbn-book',
      title: 'Book Without ISBN',
      authors: ['Test Author'],
      thumbnail: 'https://books.google.com/books/content?id=no-isbn',
      isbn: null,
    );
  }

  static BookSearchResult createResultWithoutImage() {
    return createTestResult(thumbnail: '');
  }
}
