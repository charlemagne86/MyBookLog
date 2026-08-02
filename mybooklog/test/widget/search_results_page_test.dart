/// Widget tests for [SearchResultsPage].
///
/// BUSINESS LOGIC:
/// This screen is the moment a search turns into a shelf entry: the user
/// picks a book from the results and saves it. If selection, the add flow,
/// or pagination breaks, users either can't add books at all or add the
/// wrong one — the app's core promise ("have I read this?") depends on it.
///
/// TECHNICAL:
/// The page is pumped inside a small GoRouter + Provider harness:
/// - GoRouter supplies a '/shelf' route so the post-add navigation is real
/// - Provider injects mock GoogleBooksService (pagination/ISBN lookup) and
///   mock BookshelfRepository (the add call)
/// Book covers use empty thumbnails so no image downloads are attempted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';
import 'package:mybooklog/src/features/book_search/search_results_page.dart';
import 'package:mybooklog/src/features/book_search/widgets/add_to_shelf_button.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_results_empty_state.dart';
import 'package:provider/provider.dart';

import '../fixtures/mock_repositories.dart';
import '../unit/mocks/mock_services.dart';

/// Builds n distinct search results ("Book 0", "Book 1", ...).
/// Empty thumbnails keep widget tests offline (no cover downloads).
List<BookSearchResult> makeBooks(int count, {bool withIsbn = true}) {
  return List.generate(
    count,
    (i) => BookSearchResult(
      volumeId: 'vol-$i',
      title: 'Book $i',
      authors: ['Author $i'],
      isbn: withIsbn ? '978000000000$i' : null,
      thumbnail: '',
    ),
  );
}

