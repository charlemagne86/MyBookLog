// Unit + smoke tests that need no Supabase initialization or network access.
// These replace the broken default counter test (BUG-5) and cover the pure
// logic extracted from the old monolith during the Phase 3 refactor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybooklog/src/core/config/app_config.dart';
import 'package:mybooklog/src/core/theme/app_theme.dart';
import 'package:mybooklog/src/core/utils.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';
import 'package:mybooklog/src/features/auth/signup_screen.dart';

void main() {
  group('AppConfig', () {
    test('no Google Books API key is baked into source (SEC-2 regression)', () {
      expect(AppConfig.googleBooksApiKey, isEmpty);
      expect(AppConfig.hasGoogleBooksApiKey, isFalse);
    });

    test('Supabase config has sane defaults', () {
      expect(AppConfig.supabaseUrl, contains('supabase.co'));
      expect(AppConfig.supabasePublishableKey, isNotEmpty);
    });
  });

  group('toHttpsUrl', () {
    test('upgrades http to https and passes https/empty through', () {
      expect(toHttpsUrl('http://x.test/a.jpg'), 'https://x.test/a.jpg');
      expect(toHttpsUrl('https://x.test/a.jpg'), 'https://x.test/a.jpg');
      expect(toHttpsUrl(null), '');
      expect(toHttpsUrl(''), '');
    });
  });

  group('BookSearchResult.extractPreferredIsbn', () {
    test('prefers ISBN_13 over ISBN_10', () {
      final isbn = BookSearchResult.extractPreferredIsbn([
        {'type': 'ISBN_10', 'identifier': '0306406152'},
        {'type': 'ISBN_13', 'identifier': '9780306406157'},
      ]);
      expect(isbn, '9780306406157');
    });

    test('falls back to ISBN_10 and tolerates garbage', () {
      expect(
        BookSearchResult.extractPreferredIsbn([
          {'type': 'ISBN_10', 'identifier': '0306406152'},
        ]),
        '0306406152',
      );
      expect(BookSearchResult.extractPreferredIsbn(null), isNull);
      expect(BookSearchResult.extractPreferredIsbn([42, 'nope']), isNull);
    });
  });

  group('BookSearchResult.fromGoogleVolume', () {
    test('normalizes fields and skips entries without volumeInfo', () {
      final result = BookSearchResult.fromGoogleVolume({
        'id': 'vol1',
        'volumeInfo': {
          'title': 'Dune',
          'authors': ['Frank Herbert'],
          'imageLinks': {'thumbnail': 'http://books.test/dune.jpg'},
          'industryIdentifiers': [
            {'type': 'ISBN_13', 'identifier': '9780441013593'},
          ],
        },
      });
      expect(result, isNotNull);
      expect(result!.title, 'Dune');
      expect(result.thumbnail, startsWith('https://'));
      expect(result.isbn, '9780441013593');
      expect(BookSearchResult.fromGoogleVolume({'id': 'x'}), isNull);
    });
  });

  group('GoogleBooksService.buildQuery', () {
    test('builds intitle/inauthor clauses and empty when blank', () {
      expect(
        GoogleBooksService.buildQuery(title: 'Dune', author: 'Herbert'),
        'intitle:Dune+inauthor:Herbert',
      );
      expect(GoogleBooksService.buildQuery(title: '', author: ''), isEmpty);
    });
  });

  group('SignUpScreen.validatePassword', () {
    test('accepts a strong password, rejects weak ones', () {
      expect(SignUpScreen.validatePassword('Passw0rd!'), isNull);
      expect(SignUpScreen.validatePassword('Pass1!'), isNotNull); // < 8
      expect(
        SignUpScreen.validatePassword('password1'),
        isNotNull,
      ); // no special
      expect(SignUpScreen.validatePassword(''), isNotNull);
    });
  });

  group('ShelfBook.parseReadValue', () {
    test('coerces bool/int/string into a stable bool', () {
      expect(ShelfBook.parseReadValue(true), isTrue);
      expect(ShelfBook.parseReadValue(1), isTrue);
      expect(ShelfBook.parseReadValue('true'), isTrue);
      expect(ShelfBook.parseReadValue(false), isFalse);
      expect(ShelfBook.parseReadValue(null), isFalse);
    });
  });

  testWidgets('light theme renders a basic scaffold', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('My Book Log'))),
      ),
    );
    expect(find.text('My Book Log'), findsOneWidget);
  });
}
