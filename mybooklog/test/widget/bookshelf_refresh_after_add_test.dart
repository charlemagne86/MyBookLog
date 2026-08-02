/// Regression test for the shelf-not-refreshing defect.
///
/// BUSINESS LOGIC:
/// After adding a book, the user lands back on "My Bookshelf" and expects
/// to see it there immediately — not after force-restarting the app. The
/// add-book flow returns via `context.go('/shelf')` rather than popping
/// back through each pushed screen, so go_router reuses the existing
/// BookshelfScreen instance instead of creating a fresh one; without an
/// explicit refresh hook, its one-time `initState` fetch never runs again
/// and the newly added book stays invisible until a full restart.
///
/// TECHNICAL:
/// Exercises the real navigation stack (the app's actual GoRouter, not a
/// stub): starts on /shelf, pushes /shelf/results the same way AddBookPage
/// would (bypassing AddBookPage's own UI, which is gated behind a
/// compile-time Google Books API key that CI never provides and isn't
/// itself part of this defect), then drives the real
/// select -> add -> "back to shelf" flow and asserts the new book is
/// visible with no manual refresh action from the test. `fetchShelf` is
/// stubbed to return an empty list on the first call (initial load) and a
/// list containing the new book on every call after — mirroring the real
/// database's state around the add operation.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/services/google_books_service.dart';
import 'package:mybooklog/src/features/book_search/search_results_page.dart';
import 'package:mybooklog/src/features/book_search/widgets/add_to_shelf_button.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/test_app_builder.dart';
import '../unit/mocks/mock_repositories.dart';
import '../unit/mocks/mock_services.dart';

void main() {
  testWidgets(
    'a newly added book appears on the shelf without restarting the app',
    (tester) async {
      final mockBookshelfRepository = MockBookshelfRepository();
      final mockAuthRepository = MockAuthRepository();
      final mockGoogleBooksService = MockGoogleBooksService();
      final authStateController = StreamController<AuthState>.broadcast();
      addTearDown(authStateController.close);

      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        const [],
        authStateController,
      );

      // First fetch (initial load): empty shelf. Every fetch after that
      // (triggered by the fix under test) returns the newly saved book —
      // simulating what the real database looks like before vs. after add.
      var fetchCount = 0;
      const addedBook = ShelfBook(
        bookId: 'book-1',
        title: 'Dune',
        author: 'Frank Herbert',
        thumbnailUri: '',
        isRead: false,
      );
      when(() => mockBookshelfRepository.fetchShelf()).thenAnswer((_) async {
        fetchCount++;
        return fetchCount == 1 ? const <ShelfBook>[] : [addedBook];
      });
      when(
        () => mockBookshelfRepository.addBook(
          isbn: any(named: 'isbn'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          thumbnail: any(named: 'thumbnail'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GoogleBooksService>.value(value: mockGoogleBooksService),
          ],
          child: TestAppBuilder(
            bookshelfRepository: mockBookshelfRepository,
            authRepository: mockAuthRepository,
          ).build(),
        ),
      );
      await tester.pumpAndSettle();

      // Starting point: shelf is genuinely empty.
      expect(find.text('Dune'), findsNothing);
      expect(
        find.text('Your bookshelf is empty. Tap + to add a book.'),
        findsOneWidget,
      );

      // Reach the search results screen the same way AddBookPage would
      // (its own search form is behind an API-key gate CI can't satisfy;
      // that gate is unrelated to the shelf-refresh defect under test).
      final shelfContext = tester.element(find.byType(BookshelfScreen));
      unawaited(
        GoRouter.of(shelfContext).push(
          '/shelf/results',
          extra: const SearchResultsArgs(
            results: [
              BookSearchResult(
                volumeId: 'vol-1',
                title: 'Dune',
                authors: ['Frank Herbert'],
                isbn: '9780441013593',
                thumbnail: '',
              ),
            ],
            searchQuery: 'Dune',
            totalItems: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select the book and add it — the real user-facing add flow.
      await tester.tap(find.text('Dune'));
      await tester.pump();
      await tester.tap(find.byType(AddToShelfButton));
      await tester.pumpAndSettle();

      // Back on the shelf: the book is visible with no manual refresh.
      expect(find.text('Dune'), findsOneWidget);
      expect(
        find.text('Your bookshelf is empty. Tap + to add a book.'),
        findsNothing,
      );
      expect(fetchCount, greaterThan(1));
    },
  );
}
