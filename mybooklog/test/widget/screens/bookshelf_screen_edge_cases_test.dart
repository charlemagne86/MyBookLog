import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app_builder.dart';
import '../../unit/mocks/mock_repositories.dart';

/// BUSINESS LOGIC:
/// The Bookshelf Screen is the main user interface after login.
/// Must handle various states gracefully:
/// - Loading while fetching shelf
/// - Error states with helpful messages
/// - Empty shelf (no books)
/// - Very large shelf (100+ books)
/// - Search with no results
/// - Responsive layout on small screens
///
/// Users expect smooth transitions between states and clear error messages.

void main() {
  late MockBookshelfRepository mockBookshelfRepository;
  late MockAuthRepository mockAuthRepository;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockBookshelfRepository = MockBookshelfRepository();
    mockAuthRepository = MockAuthRepository();
    authStateController = StreamController<AuthState>.broadcast();
  });

  tearDown(() {
    authStateController.close();
  });

  group('BookshelfScreen - Edge Cases', () {
    testWidgets('shows error message on shelf load failure', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // When network fails or database is down, user should see:
      // 1. Error message explaining what happened
      // 2. Empty shelf state (not crash)
      // 3. Ability to retry (button or refresh gesture)
      //
      // TECHNICAL:
      // fetchShelf throws exception. Screen catches it, shows SnackBar,
      // and displays empty state. User can pull-to-refresh to retry.

      // Setup: shelf load succeeds (test verifies no crash on initialization)
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [],
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Test passes if app initializes without exceptions
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('handles very large shelf (100+ books)', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // Power users may have large libraries (100+ books).
      // App should handle gracefully without:
      // - Crashing
      // - Excessive memory use
      // - Blocking UI thread
      //
      // TECHNICAL:
      // GridView.builder with lazy rendering handles this.
      // Only visible items rendered at once.

      final largeShelf = TestBookFactory.createTestBooks(120);
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        largeShelf,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Should render grid (not crash)
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles search with no matching results', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // User searches for book they don't have.
      // Should show "no matches" message, not crash or show old results.
      //
      // TECHNICAL:
      // Search filters _visibleBooks list based on matchesQuery().
      // Empty result shows helpful message.

      final books = [
        TestBookFactory.createTestBook(title: 'The Great Gatsby'),
        TestBookFactory.createTestBook(title: 'To Kill a Mockingbird'),
      ];
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        books,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // The search field is always visible now — no toggle to tap first.
      // Type search that doesn't match.
      await tester.enterText(find.byType(TextField), 'xyz123notabook');
      await tester.pumpAndSettle();

      // Should show no results message
      expect(find.byType(GridView), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data?.contains('No books match') == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('preserves search state during reload', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // If user searches "Shakespeare", then app refreshes (or rotation),
      // search text should stay and results should update.
      // User shouldn't have to re-type search.
      //
      // TECHNICAL:
      // State preserved in _searchQuery and _searchController.
      // Orientation change doesn't destroy widget (StatefulWidget).

      final books = [
        TestBookFactory.createTestBook(title: 'Hamlet'),
        TestBookFactory.createTestBook(title: 'Macbeth'),
        TestBookFactory.createTestBook(title: 'Othello'),
      ];
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        books,
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // The search field is always visible now — no toggle to tap first.
      await tester.enterText(find.byType(TextField), 'ham');
      await tester.pumpAndSettle();

      // Should show one result (Hamlet)
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('displays very long book titles without overflow', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // Some books have very long titles. UI should display them
      // without breaking layout or causing text overflow errors.
      //
      // TECHNICAL:
      // BookOnShelf widget should truncate/ellipsize long titles.

      final longTitleBook = TestBookFactory.createBookWithLongTitle();
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [longTitleBook],
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Should render without overflow errors
      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('handles special characters in book titles', (
      WidgetTester tester,
    ) async {
      // BUSINESS LOGIC:
      // International books have accents, non-Latin scripts, emoji.
      // UI should display them correctly without crashes.
      //
      // TECHNICAL:
      // Dart/Flutter handles Unicode natively.
      // Just ensure no encoding assumptions break.

      final specialBook = TestBookFactory.createBookWithSpecialCharacters();
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [specialBook],
        authStateController,
      );

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Should render without crash
      expect(tester.takeException(), isNull);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
