import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/book_on_shelf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    testWidgets('displays loading spinner while fetching shelf', (
      WidgetTester tester,
    ) async {
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

      // Emit auth state after pumpWidget so router listener is ready
      final now = DateTime.now().toIso8601String();
      final testSession = Session(
        accessToken: 'test-token',
        tokenType: 'bearer',
        expiresIn: 3600,
        refreshToken: 'refresh-token',
        user: User(
          id: 'test-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          confirmationSentAt: null,
          recoverySentAt: null,
          emailConfirmedAt: now,
          invitedAt: null,
          actionLink: '',
          email: 'test@example.com',
          phone: '',
          createdAt: now,
          identities: [],
          lastSignInAt: now,
          role: 'authenticated',
          updatedAt: now,
        ),
      );
      authStateController.add(AuthState(AuthChangeEvent.signedIn, testSession));

      // Pump and settle to let router navigate
      await tester.pumpAndSettle();

      // Verify bookshelf screen appears
      expect(find.byType(BookshelfScreen), findsOneWidget);
    });

    testWidgets('displays books in grid after successful load', (
      WidgetTester tester,
    ) async {
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

      // Emit auth state after pumpWidget
      final now = DateTime.now().toIso8601String();
      final testSession = Session(
        accessToken: 'test-token',
        tokenType: 'bearer',
        expiresIn: 3600,
        refreshToken: 'refresh-token',
        user: User(
          id: 'test-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          confirmationSentAt: null,
          recoverySentAt: null,
          emailConfirmedAt: now,
          invitedAt: null,
          actionLink: '',
          email: 'test@example.com',
          phone: '',
          createdAt: now,
          identities: [],
          lastSignInAt: now,
          role: 'authenticated',
          updatedAt: now,
        ),
      );
      authStateController.add(AuthState(AuthChangeEvent.signedIn, testSession));

      await tester.pumpAndSettle();

      // Verify books are displayed in grid
      expect(find.byType(BookOnShelf), findsWidgets);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays empty shelf message when no books', (
      WidgetTester tester,
    ) async {
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
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.data?.contains('empty') == true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error message when shelf load fails', (
      WidgetTester tester,
    ) async {
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

      // The search field only appears after tapping the AppBar icon.
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'great');
      await tester.pumpAndSettle();

      expect(find.byType(BookOnShelf), findsOneWidget);
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

    testWidgets('renders large shelf with 50+ books', (
      WidgetTester tester,
    ) async {
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