void main() {
  late MockGoogleBooksService service;
  late MockBookshelfRepository repository;

  setUp(() {
    service = MockGoogleBooksService();
    repository = MockBookshelfRepository();
  });

  /// Pumps the page inside the router/provider harness described above.
  Future<void> pumpPage(
    WidgetTester tester, {
    required List<BookSearchResult> results,
    String query = 'gatsby',
    int? totalItems,
  }) async {
    final router = GoRouter(
      initialLocation: '/results',
      routes: [
        GoRoute(
          path: '/results',
          builder: (_, _) => SearchResultsPage(
            args: SearchResultsArgs(
              results: results,
              searchQuery: query,
              totalItems: totalItems,
            ),
          ),
        ),
        GoRoute(
          path: '/shelf',
          builder: (_, _) =>
              const Scaffold(body: Text('Bookshelf destination')),
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GoogleBooksService>.value(value: service),
          Provider<BookshelfRepository>.value(value: repository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('SearchResultsPage', () {
    group('rendering', () {
      testWidgets('shows the returned books', (tester) async {
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        expect(find.text('Book 0'), findsOneWidget);
        expect(find.text('Book 1'), findsOneWidget);
        expect(find.text('Book 2'), findsOneWidget);
      });

      testWidgets('shows the empty state when there are no results', (
        tester,
      ) async {
        await pumpPage(tester, results: const [], totalItems: 0);

        expect(find.byType(SearchEmptyState), findsOneWidget);
      });
    });

    group('selection', () {
      testWidgets('tapping a book reveals the add button', (tester) async {
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        // No selection yet -> no way to add (prevents accidental adds).
        expect(find.byType(AddToShelfButton), findsNothing);

        await tester.tap(find.text('Book 1'));
        await tester.pump();

        expect(find.byType(AddToShelfButton), findsOneWidget);
      });

      testWidgets('tapping the selected book again deselects it', (
        tester,
      ) async {
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        await tester.tap(find.text('Book 1'));
        await tester.pump();
        await tester.tap(find.text('Book 1'));
        await tester.pump();

        expect(find.byType(AddToShelfButton), findsNothing);
      });
    });

    group('adding a book', () {
      testWidgets('saves the selection and navigates to the shelf', (
        tester,
      ) async {
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenAnswer((_) async => false); // false = newly added
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        await tester.tap(find.text('Book 1'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pumpAndSettle();

        // The exact selected book was saved (empty thumbnail becomes null).
        verify(
          () => repository.addBook(
            isbn: '9780000000001',
            title: 'Book 1',
            author: 'Author 1',
            thumbnail: null,
          ),
        ).called(1);
        // Success lands the user on their shelf.
        expect(find.text('Bookshelf destination'), findsOneWidget);
      });

      testWidgets('warns about duplicates and stays on the results', (
        tester,
      ) async {
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenAnswer((_) async => true); // true = already on shelf
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pump();

        expect(
          find.text('This book already exists on your bookshelf.'),
          findsOneWidget,
        );
        // Duplicate is not an error: user stays here to pick another book.
        expect(find.text('Bookshelf destination'), findsNothing);
      });

      testWidgets('looks up an ISBN when the selection has none', (
        tester,
      ) async {
        // BUSINESS LOGIC: Google often returns editions without ISBNs.
        // The page must fall back to the volume lookup before giving up.
        when(
          () => service.fetchPreferredIsbnForVolume('vol-0'),
        ).thenAnswer((_) async => '9780743273565');
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenAnswer((_) async => false);
        await pumpPage(
          tester,
          results: makeBooks(1, withIsbn: false),
          totalItems: 1,
        );

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pumpAndSettle();

        verify(
          () => repository.addBook(
            isbn: '9780743273565',
            title: 'Book 0',
            author: 'Author 0',
            thumbnail: null,
          ),
        ).called(1);
      });

      testWidgets('explains when no ISBN can be found anywhere', (
        tester,
      ) async {
        when(
          () => service.fetchPreferredIsbnForVolume(any()),
        ).thenAnswer((_) async => null);
        await pumpPage(
          tester,
          results: makeBooks(1, withIsbn: false),
          totalItems: 1,
        );

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pump();

        expect(find.textContaining('missing ISBN'), findsOneWidget);
        verifyNever(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        );
      });

      testWidgets('surfaces save failures and lets the user retry', (
        tester,
      ) async {
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenThrow(Exception('network down'));
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pump();

        expect(find.textContaining('Failed to add book'), findsOneWidget);
        // The button is back in its idle state so the user can try again.
        expect(find.byType(AddToShelfButton), findsOneWidget);
      });
    });

    group('choosing a cover', () {
      testWidgets('saves the selected edition\'s own cover once it validates', (
        tester,
      ) async {
        when(
          () => service.isThumbnailValid('https://covers.example.com/good.jpg'),
        ).thenAnswer((_) async => true);
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenAnswer((_) async => false);
        final books = [
          BookSearchResult(
            volumeId: 'vol-0',
            title: 'Book 0',
            authors: const ['Author 0'],
            isbn: '9780000000000',
            thumbnail: 'https://covers.example.com/good.jpg',
          ),
        ];
        await pumpPage(tester, results: books, totalItems: 1);

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pumpAndSettle();

        verify(
          () => repository.addBook(
            isbn: '9780000000000',
            title: 'Book 0',
            author: 'Author 0',
            thumbnail: 'https://covers.example.com/good.jpg',
          ),
        ).called(1);
      });

      testWidgets(
        'borrows a sibling edition\'s cover when the selected one is invalid',
        (tester) async {
          // BUSINESS LOGIC: Two entries for the same title+author (e.g.
          // hardcover vs. paperback) — the tapped one's cover is broken,
          // but the other edition's is real. The real one should be used.
          when(
            () => service.isThumbnailValid(
              'https://covers.example.com/broken.jpg',
            ),
          ).thenAnswer((_) async => false);
          when(
            () =>
                service.isThumbnailValid('https://covers.example.com/good.jpg'),
          ).thenAnswer((_) async => true);
          when(
            () => repository.addBook(
              isbn: any(named: 'isbn'),
              title: any(named: 'title'),
              author: any(named: 'author'),
              thumbnail: any(named: 'thumbnail'),
            ),
          ).thenAnswer((_) async => false);
          final editions = [
            BookSearchResult(
              volumeId: 'vol-a',
              title: 'Dune',
              authors: const ['Frank Herbert'],
              isbn: '9781111111111',
              thumbnail: 'https://covers.example.com/broken.jpg',
            ),
            BookSearchResult(
              volumeId: 'vol-b',
              title: 'Dune',
              authors: const ['Frank Herbert'],
              isbn: '9782222222222',
              thumbnail: 'https://covers.example.com/good.jpg',
            ),
          ];
          await pumpPage(tester, results: editions, totalItems: 2);

          // Selects the FIRST (broken-cover) edition.
          await tester.tap(find.text('Dune').first);
          await tester.pump();
          await tester.tap(find.byType(AddToShelfButton));
          await tester.pumpAndSettle();

          verify(
            () => repository.addBook(
              isbn: '9781111111111', // the tapped edition's own ISBN
              title: 'Dune',
              author: 'Frank Herbert',
              thumbnail: 'https://covers.example.com/good.jpg', // borrowed
            ),
          ).called(1);
        },
      );

      testWidgets('adds the book with no thumbnail when no cover validates', (
        tester,
      ) async {
        when(
          () => service.isThumbnailValid(any()),
        ).thenAnswer((_) async => false);
        when(
          () => repository.addBook(
            isbn: any(named: 'isbn'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            thumbnail: any(named: 'thumbnail'),
          ),
        ).thenAnswer((_) async => false);
        final books = [
          BookSearchResult(
            volumeId: 'vol-0',
            title: 'Book 0',
            authors: const ['Author 0'],
            isbn: '9780000000000',
            thumbnail: 'https://covers.example.com/placeholder.jpg',
          ),
        ];
        await pumpPage(tester, results: books, totalItems: 1);

        await tester.tap(find.text('Book 0'));
        await tester.pump();
        await tester.tap(find.byType(AddToShelfButton));
        await tester.pumpAndSettle();

        verify(
          () => repository.addBook(
            isbn: '9780000000000',
            title: 'Book 0',
            author: 'Author 0',
            thumbnail: null,
          ),
        ).called(1);
        // The book still lands on the shelf despite no valid cover —
        // GenericBookCover covers the display side of this case.
        expect(find.text('Bookshelf destination'), findsOneWidget);
      });
    });

    group('pagination', () {
      testWidgets('loads the next page when scrolled near the end', (
        tester,
      ) async {
        // A full first page with an unknown total means "probably more".
        when(
          () => service.search(any(), startIndex: any(named: 'startIndex')),
        ).thenAnswer(
          (_) async => GoogleBooksPage(
            results: [
              BookSearchResult(
                volumeId: 'vol-next',
                title: 'Next Page Book',
                authors: const ['New Author'],
                isbn: '9780000000099',
                thumbnail: '',
              ),
            ],
            totalItems: 21,
          ),
        );
        await pumpPage(tester, results: makeBooks(GoogleBooksService.pageSize));

        // Tiles are ~215px tall, so a full page is ~5200px of content;
        // one long drag pins the list to its end (drags don't fling).
        await tester.drag(find.byType(ListView), const Offset(0, -8000));
        await tester.pumpAndSettle();

        // Next page was requested where the current list ended.
        verify(() => service.search('gatsby', startIndex: 20)).called(1);
        expect(find.text('Next Page Book'), findsOneWidget);
      });

      testWidgets('does not fetch when all results are already shown', (
        tester,
      ) async {
        // totalItems matches what we have: scrolling must stay quiet.
        await pumpPage(tester, results: makeBooks(3), totalItems: 3);

        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -1000),
        );
        await tester.pumpAndSettle();

        verifyNever(
          () => service.search(any(), startIndex: any(named: 'startIndex')),
        );
      });

      testWidgets('reports pagination failures without losing the list', (
        tester,
      ) async {
        when(
          () => service.search(any(), startIndex: any(named: 'startIndex')),
        ).thenThrow(Exception('rate limited'));
        await pumpPage(tester, results: makeBooks(GoogleBooksService.pageSize));

        await tester.drag(find.byType(ListView), const Offset(0, -8000));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Failed to load more results'),
          findsOneWidget,
        );
        // The books the user already had are still there behind the snackbar.
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}
