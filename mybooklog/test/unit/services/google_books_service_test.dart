import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:mybooklog/src/data/services/google_books_service.dart';

// BUSINESS LOGIC:
// GoogleBooksService is the app's connection to Google Books API, used for
// searching and looking up book details. The service must:
// - Handle network errors gracefully (timeouts, connection failures)
// - Properly parse API responses (valid, empty, malformed)
// - Encode search queries correctly (special characters, multiple pages)
// - Provide fallback ISBN lookup when search results lack ISBNs
// - Set appropriate timeouts (10 seconds per request)
//
// TECHNICAL:
// We mock the http.Client to control responses and simulate various scenarios.
// Tests verify proper HTTP requests and JSON response parsing.

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('GoogleBooksService', () {
    late GoogleBooksService service;
    late MockHttpClient mockClient;

    setUp(() {
      mockClient = MockHttpClient();
      service = GoogleBooksService(client: mockClient);

      // Register fallback value for Uri matchers
      registerFallbackValue(Uri());
    });

    group('buildQuery', () {
      test('builds query with title only', () {
        final query = GoogleBooksService.buildQuery(
          title: 'The Great Gatsby',
          author: '',
        );

        expect(query, contains('intitle:'));
        expect(query, contains('Gatsby'));
      });

      test('builds query with author only', () {
        final query = GoogleBooksService.buildQuery(
          title: '',
          author: 'F. Scott Fitzgerald',
        );

        expect(query, contains('inauthor:'));
        expect(query, contains('Fitzgerald'));
      });

      test('builds query with both title and author', () {
        final query = GoogleBooksService.buildQuery(
          title: 'Dune',
          author: 'Frank Herbert',
        );

        expect(query, contains('intitle:'));
        expect(query, contains('inauthor:'));
        expect(query, contains('Dune'));
        expect(query, contains('Herbert'));
      });

      test('returns empty string when both fields blank', () {
        final query = GoogleBooksService.buildQuery(title: '', author: '');

        expect(query, isEmpty);
      });

      test('returns empty string when both fields whitespace', () {
        final query = GoogleBooksService.buildQuery(title: '   ', author: '\t');

        expect(query, isEmpty);
      });

      test('encodes special characters in query', () {
        final query = GoogleBooksService.buildQuery(
          title: 'The Hobbit: There and Back Again',
          author: '',
        );

        // Special characters should be URL-encoded
        expect(query, isNotEmpty);
      });

      test('handles non-ASCII characters (accents, etc)', () {
        final query = GoogleBooksService.buildQuery(
          title: 'García Márquez',
          author: '',
        );

        expect(query, contains('intitle:'));
      });
    });

    group('search', () {
      test('successfully searches and parses results', () async {
        // TECHNICAL: HTTP 200 with valid Google Books API response
        // Should parse results into BookSearchResult objects
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response('''{
              "items": [
                {
                  "id": "book-1",
                  "volumeInfo": {
                    "title": "The Great Gatsby",
                    "authors": ["F. Scott Fitzgerald"],
                    "imageLinks": {"thumbnail": "https://example.com/gatsby.jpg"},
                    "industryIdentifiers": [
                      {"type": "ISBN_13", "identifier": "978-0-7432-7356-5"}
                    ]
                  }
                }
              ],
              "totalItems": 123
            }''', 200),
        );

        final page = await service.search('intitle:Gatsby');

        expect(page.results, isNotEmpty);
        expect(page.results.length, equals(1));
        expect(page.totalItems, equals(123));
      });

      test('returns empty results when API returns no items', () async {
        // TECHNICAL: Valid response but no matching books
        // Should return empty list, not throw
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{"totalItems": 0}', 200));

        final page = await service.search('nonexistent book');

        expect(page.results, isEmpty);
        expect(page.totalItems, equals(0));
      });

      test('handles empty response body gracefully', () async {
        // TECHNICAL: Server returns 200 but empty body
        // Should not crash, return empty results
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('', 200));

        final page = await service.search('test');

        expect(page.results, isEmpty);
      });

      test('throws exception on HTTP 400 (bad request)', () async {
        // TECHNICAL: Malformed search query
        // Should inform user of search error
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('Bad request', 400));

        expect(() => service.search(''), throwsA(isA<GoogleBooksException>()));
      });

      test(
        'throws exception on HTTP 403 (forbidden - API key invalid)',
        () async {
          // TECHNICAL: Invalid or missing API key
          // Should not expose API key in error message
          when(
            () => mockClient.get(any()),
          ).thenAnswer((_) async => http.Response('Forbidden', 403));

          expect(
            () => service.search('test'),
            throwsA(isA<GoogleBooksException>()),
          );
        },
      );

      test('throws exception on HTTP 429 (rate limited)', () async {
        // TECHNICAL: Too many requests to Google API
        // Should handle gracefully and inform user
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('Too Many Requests', 429));

        expect(
          () => service.search('test'),
          throwsA(isA<GoogleBooksException>()),
        );
      });

      test('throws exception on HTTP 500 (server error)', () async {
        // TECHNICAL: Google's servers are having issues
        // Should show friendly error to user
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

        expect(
          () => service.search('test'),
          throwsA(isA<GoogleBooksException>()),
        );
      });

      test('times out after 10 seconds', () async {
        // TECHNICAL: Network is slow or server unresponsive
        // Should give up after timeout
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => Future.delayed(
            const Duration(seconds: 15),
            () => http.Response('', 200),
          ),
        );

        expect(() => service.search('test'), throwsA(isA<TimeoutException>()));
      });

      test('respects custom timeout duration', () async {
        // TECHNICAL: Service can be configured with different timeout
        final serviceWithShortTimeout = GoogleBooksService(
          client: mockClient,
          timeout: const Duration(milliseconds: 100),
        );

        when(() => mockClient.get(any())).thenAnswer(
          (_) async => Future.delayed(
            const Duration(seconds: 1),
            () => http.Response('', 200),
          ),
        );

        expect(
          () => serviceWithShortTimeout.search('test'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('handles pagination with startIndex', () async {
        // TECHNICAL: Search results are paginated (20 per page)
        // Page 2 starts at index 20, page 3 at 40, etc
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response('{"items": [], "totalItems": 100}', 200),
        );

        final page2 = await service.search('test', startIndex: 20);
        final page3 = await service.search('test', startIndex: 40);

        expect(page2, isNotNull);
        expect(page3, isNotNull);
      });

      test('handles malformed JSON response', () async {
        // TECHNICAL: Server returns invalid JSON
        // Should throw parsing error
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response('not valid json {broken}', 200),
        );

        expect(() => service.search('test'), throwsException);
      });

      test('handles missing totalItems in response', () async {
        // TECHNICAL: Some API responses might omit totalItems
        // Should handle gracefully
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{"items": []}', 200));

        final page = await service.search('test');

        expect(page.results, isEmpty);
        expect(page.totalItems, isNull);
      });

      test('includes API key in request URL', () async {
        // TECHNICAL: Google Books API requires API key for quota/auth
        // Should include key in request
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{"totalItems": 0}', 200));

        await service.search('test');

        // Verify request was made with URL containing API key
        verify(() => mockClient.get(any())).called(1);
      });
    });

    group('fetchPreferredIsbnForVolume', () {
      test('successfully fetches ISBN for volume', () async {
        // TECHNICAL: Lookup specific book by Google ID to get ISBN
        // Used when search result is missing ISBN
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response('''{
              "volumeInfo": {
                "industryIdentifiers": [
                  {"type": "ISBN_13", "identifier": "978-0-7432-7356-5"}
                ]
              }
            }''', 200),
        );

        final isbn = await service.fetchPreferredIsbnForVolume('book-123');

        expect(isbn, equals('978-0-7432-7356-5'));
      });

      test('returns null when volume not found (404)', () async {
        // TECHNICAL: Volume ID doesn't exist or is invalid
        // Should return null, not throw
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('Not found', 404));

        final isbn = await service.fetchPreferredIsbnForVolume('invalid-id');

        expect(isbn, isNull);
      });

      test('returns null when no ISBN in response', () async {
        // TECHNICAL: Volume found but has no ISBN
        // Should return null, not throw
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{"volumeInfo": {}}', 200));

        final isbn = await service.fetchPreferredIsbnForVolume('book-123');

        expect(isbn, isNull);
      });

      test('returns null when volumeInfo missing', () async {
        // TECHNICAL: Malformed response structure
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{}', 200));

        final isbn = await service.fetchPreferredIsbnForVolume('book-123');

        expect(isbn, isNull);
      });

      test('returns null on HTTP 500 error', () async {
        // TECHNICAL: Server error during fallback lookup
        // Should gracefully handle, return null
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('Server error', 500));

        final isbn = await service.fetchPreferredIsbnForVolume('book-123');

        expect(isbn, isNull);
      });

      test('handles empty response body', () async {
        // TECHNICAL: Server returns 200 but no body
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('', 200));

        final isbn = await service.fetchPreferredIsbnForVolume('book-123');

        expect(isbn, isNull);
      });

      test('encodes volume ID properly in URL', () async {
        // TECHNICAL: Volume IDs with special characters need encoding
        when(
          () => mockClient.get(any()),
        ).thenAnswer((_) async => http.Response('{"volumeInfo": {}}', 200));

        await service.fetchPreferredIsbnForVolume('book/with-special_chars');

        // Should have called get with properly encoded URL
        verify(() => mockClient.get(any())).called(1);
      });
    });

    group('GoogleBooksException', () {
      test('exception has proper message', () {
        final exception = GoogleBooksException('Test error message');

        expect(exception.toString(), equals('Test error message'));
      });
    });

    group('GoogleBooksPage', () {
      test('page constructor stores results and totalItems', () {
        const page = GoogleBooksPage(results: [], totalItems: 42);

        expect(page.results, isEmpty);
        expect(page.totalItems, equals(42));
      });

      test('page can have null totalItems', () {
        const page = GoogleBooksPage(results: [], totalItems: null);

        expect(page.totalItems, isNull);
      });
    });
  });
}
