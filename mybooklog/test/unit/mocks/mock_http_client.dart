import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

// BUSINESS LOGIC:
// Google Books Service makes HTTP requests to googleapis.com
// Our mock HTTP client simulates various response scenarios:
// - Successful searches with real book data
// - API errors (401, 403, 404, 500, 503)
// - Network timeouts
// - Malformed JSON responses
// - Empty result sets
//
// This enables comprehensive error handling testing without real network calls.

class MockHttpClient extends Mock implements http.Client {}

class MockHttpResponse {
  final int statusCode;
  final String body;

  MockHttpResponse({required this.statusCode, required this.body});
}

// Response factories for common scenarios
class HttpResponseFactories {
  static MockHttpResponse successResponse({required String query}) {
    return MockHttpResponse(
      statusCode: 200,
      body: '''
{
  "kind": "books#volumes",
  "totalItems": 2,
  "items": [
    {
      "kind": "books#volume",
      "id": "test-book-1",
      "volumeInfo": {
        "title": "Test Book One",
        "authors": ["Author One"],
        "industryIdentifiers": [
          {"type": "ISBN_13", "identifier": "9780123456789"}
        ],
        "imageLinks": {"thumbnail": "https://books.google.com/books/content?id=test1"}
      }
    },
    {
      "kind": "books#volume",
      "id": "test-book-2",
      "volumeInfo": {
        "title": "Test Book Two",
        "authors": ["Author Two"],
        "industryIdentifiers": [
          {"type": "ISBN_10", "identifier": "0123456789"}
        ],
        "imageLinks": {"thumbnail": "http://books.google.com/books/content?id=test2"}
      }
    }
  ]
}
''',
    );
  }

  static MockHttpResponse emptyResponse() {
    return MockHttpResponse(
      statusCode: 200,
      body: '{"kind": "books#volumes", "totalItems": 0, "items": []}',
    );
  }

  static MockHttpResponse malformedResponse() {
    return MockHttpResponse(statusCode: 200, body: '{invalid json}');
  }

  static MockHttpResponse missingFieldsResponse() {
    return MockHttpResponse(
      statusCode: 200,
      body: '''
{
  "kind": "books#volumes",
  "totalItems": 1,
  "items": [
    {
      "kind": "books#volume",
      "id": "incomplete-book"
    }
  ]
}
''',
    );
  }

  static MockHttpResponse errorResponse(int statusCode, String message) {
    return MockHttpResponse(
      statusCode: statusCode,
      body: '{"error": {"code": $statusCode, "message": "$message"}}',
    );
  }

  static MockHttpResponse largeDatasetResponse(int count) {
    final items = List.generate(
      count,
      (i) =>
          '''
{
  "kind": "books#volume",
  "id": "book-$i",
  "volumeInfo": {
    "title": "Book $i",
    "authors": ["Author $i"],
    "industryIdentifiers": [
      {"type": "ISBN_13", "identifier": "978000000000$i"}
    ],
    "imageLinks": {"thumbnail": "https://books.google.com/books/content?id=book$i"}
  }
}
''',
    ).join(',');

    return MockHttpResponse(
      statusCode: 200,
      body:
          '''
{
  "kind": "books#volumes",
  "totalItems": $count,
  "items": [$items]
}
''',
    );
  }

  static MockHttpResponse specialCharacterResponse() {
    return MockHttpResponse(
      statusCode: 200,
      body: '''
{
  "kind": "books#volumes",
  "totalItems": 1,
  "items": [
    {
      "kind": "books#volume",
      "id": "special-chars",
      "volumeInfo": {
        "title": "Test™ 中文 العربية 🎉",
        "authors": ["Author™"],
        "industryIdentifiers": [
          {"type": "ISBN_13", "identifier": "9780123456789"}
        ],
        "imageLinks": {"thumbnail": "https://books.google.com/books/content?id=special"}
      }
    }
  ]
}
''',
    );
  }
}

// Setup helper for tests
void setupMockHttpClientSuccessResponse(MockHttpClient client) {
  when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
    (_) async => http.Response(
      HttpResponseFactories.successResponse(query: '').body,
      HttpResponseFactories.successResponse(query: '').statusCode,
    ),
  );
}

void setupMockHttpClientErrorResponse(MockHttpClient client, int statusCode) {
  when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
    (_) async => http.Response(
      HttpResponseFactories.errorResponse(statusCode, 'API Error').body,
      statusCode,
    ),
  );
}
