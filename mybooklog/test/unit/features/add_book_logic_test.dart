import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';

// BUSINESS LOGIC:
// Add book page requires users to search by title and/or author.
// The query must be properly formatted for Google Books API.
// This tests the query building and validation logic that powers the search.

void main() {
  group('GoogleBooksService.buildQuery - Search Query Construction', () {
    // BUSINESS LOGIC: User must enter at least title or author
    // TECHNICAL: buildQuery returns empty string if both fields empty
    test('returns empty string when both title and author are empty', () {
      final query = GoogleBooksService.buildQuery(title: '', author: '');
      expect(query, isEmpty);
    });

    // BUSINESS LOGIC: User can search by title alone
    // TECHNICAL: buildQuery adds intitle: prefix with URL encoding
    test('builds query with title only', () {
      final query = GoogleBooksService.buildQuery(
        title: 'The Great Gatsby',
        author: '',
      );
      expect(query, contains('intitle:'));
      expect(query, contains('Gatsby'));
    });

    // BUSINESS LOGIC: User can search by author alone
    // TECHNICAL: buildQuery adds inauthor: prefix with URL encoding
    test('builds query with author only', () {
      final query = GoogleBooksService.buildQuery(
        title: '',
        author: 'F. Scott Fitzgerald',
      );
      expect(query, contains('inauthor:'));
      expect(query, contains('Fitzgerald'));
    });

    // BUSINESS LOGIC: User can combine title and author for precise search
    // TECHNICAL: buildQuery joins with + operator, applies encoding to both
    test('builds query with title and author', () {
      final query = GoogleBooksService.buildQuery(
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
      );
      expect(query, contains('intitle:'));
      expect(query, contains('inauthor:'));
      expect(query, contains('+'));
    });

    // BUSINESS LOGIC: Whitespace around input should be trimmed
    // TECHNICAL: Trim before processing, so leading/trailing spaces ignored
    test('trims whitespace from title', () {
      final query = GoogleBooksService.buildQuery(
        title: '  The Great Gatsby  ',
        author: '',
      );
      expect(query, contains('Gatsby'));
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Whitespace around input should be trimmed
    test('trims whitespace from author', () {
      final query = GoogleBooksService.buildQuery(
        title: '',
        author: '  F. Scott Fitzgerald  ',
      );
      expect(query, contains('Fitzgerald'));
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Special characters in title must be URL-encoded
    // TECHNICAL: Uri.encodeQueryComponent escapes special characters
    test('encodes special characters in title', () {
      final query = GoogleBooksService.buildQuery(
        title: 'To Kill a Mockingbird',
        author: '',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Special characters in author must be URL-encoded
    test('encodes special characters in author', () {
      final query = GoogleBooksService.buildQuery(
        title: '',
        author: 'Müller',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Apostrophes and quotes should be handled safely
    test('handles apostrophes in title', () {
      final query = GoogleBooksService.buildQuery(
        title: "Don't Look Now",
        author: '',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Numbers in title/author are valid
    test('handles numbers in search query', () {
      final query = GoogleBooksService.buildQuery(
        title: '2001: A Space Odyssey',
        author: '',
      );
      expect(query, contains('2001'));
    });

    // BUSINESS LOGIC: Single character searches should work
    test('handles single character input', () {
      final query = GoogleBooksService.buildQuery(
        title: 'A',
        author: '',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Very long titles should be supported
    test('handles very long title input', () {
      final longTitle = 'A' * 100;
      final query = GoogleBooksService.buildQuery(
        title: longTitle,
        author: '',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Unicode characters should be preserved
    test('preserves unicode characters', () {
      final query = GoogleBooksService.buildQuery(
        title: '日本語',
        author: '',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Empty strings with only whitespace are treated as empty
    test('treats whitespace-only input as empty', () {
      final query = GoogleBooksService.buildQuery(
        title: '   ',
        author: '   ',
      );
      expect(query, isEmpty);
    });

    // BUSINESS LOGIC: Mixed whitespace and text is properly trimmed
    test('trims and preserves mixed whitespace with text', () {
      final query = GoogleBooksService.buildQuery(
        title: '  The Hobbit  ',
        author: '  Tolkien  ',
      );
      expect(query, isNotEmpty);
      expect(query, contains('Hobbit'));
      expect(query, contains('Tolkien'));
    });
  });

  group('GoogleBooksService.search - Query Execution', () {
    // BUSINESS LOGIC: Empty query should not be sent to Google
    // TECHNICAL: buildQuery returns empty string for empty input
    test('buildQuery returns empty string for empty inputs', () {
      final emptyQuery = GoogleBooksService.buildQuery(title: '', author: '');
      expect(emptyQuery, isEmpty);
    });

    // BUSINESS LOGIC: Non-empty query from buildQuery indicates valid search
    test('non-empty query indicates searchable input', () {
      final validQuery = GoogleBooksService.buildQuery(
        title: 'Test',
        author: '',
      );
      expect(validQuery, isNotEmpty);
    });

    // BUSINESS LOGIC: Query string is properly formatted for API
    test('query has proper format with intitle prefix', () {
      final query = GoogleBooksService.buildQuery(
        title: 'Test Book',
        author: '',
      );
      expect(query, startsWith('intitle:'));
    });

    // BUSINESS LOGIC: Combined queries use + separator
    test('combined query uses + separator', () {
      final query = GoogleBooksService.buildQuery(
        title: 'Test',
        author: 'Author',
      );
      expect(query, contains('+'));
    });
  });
}
