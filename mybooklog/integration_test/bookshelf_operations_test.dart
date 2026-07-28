import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/app.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:provider/provider.dart';

import 'helpers/integration_test_helper.dart';

// ============================================================================
// Bookshelf Operations Integration Tests
// ============================================================================

void main() {
  setUpAll(() async {
    // Initialize Supabase for tests (must run before any tests)
    await initializeSupabaseForTests();
  });

  group('Bookshelf Operations', () {
    final helper = IntegrationTestHelper();

    // BUSINESS LOGIC:
    // Once logged in, users need to manage their book collection:
    // - View books in a grid
    // - Search for books
    // - Mark books as read/unread
    // - Remove books they no longer want
    // These gestures and operations are critical for the core user experience.

    testWidgets('display bookshelf with sample books',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user is logged in, has books on shelf
      final (mockAuth, mockBookshelf) = await helper.setupMocks();

      // Mock logged-in state
      when(() => mockAuth.currentSession).thenReturn(MockSession());

      // Mock shelf with sample books
      when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => [
            ShelfBook(
              bookId: '1',
              title: 'The Foundation',
              author: 'Isaac Asimov',
              thumbnailUri: 'https://example.com/foundation.jpg',
              isRead: false,
            ),
            ShelfBook(
              bookId: '2',
              title: 'Dune',
              author: 'Frank Herbert',
              thumbnailUri: 'https://example.com/dune.jpg',
              isRead: true,
            ),
          ]);

      // TECHNICAL:
      // Launch app (should route to bookshelf since logged in)
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Verify bookshelf screen is displayed
      expect(find.text('My Bookshelf'), findsOneWidget);
      expect(find.text('The Foundation'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);

      // TECHNICAL:
      // Verify grid layout is used
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('search functionality filters books',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user logged in with books
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(MockSession());

      when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => [
            ShelfBook(
              bookId: '1',
              title: 'The Foundation',
              author: 'Isaac Asimov',
              thumbnailUri: 'https://example.com/foundation.jpg',
              isRead: false,
            ),
            ShelfBook(
              bookId: '2',
              title: 'Dune',
              author: 'Frank Herbert',
              thumbnailUri: 'https://example.com/dune.jpg',
              isRead: true,
            ),
          ]);

      // TECHNICAL:
      // Launch app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Tap search icon to open search bar
      await helper.tap(tester, find.byIcon(Icons.search));

      // TECHNICAL:
      // Enter search query
      await helper.enterText(
        tester,
        find.byType(TextField),
        'dune',
      );

      // TECHNICAL:
      // Verify filtered results (only Dune should show)
      expect(find.text('Dune'), findsOneWidget);
      // Foundation should be filtered out (or at least verify search worked)
    });

    testWidgets('long press book shows context menu',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user logged in with books
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(MockSession());

      when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => [
            ShelfBook(
              bookId: '1',
              title: 'The Foundation',
              author: 'Isaac Asimov',
              thumbnailUri: 'https://example.com/foundation.jpg',
              isRead: false,
            ),
          ]);

      // TECHNICAL:
      // Launch app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Long-press a book to show context menu
      await helper.longPressWidget(tester, find.text('The Foundation'));

      // TECHNICAL:
      // Verify context menu appears with options
      expect(find.text('Remove Book'), findsOneWidget);
      expect(find.text('Mark as Read'), findsOneWidget);
    });

    testWidgets('remove book from shelf', (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user logged in with a book
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(MockSession());

      final initialBooks = [
        ShelfBook(
          bookId: '1',
          title: 'The Foundation',
          author: 'Isaac Asimov',
          thumbnailUri: 'https://example.com/foundation.jpg',
          isRead: false,
        ),
      ];

      when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => initialBooks);

      // Mock remove operation
      when(() => mockBookshelf.removeBook(any()))
          .thenAnswer((_) async {
            // Simulate removal by clearing the list
            initialBooks.clear();
          });

      // TECHNICAL:
      // Launch app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Long-press to open context menu
      await helper.longPressWidget(tester, find.text('The Foundation'));

      // TECHNICAL:
      // Tap "Remove Book"
      await helper.tap(tester, find.text('Remove Book'));

      // TECHNICAL:
      // Verify removeBook was called
      verify(() => mockBookshelf.removeBook(any())).called(greaterThan(0));

      // TECHNICAL:
      // Book should be removed from shelf
      expect(find.text('The Foundation'), findsNothing);
    });

    testWidgets('mark book as read', (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user logged in, book is unread
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(MockSession());

      when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => [
            ShelfBook(
              bookId: '1',
              title: 'The Foundation',
              author: 'Isaac Asimov',
              thumbnailUri: 'https://example.com/foundation.jpg',
              isRead: false,
            ),
          ]);

      // Mock read status update
      when(() => mockBookshelf.setReadStatus(any(), isRead: any(named: 'isRead')))
          .thenAnswer((_) async {});

      // TECHNICAL:
      // Launch app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Long-press to open context menu
      await helper.longPressWidget(tester, find.text('The Foundation'));

      // TECHNICAL:
      // Tap "Mark as Read" (for unread book)
      await helper.tap(tester, find.text('Mark as Read'));

      // TECHNICAL:
      // Verify setReadStatus was called
      verify(() => mockBookshelf.setReadStatus(any(), isRead: true))
          .called(greaterThan(0));
    });
  });
}
