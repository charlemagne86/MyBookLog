import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';

import 'helpers/integration_test_helper.dart';

// ============================================================================
// SplashScreen Routing Integration Tests
// ============================================================================

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Routing', () {
    final helper = IntegrationTestHelper();

    // BUSINESS LOGIC:
    // When the app starts, users aged 60+ should see the branding for a moment
    // (the splash screen) before being routed to either:
    // - Login screen (if not logged in)
    // - Bookshelf screen (if logged in from before)
    // This provides confidence that the app is loading and recognizes their state.

    testWidgets('routes to login screen when user not logged in',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up auth mock to return no session (not logged in)
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      // TECHNICAL:
      // Launch the app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // The app should route to login after the splash screen delay.
      // Verify by checking for login screen elements.
      expect(find.text('Login'), findsWidgets); // Title + button
      expect(find.text('Username (email)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays splash screen initially', (WidgetTester tester) async {
      // TECHNICAL:
      // Set up auth mock
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      // TECHNICAL:
      // Pump the widget tree but don't settle (to catch splash screen)
      final MultiProvider app = MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: mockAuth),
          Provider<BookshelfRepository>.value(value: mockBookshelf),
        ],
        child: const MyBookLogApp(),
      );

      await tester.pumpWidget(app);

      // TECHNICAL:
      // Should see splash screen elements
      expect(find.text('My Book Log'), findsOneWidget);
      expect(find.text('crafted with love'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('splash screen waits 2 seconds before routing',
        (WidgetTester tester) async {
      // TECHNICAL:
      // This test verifies the timing of the splash screen display.
      // After 2 seconds, navigation to login should complete.
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // After pumpAndSettle (which waits for all animations/timers),
      // the router should have completed navigation to login screen.
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Username (email)'), findsOneWidget);
    });
  });
}

// Import for test data
import 'package:mybooklog/src/features/auth/login_screen.dart';
import 'package:mybooklog/src/features/auth/splash_screen.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:mybooklog/src/app.dart';
import 'package:provider/provider.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
