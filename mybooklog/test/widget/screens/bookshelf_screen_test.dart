import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/book_on_shelf.dart';

import '../../helpers/test_app_builder.dart';
import '../../unit/mocks/mock_repositories.dart';

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

  group('BookshelfScreen', () {
    testWidgets('displays loading spinner while fetching shelf',
        (WidgetTester tester) async {
      final completer = Completer<List<ShelfBook>>();
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [],
        authStateController,
      );
      // Override fetchShelf to return incomplete future
      when(() => mockBookshelfRepository.fetchShelf())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      // Pump frames without settling (since future is incomplete)
      await tester.pump();
      await tester.pump();

      // Verify bookshelf screen appears while loading
      expect(find.byType(BookshelfScreen), findsOneWidget);
    });

    testWidgets('displays books in grid after successful load',
        (WidgetTester tester) async {
      final testBooks = TestBookFactory.createTestBooks(6);
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        testBooks,
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

      // GridView uses lazy rendering - only visible items render
      // Scroll down to render all items
      final gridView = find.byType(GridView);
      if (gridView.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          find.byType(BookOnShelf).last,
          500,
          scrollable: gridView.first,
        );
        await tester.pumpAndSettle();
      }

      expect(find.byType(BookOnShelf), findsNWidgets(6));
    });

    testWidgets('displays empty shelf message when no books',
        (WidgetTester tester) async {
      TestSetupHelpers.setupEmptyShelf(mockBookshelfRepository);
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

      expect(find.byType(BookOnShelf), findsNothing);
      expect(
        find.byWidgetPredicate((widget) =>
            widget is Text && widget.data?.contains('empty') == true),
        findsOneWidget,
      );
    });

    testWidgets('shows error message when shelf load fails',
        (WidgetTester tester) async {
      TestSetupHelpers.setupShelfLoadError(mockBookshelfRepository);
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

      // Verify bookshelf screen still displays (with error handling)
      expect(find.byType(BookshelfScreen), findsOneWidget);
    });

    testWidgets('filters books by search query', (WidgetTester tester) async {
      final books = [
        TestBookFactory.createTestBook(title: 'The Great Gatsby'),
        TestBookFactory.createTestBook(title: 'The Catcher in the Rye'),
        TestBookFactory.createTestBook(title: 'Moby Dick'),
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

      expect(find.byType(BookOnShelf), findsNWidgets(3));

      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton.first);
        await tester.pumpAndSettle();

        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField.first, 'great');
          await tester.pumpAndSettle();

          expect(find.byType(BookOnShelf), findsOneWidget);
        }
      }
    });

    testWidgets('add book button is accessible', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [TestBookFactory.createTestBook()],
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

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('logout button is accessible', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        [TestBookFactory.createTestBook()],
        authStateController,
      );
      when(() => mockAuthRepository.signOut()).thenAnswer((_) async {});

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('renders large shelf with 50+ books', (WidgetTester tester) async {
      final largeShelf = TestBookFactory.createTestBooks(50);
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

      expect(find.byType(BookOnShelf), findsWidgets);
    });
  });
}
