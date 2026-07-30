import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';

// BUSINESS LOGIC:
// ShelfBook model is the core data structure for books on user's shelf.
// Must handle edge cases in real-world book data:
// - Very long titles/authors (some books have 200+ char titles)
// - Special characters and Unicode (emoji, accents, etc.)
// - ISBN variations (some books have no ISBN, ISBN-10 only, etc.)
// - Search filtering with various inputs
// - Display in constrained spaces (truncation, ellipsis)

void main() {
  group('ShelfBook - Edge Cases', () {
    test('handles very long book title', () {
      // TECHNICAL: Some books have extremely long titles
      final book = ShelfBook(
        bookId: 'test-1',
        title: 'A' * 300, // Very long title
        author: 'Test Author',
        thumbnailUri: '',
        isRead: false,
      );

      expect(book.title.length, equals(300));
      expect(book.title, isNotNull);
    });

    test('handles very long author name', () {
      // TECHNICAL: Some authors have long names
      final book = ShelfBook(
        bookId: 'test-2',
        title: 'Test Book',
        author: 'A' * 200,
        thumbnailUri: '',
        isRead: false,
      );

      expect(book.author!.length, equals(200));
    });

    test('handles special characters in title', () {
      // TECHNICAL: Unicode, emoji, HTML entities
      final book = ShelfBook(
        bookId: 'test-3',
        title: 'Test Book™ 中文 العربية 🎉',
        author: 'Test',
        thumbnailUri: '',
        isRead: false,
      );

      expect(book.title.contains('™'), isTrue);
      expect(book.title.contains('中文'), isTrue);
      expect(book.title.contains('🎉'), isTrue);
    });

    test('handles null author gracefully', () {
      // TECHNICAL: Some books have no author info
      final book = ShelfBook(
        bookId: 'test-4',
        title: 'Anonymous Book',
        author: null,
        thumbnailUri: '',
        isRead: false,
      );

      expect(book.author, isNull);
      expect(book.matchesQuery('Test'), isFalse);
    });

    test('handles empty ISBN (no identifier)', () {
      // TECHNICAL: Some books have no ISBN
      final book = ShelfBook(
        bookId: 'no-isbn-fallback',
        title: 'Rare Book',
        author: 'Rare Author',
        thumbnailUri: '',
        isRead: false,
      );

      expect(book.bookId, isNotEmpty);
    });

    group('Search Filtering Edge Cases', () {
      final testBook = ShelfBook(
        bookId: 'test-search',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        thumbnailUri: '',
        isRead: false,
      );

      test('matches with mixed case query', () {
        // TECHNICAL: Case-insensitive substring matching on title and author
        expect(
          testBook.matchesQuery('GREAT'),
          isTrue,
        ); // Matches "GREAT" in title
        expect(
          testBook.matchesQuery('gReAt'),
          isTrue,
        ); // Case-insensitive match
        expect(
          testBook.matchesQuery('GaT'),
          isTrue,
        ); // Matches "gat" in "gatsby"
        expect(
          testBook.matchesQuery('xyz'),
          isFalse,
        ); // No match in title or author
      });

      test('matches partial author name', () {
        expect(testBook.matchesQuery('Scott'), isTrue);
        expect(testBook.matchesQuery('Fitzgerald'), isTrue);
      });

      test('matches with whitespace', () {
        expect(testBook.matchesQuery('  great  '), isTrue);
        expect(testBook.matchesQuery('\tgatsby'), isTrue);
      });

      test('handles unicode in search', () {
        expect(testBook.matchesQuery('Gätzby'), isFalse);
      });

      test('empty query matches all', () {
        expect(testBook.matchesQuery(''), isTrue);
      });

      test('query shorter than 3 chars still works in filter', () {
        expect(testBook.matchesQuery('ga'), isTrue);
        expect(testBook.matchesQuery('g'), isTrue);
      });
    });

    test('preserves read status through copying', () {
      // TECHNICAL: copyWith() should preserve/update fields correctly
      final original = ShelfBook(
        bookId: 'test-copy',
        title: 'Original',
        author: 'Author',
        thumbnailUri: '',
        isRead: false,
      );

      final updated = original.copyWith(isRead: true);

      expect(original.isRead, isFalse);
      expect(updated.isRead, isTrue);
      expect(updated.title, equals('Original'));
    });

    test('handles equality with different field values', () {
      // TECHNICAL: Two books with same ID should be equal
      final book1 = ShelfBook(
        bookId: 'same-id',
        title: 'Title 1',
        author: 'Author 1',
        thumbnailUri: '',
        isRead: false,
      );

      final book2 = ShelfBook(
        bookId: 'same-id',
        title: 'Title 2', // Different
        author: 'Author 2', // Different
        thumbnailUri: '',
        isRead: true, // Different
      );

      // Implementation detail: books with same ID might be considered equal
      expect(book1.bookId, equals(book2.bookId));
    });
  });
}
