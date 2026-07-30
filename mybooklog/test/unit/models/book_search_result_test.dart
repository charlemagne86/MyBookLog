/// Unit tests for [BookSearchResult] model.
///
/// Tests parsing Google Books API responses, ISBN extraction,
/// and URL normalization without external dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';

import '../../fixtures/test_data.dart';

void main() {
  group('BookSearchResult', () {
    group('fromGoogleVolume', () {
      test('parses complete volume entry correctly', () {
        // Arrange
        final volume = {
          'id': 'vol123',
          'volumeInfo': {
            'title': 'Dune',
            'authors': ['Frank Herbert'],
            'description': 'An epic tale of politics and technology',
            'imageLinks': {
              'thumbnail': 'http://books.google.com/books/content?id=dune.jpg',
            },
            'industryIdentifiers': [
              {'type': 'ISBN_13', 'identifier': '9780441013593'},
              {'type': 'ISBN_10', 'identifier': '0441013597'},
            ],
          },
        };

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNotNull);
        expect(result!.title, 'Dune');
        expect(result.authors, ['Frank Herbert']);
        expect(result.isbn, '9780441013593'); // Prefers ISBN-13
        expect(result.thumbnail, startsWith('https://'));
      });

      test('returns null for entry without volumeInfo', () {
        // Arrange
        final volume = {'id': 'vol456'};

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNull);
      });

      test('handles multiple authors', () {
        // Arrange
        final volume = {
          'volumeInfo': {
            'title': 'Foundation',
            'authors': ['Isaac Asimov', 'Others'],
          },
        };

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNotNull);
        expect(result!.authors, ['Isaac Asimov', 'Others']);
      });

      test('handles missing author gracefully', () {
        // Arrange
        final volume = {
          'volumeInfo': {
            'title': 'Anonymous Book',
            // No authors
          },
        };

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNotNull);
        expect(result!.title, 'Anonymous Book');
        expect(result.authors, []);
      });

      test('handles missing thumbnail', () {
        // Arrange
        final volume = {
          'volumeInfo': {
            'title': 'No Cover Book',
            // No imageLinks
          },
        };

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNotNull);
        expect(result!.thumbnail, isEmpty); // Empty string, not null
      });

      test('converts http thumbnail to https', () {
        // Arrange
        final volume = {
          'volumeInfo': {
            'title': 'Book',
            'imageLinks': {'thumbnail': 'http://example.com/cover.jpg'},
          },
        };

        // Act
        final result = BookSearchResult.fromGoogleVolume(volume);

        // Assert
        expect(result, isNotNull);
        expect(result!.thumbnail, startsWith('https://'));
      });
    });

    group('extractPreferredIsbn', () {
      test('prefers ISBN-13 over ISBN-10', () {
        // Arrange
        final identifiers = [
          {'type': 'ISBN_10', 'identifier': '0306406152'},
          {'type': 'ISBN_13', 'identifier': '9780306406157'},
        ];

        // Act
        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        // Assert
        expect(result, '9780306406157');
      });

      test('falls back to ISBN-10 when ISBN-13 missing', () {
        // Arrange
        final identifiers = [
          {'type': 'ISBN_10', 'identifier': '0306406152'},
        ];

        // Act
        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        // Assert
        expect(result, '0306406152');
      });

      test('returns null when no ISBN found', () {
        // Arrange
        final identifiers = [
          {'type': 'OTHER_ID', 'identifier': '12345'},
        ];

        // Act
        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        // Assert
        expect(result, isNull);
      });

      test('returns null for null input', () {
        // Act
        final result = BookSearchResult.extractPreferredIsbn(null);

        // Assert
        expect(result, isNull);
      });

      test('returns null for empty list', () {
        // Act
        final result = BookSearchResult.extractPreferredIsbn([]);

        // Assert
        expect(result, isNull);
      });

      test('handles non-map entries gracefully', () {
        // Arrange
        final identifiers = [
          42, // Not a map
          'string', // Not a map
          {'type': 'ISBN_13', 'identifier': '9780306406157'},
        ];

        // Act
        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        // Assert
        expect(result, '9780306406157');
      });

      test('extracts from mixed identifier list', () {
        // Arrange
        final identifiers = [
          {'type': 'ISSN', 'identifier': '1234-5678'},
          {'type': 'ISBN_10', 'identifier': '0306406152'},
          {'type': 'ISBN_13', 'identifier': '9780306406157'},
          {'type': 'DOI', 'identifier': 'some-doi'},
        ];

        // Act
        final result = BookSearchResult.extractPreferredIsbn(identifiers);

        // Assert
        expect(result, '9780306406157');
      });
    });

    group('identity', () {
      test('two results with same data have same identityKey', () {
        // Arrange
        final result1 = TestData.sampleSearchResult(
          title: 'Dune',
          isbn: '9780441013593',
        );
        final result2 = TestData.sampleSearchResult(
          title: 'Dune',
          isbn: '9780441013593',
        );

        // Act & Assert
        expect(result1.identityKey(), result2.identityKey());
      });

      test('results with different ISBNs have different identityKey', () {
        // Arrange
        final result1 = TestData.sampleSearchResult(
          title: 'Dune',
          isbn: '9780441013593',
        );
        final result2 = TestData.sampleSearchResult(
          title: 'Dune',
          isbn: '1234567890',
        );

        // Act & Assert
        expect(result1.identityKey(), isNot(result2.identityKey()));
      });
    });
  });
}
