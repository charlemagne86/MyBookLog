/// Unit tests for [ShelfBook] model.
///
/// Tests serialization, deserialization, equality, and business logic
/// for shelf books without any framework or network dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';

import '../../fixtures/test_data.dart';

void main() {
  group('ShelfBook', () {
    group('fromJoinedRow', () {
      test('parses valid database row correctly', () {
        // Arrange
        final row = {
          'book_id': 'book123',
          'is_read': true,
          'marked_read_on': '2026-01-15T10:30:00Z',
          'books_catalog': {
            'id': 'catalog123',
            'title': 'Dune',
            'author': 'Frank Herbert',
            'thumbnail_uri': 'http://example.com/dune.jpg',
          },
        };

        // Act
        final result = ShelfBook.fromJoinedRow(row);

        // Assert
        expect(result.bookId, 'book123');
        expect(result.title, 'Dune');
        expect(result.author, 'Frank Herbert');
        expect(result.isRead, isTrue);
        expect(result.thumbnailUri, startsWith('https://'));
      });

      test('handles missing catalog gracefully', () {
        // Arrange
        final row = {
          'book_id': 'book456',
          'is_read': false,
        };

        // Act
        final result = ShelfBook.fromJoinedRow(row);

        // Assert
        expect(result.bookId, 'book456');
        expect(result.title, isEmpty);
        expect(result.author, isNull);
        expect(result.isRead, isFalse);
      });

      test('handles null catalog entry', () {
        // Arrange
        final row = {
          'book_id': 'book789',
          'is_read': false,
          'books_catalog': null,
        };

        // Act & Assert
        expect(
          () => ShelfBook.fromJoinedRow(row),
          throwsException,
        );
      });

      test('converts http thumbnail to https', () {
        // Arrange
        final row = {
          'book_id': 'book999',
          'books_catalog': {
            'title': 'Test',
            'thumbnail_uri': 'http://example.com/cover.jpg',
          },
        };

        // Act
        final result = ShelfBook.fromJoinedRow(row);

        // Assert
        expect(result.thumbnailUri, startsWith('https://'));
        expect(result.thumbnailUri, contains('example.com/cover.jpg'));
      });

      test('handles empty thumbnail URL', () {
        // Arrange
        final row = {
          'book_id': 'book000',
          'books_catalog': {
            'title': 'Test',
            'thumbnail_uri': '',
          },
        };

        // Act
        final result = ShelfBook.fromJoinedRow(row);

        // Assert
        expect(result.thumbnailUri, isEmpty);
      });
    });

    group('matchesQuery', () {
      final book = TestData.sampleShelfBook(
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
      );

      test('matches title (case-insensitive)', () {
        expect(book.matchesQuery('gatsby'), isTrue);
        expect(book.matchesQuery('GREAT'), isTrue);
        expect(book.matchesQuery('The Great Gatsby'), isTrue);
      });

      test('matches author', () {
        expect(book.matchesQuery('fitzgerald'), isTrue);
        expect(book.matchesQuery('F. SCOTT'), isTrue);
      });

      test('requires partial substring match', () {
        expect(book.matchesQuery('gats'), isTrue);
        expect(book.matchesQuery('gerald'), isFalse);
      });

      test('returns false for non-matching query', () {
        expect(book.matchesQuery('harry potter'), isFalse);
        expect(book.matchesQuery('tolkien'), isFalse);
      });

      test('handles empty query', () {
        // Empty query should match (shows all books)
        expect(book.matchesQuery(''), isTrue);
      });

      test('ignores leading/trailing spaces', () {
        expect(book.matchesQuery('  gatsby  '), isTrue);
      });
    });

    group('parseReadValue', () {
      test('parses true as isRead', () {
        expect(ShelfBook.parseReadValue(true), isTrue);
        expect(ShelfBook.parseReadValue(1), isTrue);
        expect(ShelfBook.parseReadValue('true'), isTrue);
        expect(ShelfBook.parseReadValue('1'), isTrue);
      });

      test('parses false as unread', () {
        expect(ShelfBook.parseReadValue(false), isFalse);
        expect(ShelfBook.parseReadValue(0), isFalse);
        expect(ShelfBook.parseReadValue('false'), isFalse);
        expect(ShelfBook.parseReadValue('0'), isFalse);
      });

      test('parses null as unread', () {
        expect(ShelfBook.parseReadValue(null), isFalse);
      });

      test('parses unexpected types defensively', () {
        // Should not crash, should default to false
        expect(ShelfBook.parseReadValue({}), isFalse);
        expect(ShelfBook.parseReadValue([]), isFalse);
        expect(ShelfBook.parseReadValue('unexpected'), isFalse);
      });
    });

    group('equality & hashing', () {
      test('two books with same fields are equal', () {
        final book1 = TestData.sampleShelfBook(title: 'Dune');
        final book2 = TestData.sampleShelfBook(title: 'Dune');

        expect(book1, book2);
        expect(book1.hashCode, book2.hashCode);
      });

      test('books with different IDs are not equal', () {
        final book1 = TestData.sampleShelfBook(bookId: 'b1', title: 'Dune');
        final book2 = TestData.sampleShelfBook(bookId: 'b2', title: 'Dune');

        expect(book1, isNot(book2));
      });

      test('books with different read status are not equal', () {
        final book1 = TestData.sampleShelfBook(isRead: true);
        final book2 = TestData.sampleShelfBook(isRead: false);

        expect(book1, isNot(book2));
      });
    });

    group('copyWith', () {
      final original = TestData.sampleShelfBook(
        bookId: 'b1',
        title: 'Original',
        isRead: false,
      );

      test('creates copy with single field changed', () {
        final copy = original.copyWith(title: 'Modified');

        expect(copy.bookId, original.bookId);
        expect(copy.title, 'Modified');
        expect(copy.author, original.author);
        expect(copy.isRead, original.isRead);
      });

      test('creates copy with multiple fields changed', () {
        final copy = original.copyWith(
          title: 'New Title',
          isRead: true,
        );

        expect(copy.bookId, original.bookId);
        expect(copy.title, 'New Title');
        expect(copy.isRead, isTrue);
        expect(copy.author, original.author);
      });

      test('original is unmodified after copyWith', () {
        final copy = original.copyWith(title: 'Changed');

        expect(original.title, 'Original');
        expect(copy.title, 'Changed');
      });

      test('copyWith preserves null values when not overridden', () {
        final bookWithoutAuthor = TestData.sampleShelfBook(
          title: 'Untitled',
          author: null,
        );
        final copy = bookWithoutAuthor.copyWith(title: 'Now Titled');

        expect(copy.author, isNull);
      });
    });
  });
}
