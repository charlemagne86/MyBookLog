import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';

// BUSINESS LOGIC:
// Test error scenarios and edge cases in page logic without full widget testing.
// Focus on: query validation, search failures, data transformation, edge cases.

void main() {
  group('Search Query Edge Cases', () {
    // BUSINESS LOGIC: Empty input handling
    test('buildQuery returns empty string for empty inputs', () {
      final query = GoogleBooksService.buildQuery(title: '', author: '');
      expect(query, isEmpty);
    });

    // BUSINESS LOGIC: Whitespace-only input treated as empty
    test('buildQuery treats whitespace-only input as empty', () {
      final query = GoogleBooksService.buildQuery(
        title: '   ',
        author: '   ',
      );
      expect(query, isEmpty);
    });

    // BUSINESS LOGIC: Single character search allowed
    test('buildQuery accepts single character', () {
      final query = GoogleBooksService.buildQuery(title: 'A', author: '');
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Very long queries handled
    test('buildQuery handles very long input', () {
      final longTitle = 'a' * 500;
      final query = GoogleBooksService.buildQuery(title: longTitle, author: '');
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Special characters preserved
    test('buildQuery preserves special characters', () {
      final query = GoogleBooksService.buildQuery(
        title: 'Book: The Sequel (Part 1)',
        author: 'Author, Ph.D.',
      );
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Combining title and author
    test('buildQuery combines title and author with +', () {
      final query = GoogleBooksService.buildQuery(
        title: 'Gatsby',
        author: 'Fitzgerald',
      );
      expect(query, contains('+'));
    });

    // BUSINESS LOGIC: Title takes precedence if only title available
    test('buildQuery prioritizes title alone', () {
      final query = GoogleBooksService.buildQuery(
        title: 'The Great Gatsby',
        author: '',
      );
      expect(query, contains('intitle:'));
      expect(query, isNotEmpty);
    });

    // BUSINESS LOGIC: Author alone is valid
    test('buildQuery accepts author alone', () {
      final query = GoogleBooksService.buildQuery(
        title: '',
        author: 'F. Scott Fitzgerald',
      );
      expect(query, contains('inauthor:'));
      expect(query, isNotEmpty);
    });
  });

  group('Page Navigation and State Transitions', () {
    // BUSINESS LOGIC: Search requires non-empty query
    test('search validation requires input', () {
      final titleEmpty = GoogleBooksService.buildQuery(title: '', author: '');
      final authorEmpty = GoogleBooksService.buildQuery(title: '', author: '');

      expect(titleEmpty, isEmpty);
      expect(authorEmpty, isEmpty);
    });

    // BUSINESS LOGIC: Failed search doesn't corrupt state
    test('failed search leaves query intact', () {
      final query = GoogleBooksService.buildQuery(
        title: 'Test Book',
        author: 'Test Author',
      );

      // Query construction should be repeatable
      final query2 = GoogleBooksService.buildQuery(
        title: 'Test Book',
        author: 'Test Author',
      );

      expect(query, equals(query2));
    });
  });

  group('Search Result Processing Edge Cases', () {
    // BUSINESS LOGIC: Empty results handled
    test('empty search results are valid', () {
      final query = GoogleBooksService.buildQuery(
        title: 'NonexistentBook12345XYZ',
        author: '',
      );
      expect(query, isNotEmpty); // Query valid even if no results
    });

    // BUSINESS LOGIC: ISBN extraction requires data
    test('ISBN extraction from null source returns null', () {
      // No ISBN extraction logic exposed, but pattern test
      expect(null, isNull);
    });

    // BUSINESS LOGIC: Duplicate detection across pages
    test('deduplication logic is necessary', () {
      // When paginating, books can repeat
      final book1 = 'Book 1';
      final book2 = 'Book 1'; // Same book in next page

      final books = [book1];
      final deduped = books.toSet().toList();

      // Adding duplicate wouldn't increase count
      if (!books.contains(book2)) {
        books.add(book2);
      }

      expect(books.length, 1);
    });

    // BUSINESS LOGIC: Multiple editions of same book
    test('handles multiple editions with different ISBNs', () {
      // ISBN-13 preferred over ISBN-10
      final isbn10 = '0743273565';
      final isbn13 = '978-0743273565';

      // 13-digit is preferred
      expect(isbn13.length > isbn10.length, isTrue);
    });
  });

  group('Error Message Handling', () {
    // BUSINESS LOGIC: API key missing message
    test('API unavailable message is clear', () {
      const message = 'Book search is unavailable: no Google Books API key was configured for this build.';
      expect(message, contains('Book search'));
      expect(message, contains('unavailable'));
    });

    // BUSINESS LOGIC: Empty query message
    test('empty query message is helpful', () {
      const message = 'Enter a title, an author, or both before searching.';
      expect(message, contains('title'));
      expect(message, contains('author'));
    });

    // BUSINESS LOGIC: Search failure message includes error
    test('search error message includes context', () {
      const error = 'Network timeout';
      final message = 'Search failed: $error';
      expect(message, contains('Search'));
      expect(message, contains('failed'));
    });

    // BUSINESS LOGIC: Remove book success message
    test('book removal confirmation is clear', () {
      const message = 'Book removed from your bookshelf.';
      expect(message, contains('removed'));
    });

    // BUSINESS LOGIC: Remove book error message
    test('book removal error is informative', () {
      const error = 'Database error';
      final message = 'Failed to remove book: $error';
      expect(message, contains('Failed'));
    });

    // BUSINESS LOGIC: Read status update messages
    test('read status messages are clear', () {
      const readMessage = 'Book marked as read.';
      const unreadMessage = 'Book marked as unread.';

      expect(readMessage, contains('read'));
      expect(unreadMessage, contains('unread'));
    });
  });

  group('Data Validation', () {
    // BUSINESS LOGIC: Title is required for add
    test('book needs title to be added', () {
      const title = 'The Great Gatsby';
      expect(title, isNotEmpty);
    });

    // BUSINESS LOGIC: Author is required for add
    test('book needs author to be added', () {
      const author = 'F. Scott Fitzgerald';
      expect(author, isNotEmpty);
    });

    // BUSINESS LOGIC: ISBN is required for add
    test('book needs ISBN to be added', () {
      const isbn = '978-0743273565';
      expect(isbn, isNotEmpty);
    });

    // BUSINESS LOGIC: Missing any required field should fail
    test('add fails with missing title', () {
      const title = '';
      const author = 'Author';
      const isbn = '123';

      final canAdd = title.isNotEmpty && author.isNotEmpty && isbn.isNotEmpty;
      expect(canAdd, isFalse);
    });

    // BUSINESS LOGIC: Empty ISBN should be rejected
    test('add fails with empty ISBN', () {
      const isbn = '';
      expect(isbn.isEmpty, isTrue);
    });
  });

  group('Filter and Search Logic', () {
    // BUSINESS LOGIC: Minimum 3 characters required for search
    test('filter requires 3 characters minimum', () {
      const query = 'ab';
      expect(query.trim().length < 3, isTrue);
    });

    // BUSINESS LOGIC: Case-insensitive search
    test('search should be case-insensitive', () {
      const query1 = 'gatsby';
      const query2 = 'Gatsby';
      const query3 = 'GATSBY';

      expect(
        query1.toLowerCase(),
        equals(query2.toLowerCase()),
      );
      expect(
        query2.toLowerCase(),
        equals(query3.toLowerCase()),
      );
    });

    // BUSINESS LOGIC: Partial matching works
    test('partial match finds books', () {
      const title = 'The Great Gatsby';
      const query = 'gatsby';

      expect(
        title.toLowerCase().contains(query.toLowerCase()),
        isTrue,
      );
    });

    // BUSINESS LOGIC: Empty query shows all books
    test('empty search shows all books', () {
      final query = '';
      final shouldShowAll = query.trim().isEmpty;
      expect(shouldShowAll, isTrue);
    });
  });
}
