/// Reusable test data factories and fixtures.
///
/// This file provides factory methods to create test objects without
/// duplicating data setup across multiple test files.
library;

import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';

class TestData {
  // Private constructor to prevent instantiation
  TestData._();

  /// A complete, valid [ShelfBook] with reasonable defaults.
  ///
  /// BUSINESS LOGIC:
  /// Each book on the shelf has an ID, title, author, cover image, and
  /// read status. This factory creates a realistic test book without
  /// duplicating this setup in every test.
  ///
  /// TECHNICAL:
  /// The bookId should be unique per test to avoid collisions if multiple
  /// books are created. The thumbnailUri is normalized to HTTPS.
  static ShelfBook sampleShelfBook({
    String bookId = 'test-book-001',
    String title = 'The Overstory',
    String? author = 'Richard Powers',
    String? thumbnailUri = 'https://example.com/overstory.jpg',
    bool isRead = false,
  }) => ShelfBook(
    bookId: bookId,
    title: title,
    author: author,
    thumbnailUri: thumbnailUri ?? '',
    isRead: isRead,
  );

  /// A collection of shelf books at various read states.
  static List<ShelfBook> sampleShelfBooks({int count = 5}) => List.generate(
    count,
    (i) => sampleShelfBook(
      bookId: 'book-$i',
      title: 'Book Title $i',
      author: 'Author $i',
      isRead: i % 2 == 0,
    ),
  );

  /// A valid [BookSearchResult] from Google Books.
  ///
  /// BUSINESS LOGIC:
  /// Search results need a title, author(s), ISBN (for duplicate detection),
  /// and cover image. This factory creates realistic search results without
  /// duplicating data in every test.
  ///
  /// TECHNICAL:
  /// The volumeId is a Google Books internal ID. Authors is a list since
  /// books can have multiple authors. ISBN is required for "already have"
  /// detection. Thumbnail is normalized to HTTPS.
  static BookSearchResult sampleSearchResult({
    String? volumeId = 'volume-123',
    String title = 'Dune',
    List<String>? authors = const ['Frank Herbert'],
    String? isbn = '9780441013593',
    String? thumbnail = 'https://books.google.com/books/content?id=example',
  }) => BookSearchResult(
    volumeId: volumeId,
    title: title,
    authors: authors ?? [],
    isbn: isbn,
    thumbnail: thumbnail ?? '',
  );

  /// Multiple search results, useful for pagination testing.
  ///
  /// BUSINESS LOGIC:
  /// Tests for search pagination and filtering often need multiple results.
  /// This factory generates a list of realistic search results without duplication.
  ///
  /// TECHNICAL:
  /// Each result has a unique ISBN and title for differentiation.
  static List<BookSearchResult> sampleSearchResults({int count = 10}) =>
      List.generate(
        count,
        (i) => sampleSearchResult(
          title: 'Book $i',
          authors: ['Author $i'],
          isbn: '978000000${i.toString().padLeft(4, '0')}',
        ),
      );

  /// A ISBN-13 that is valid for testing.
  static const String validIsbn13 = '9780441013593'; // Dune

  /// A ISBN-10 that is valid for testing.
  static const String validIsbn10 = '0441013597'; // Dune

  /// An invalid ISBN (wrong checksum).
  static const String invalidIsbn = '9999999999999';

  /// A valid HTTP URL for thumbnail.
  static const String validThumbnailUrl = 'https://books.example.com/cover.jpg';

  /// An HTTP (non-HTTPS) URL for testing HTTPS conversion.
  static const String httpThumbnailUrl = 'http://books.example.com/cover.jpg';
}
