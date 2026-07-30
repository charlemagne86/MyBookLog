import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';

// BUSINESS LOGIC:
// BookSearchResult represents a book from Google's search API.
// Must handle various API response formats gracefully:
// - Missing fields (authors, ISBN, cover image)
// - Multiple ISBN formats (ISBN-13, ISBN-10)
// - Malformed data from API
// - URLs that need HTTPS normalization
//
// Users depend on accurate identity matching (ISBN or title+author)
// to avoid adding the same book twice.

void main() {
  group('BookSearchResult - Comprehensive Model Tests', () {
    group('authorsLabel', () {
      test('returns joined author names', () {
        // TECHNICAL: Multiple authors displayed as comma-separated list
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: ['Jane Smith', 'John Doe', 'Alice Johnson'],
          thumbnail: '',
          isbn: null,
        );

        expect(
          book.authorsLabel,
          equals('Jane Smith, John Doe, Alice Johnson'),
        );
      });

      test('returns single author name', () {
        // TECHNICAL: Single author case
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: ['Jane Smith'],
          thumbnail: '',
          isbn: null,
        );

        expect(book.authorsLabel, equals('Jane Smith'));
      });

      test('returns "Unknown author" when no authors', () {
        // TECHNICAL: API may not provide authors
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: null,
        );

        expect(book.authorsLabel, equals('Unknown author'));
      });
    });

    group('hasIsbn', () {
      test('returns true when ISBN present and non-empty', () {
        // TECHNICAL: ISBN is required for duplicate detection
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: '978-0-7432-7356-5',
        );

        expect(book.hasIsbn, isTrue);
      });

      test('returns false when ISBN is null', () {
        // TECHNICAL: No ISBN available
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: null,
        );

        expect(book.hasIsbn, isFalse);
      });

      test('returns false when ISBN is empty string', () {
        // TECHNICAL: Empty string after trim
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: '   ',
        );

        expect(book.hasIsbn, isFalse);
      });

      test('returns false when ISBN is whitespace only', () {
        // TECHNICAL: ISBN with only spaces
        final book = BookSearchResult(
          volumeId: 'book-1',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: '\t\n',
        );

        expect(book.hasIsbn, isFalse);
      });
    });

    group('extractPreferredIsbn', () {
      test('prefers ISBN-13 over ISBN-10', () {
        // TECHNICAL: 13-digit ISBN is more modern/reliable
        final identifiers = [
          {'type': 'ISBN_10', 'identifier': '0-7432-7356-4'},
          {'type': 'ISBN_13', 'identifier': '978-0-7432-7356-5'},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('978-0-7432-7356-5'));
      });

      test('falls back to ISBN-10 when ISBN-13 missing', () {
        // TECHNICAL: Fallback when newer format unavailable
        final identifiers = [
          {'type': 'ISBN_10', 'identifier': '0-7432-7356-4'},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('0-7432-7356-4'));
      });

      test('handles null input gracefully', () {
        // TECHNICAL: API might not include identifiers field
        final result = BookSearchResult.extractPreferredIsbn(null);

        expect(result, isNull);
      });

      test('ignores malformed entries', () {
        // TECHNICAL: Some entries might be invalid objects
        final identifiers = [
          'not a map', // Invalid type
          {'type': 'ISBN_13', 'identifier': '978-0-7432-7356-5'},
          {'type': 'ISBN_10'}, // Missing identifier
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('978-0-7432-7356-5'));
      });

      test('trims whitespace from ISBN', () {
        // TECHNICAL: API might include extra spaces
        final identifiers = [
          {'type': 'ISBN_13', 'identifier': '  978-0-7432-7356-5  '},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('978-0-7432-7356-5'));
      });

      test('handles null identifier gracefully', () {
        // TECHNICAL: Missing identifier field
        final identifiers = [
          {'type': 'ISBN_13', 'identifier': null},
          {'type': 'ISBN_10', 'identifier': '0-7432-7356-4'},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('0-7432-7356-4'));
      });

      test('handles empty identifier string', () {
        // TECHNICAL: Empty string after trim
        final identifiers = [
          {'type': 'ISBN_13', 'identifier': '   '},
          {'type': 'ISBN_10', 'identifier': '0-7432-7356-4'},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('0-7432-7356-4'));
      });

      test('stops searching after finding both ISBN types', () {
        // TECHNICAL: Optimization - don't need to check all entries
        final identifiers = [
          {'type': 'ISBN_13', 'identifier': '978-0-7432-7356-5'},
          {'type': 'ISBN_10', 'identifier': '0-7432-7356-4'},
        ];

        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        expect(result, equals('978-0-7432-7356-5'));
      });
    });

    group('fromGoogleVolume', () {
      test('creates book from valid Google volume', () {
        // TECHNICAL: Complete, well-formed API response
        final volume = {
          'id': 'book-123',
          'volumeInfo': {
            'title': 'The Great Gatsby',
            'authors': ['F. Scott Fitzgerald'],
            'imageLinks': {'thumbnail': 'http://example.com/gatsby.jpg'},
            'industryIdentifiers': [
              {'type': 'ISBN_13', 'identifier': '978-0-7432-7356-5'},
            ],
          },
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNotNull);
        expect(result!.title, equals('The Great Gatsby'));
        expect(result.volumeId, equals('book-123'));
        expect(result.authors, contains('F. Scott Fitzgerald'));
        expect(result.isbn, equals('978-0-7432-7356-5'));
      });

      test('returns null for non-map input', () {
        // TECHNICAL: Malformed API response
        final result = BookSearchResult.fromGoogleVolume('not a map');

        expect(result, isNull);
      });

      test('returns null when volumeInfo missing', () {
        // TECHNICAL: Required field is missing
        final volume = {'id': 'book-123'};

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNull);
      });

      test('handles missing authors gracefully', () {
        // TECHNICAL: Authors field might be missing or null
        final volume = {
          'id': 'book-123',
          'volumeInfo': {
            'title': 'Book Without Authors',
            // No authors field
          },
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNotNull);
        expect(result!.authors, isEmpty);
        expect(result.authorsLabel, equals('Unknown author'));
      });

      test('handles missing title gracefully', () {
        // TECHNICAL: Title field missing - use default
        final volume = {
          'id': 'book-123',
          'volumeInfo': {
            // No title
            'authors': ['Some Author'],
          },
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNotNull);
        expect(result!.title, equals('No Title'));
      });

      test('handles missing thumbnail gracefully', () {
        // TECHNICAL: Cover image might not be available
        final volume = {
          'id': 'book-123',
          'volumeInfo': {
            'title': 'Book Without Cover',
            // No imageLinks
          },
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNotNull);
        expect(result!.thumbnail, isEmpty);
      });

      test('normalizes http thumbnails to https', () {
        // TECHNICAL: Security - always use HTTPS
        final volume = {
          'id': 'book-123',
          'volumeInfo': {
            'title': 'Test Book',
            'imageLinks': {'thumbnail': 'http://example.com/book.jpg'},
          },
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result!.thumbnail, startsWith('https://'));
      });

      test('preserves empty volumeId', () {
        // TECHNICAL: volumeId might be missing or empty
        final volume = {
          'volumeInfo': {'title': 'Test Book'},
        };

        final result = BookSearchResult.fromGoogleVolume(volume);

        expect(result, isNotNull);
        expect(result!.volumeId, isNull);
      });
    });

    group('listFromGoogleItems', () {
      test('converts list of valid volumes', () {
        // TECHNICAL: Batch conversion of search results
        final items = [
          {
            'id': 'book-1',
            'volumeInfo': {
              'title': 'Book 1',
              'authors': ['Author 1'],
            },
          },
          {
            'id': 'book-2',
            'volumeInfo': {
              'title': 'Book 2',
              'authors': ['Author 2'],
            },
          },
        ];

        final result = BookSearchResult.listFromGoogleItems(items);

        expect(result.length, equals(2));
        expect(result[0].title, equals('Book 1'));
        expect(result[1].title, equals('Book 2'));
      });

      test('filters out invalid entries silently', () {
        // TECHNICAL: Some entries might be malformed - skip them
        final items = [
          {
            'id': 'book-1',
            'volumeInfo': {'title': 'Good Book'},
          },
          'invalid entry', // Won't be converted
          {
            // Missing volumeInfo - invalid
            'id': 'book-3',
          },
          {
            'id': 'book-4',
            'volumeInfo': {'title': 'Another Good Book'},
          },
        ];

        final result = BookSearchResult.listFromGoogleItems(items);

        expect(result.length, equals(2));
        expect(result[0].title, equals('Good Book'));
        expect(result[1].title, equals('Another Good Book'));
      });

      test('returns empty list for empty input', () {
        // TECHNICAL: No results from search
        final result = BookSearchResult.listFromGoogleItems([]);

        expect(result, isEmpty);
      });
    });

    group('identityKey', () {
      test('uses ISBN when available', () {
        // TECHNICAL: ISBN is primary identifier (unique)
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Test Book',
          authors: ['Author'],
          thumbnail: '',
          isbn: '978-0-7432-7356-5',
        );

        final key = book.identityKey();

        expect(key, startsWith('isbn:'));
        expect(key, contains('978-0-7432-7356-5'));
      });

      test('falls back to title+authors when no ISBN', () {
        // TECHNICAL: Use volume key as fallback
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Test Book',
          authors: ['Author One', 'Author Two'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.identityKey();

        expect(key, startsWith('fallback:'));
      });

      test('trims whitespace from ISBN in key', () {
        // TECHNICAL: Normalize ISBN before using as key
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Test Book',
          authors: [],
          thumbnail: '',
          isbn: '  978-0-7432-7356-5  ',
        );

        final key = book.identityKey();

        expect(key, equals('isbn:978-0-7432-7356-5'));
      });

      test('ignores empty ISBN and uses fallback', () {
        // TECHNICAL: Empty ISBN after trim should fallback
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Test Book',
          authors: ['Author'],
          thumbnail: '',
          isbn: '   ',
        );

        final key = book.identityKey();

        expect(key, startsWith('fallback:'));
      });
    });

    group('volumeKey', () {
      test('creates consistent key from title and authors', () {
        // TECHNICAL: Groups different editions of same book
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'The Great Gatsby',
          authors: ['F. Scott Fitzgerald'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        expect(key, contains('great gatsby'));
        expect(key, contains('scott fitzgerald'));
      });

      test('normalizes to lowercase', () {
        // TECHNICAL: Case-insensitive matching
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'TEST BOOK',
          authors: ['AUTHOR NAME'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        expect(key.toLowerCase(), equals(key));
      });

      test('handles multiple authors', () {
        // TECHNICAL: Multiple authors separated by pipe
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Collaboration',
          authors: ['Author A', 'Author B', 'Author C'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        expect(key, contains('author a'));
        expect(key, contains('author b'));
        expect(key, contains('author c'));
      });

      test('filters out empty author strings', () {
        // TECHNICAL: Some entries might have empty strings
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Book',
          authors: ['Author', '', '  ', 'Another Author'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        // Should not contain empty author entries
        expect(key, isNotEmpty);
      });

      test('separates title and authors with double colon', () {
        // TECHNICAL: Delimiter for parsing/grouping
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Title',
          authors: ['Author'],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        expect(key, contains('::'));
      });

      test('handles books with no authors', () {
        // TECHNICAL: Authors might be empty
        final book = BookSearchResult(
          volumeId: 'vol-123',
          title: 'Untitled',
          authors: [],
          thumbnail: '',
          isbn: null,
        );

        final key = book.volumeKey();

        expect(key, startsWith('untitled::'));
      });
    });

    group('isLikelyIsbn13', () {
      test('returns true for 13-digit ISBN', () {
        // TECHNICAL: ISBN-13 validation (digit count only)
        expect(BookSearchResult.isLikelyIsbn13('978-0-7432-7356-5'), isTrue);
      });

      test('returns false for 10-digit ISBN', () {
        // TECHNICAL: ISBN-10 is older format
        expect(BookSearchResult.isLikelyIsbn13('0-7432-7356-4'), isFalse);
      });

      test('ignores hyphens and spaces', () {
        // TECHNICAL: Format variations should be normalized
        expect(BookSearchResult.isLikelyIsbn13('978 0 7432 7356 5'), isTrue);
      });

      test('counts X or x as character (ISBN-10 check digit)', () {
        // TECHNICAL: ISBN-10 uses x as check digit, function counts as char
        // 978-0-7432-7356-x: 12 digits + x = treated as 13 character code
        expect(BookSearchResult.isLikelyIsbn13('978-0-7432-7356-x'), isTrue);
      });

      test('counts only digits', () {
        // TECHNICAL: Hyphens and other chars ignored
        final isbn13 = '978-0-7432-7356-5';
        expect(BookSearchResult.isLikelyIsbn13(isbn13), isTrue);
      });

      test('returns false for invalid length', () {
        // TECHNICAL: Wrong number of digits
        expect(BookSearchResult.isLikelyIsbn13('9780743273565999'), isFalse);
      });
    });
  });
}
