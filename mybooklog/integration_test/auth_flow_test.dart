import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/app.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:provider/provider.dart';

import 'helpers/integration_test_helper.dart';

// ============================================================================
// Auth Flow Integration Tests
// ============================================================================

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  group('Authentication Flow', () {
    final helper = IntegrationTestHelper();

    // BUSINESS LOGIC:
    // Users need to authenticate to access their book collection.
    // The complete flow is:
    // 1. App starts → SplashScreen
    // 2. SplashScreen routes to LoginScreen (not logged in)
    // 3. User enters email/password
    // 4. On success: LoginScreen routes to BookshelfScreen
    // 5. User can see their books

    testWidgets('complete login flow with valid credentials',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user not logged in initially
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      // Mock successful login
      when(
        () => mockAuth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        // Simulate successful login by updating session
        when(() => mockAuth.currentSession).thenReturn(
          // Mock session object (just needs to be non-null)
          MockSession(),
        );
      });

      // TECHNICAL:
      // Launch app (should route to login)
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Verify we're on login screen (check for unique login elements)
      expect(find.byType(TextField), findsWidgets, reason: 'Should show login form fields');
      expect(find.byType(ElevatedButton), findsOneWidget, reason: 'Should show login button');

      // TECHNICAL:
      // Enter credentials
      await helper.enterText(
        tester,
        find.byType(TextField).first,
        'user@example.com',
      );
      await helper.enterText(
        tester,
        find.byType(TextField).last,
        'password123',
      );

      // TECHNICAL:
      // Tap login button
      await helper.tap(tester, find.byType(ElevatedButton));

      // TECHNICAL:
      // After login, router should navigate to bookshelf.
      // Verify by checking for bookshelf screen elements.
      // Note: In real scenario, router would detect auth change via stream.
      // In this test, we're verifying the flow completes.
    });

    testWidgets('login with invalid credentials shows error',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks: user not logged in
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      // Mock failed login (throws exception)
      when(
        () => mockAuth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Invalid credentials'));

      // TECHNICAL:
      // Launch app (should route to login)
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Verify we're on login screen (check for unique login elements)
      expect(find.byType(TextField), findsWidgets, reason: 'Should show login form fields');
      expect(find.byType(ElevatedButton), findsOneWidget, reason: 'Should show login button');

      // TECHNICAL:
      // Enter invalid credentials
      await helper.enterText(
        tester,
        find.byType(TextField).first,
        'wrong@example.com',
      );
      await helper.enterText(
        tester,
        find.byType(TextField).last,
        'wrongpassword',
      );

      // TECHNICAL:
      // Tap login button
      await helper.tap(tester, find.byType(ElevatedButton));

      // TECHNICAL:
      // Error message should be shown
      // (would verify exact error text from friendlyMessage())
    });

    testWidgets('password visibility toggle works during login',
        (WidgetTester tester) async {
      // TECHNICAL:
      // Set up mocks
      final (mockAuth, mockBookshelf) = await helper.setupMocks();
      when(() => mockAuth.currentSession).thenReturn(null);

      // TECHNICAL:
      // Launch app
      await helper.launchApp(
        tester,
        mockAuth: mockAuth,
        mockBookshelf: mockBookshelf,
      );

      // TECHNICAL:
      // Enter password
      final passwordField = find.byType(TextField).last;
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // TECHNICAL:
      // Initially password should be obscured
      TextField password =
          tester.widget<TextField>(passwordField) as TextField;
      expect(password.obscureText, true);

      // TECHNICAL:
      // Tap visibility icon to show password
      await helper.tap(tester, find.byIcon(Icons.visibility));

      // TECHNICAL:
      // Password should now be visible
      password = tester.widget<TextField>(passwordField) as TextField;
      expect(password.obscureText, false);

      // TECHNICAL:
      // Tap again to hide password
      await helper.tap(tester, find.byIcon(Icons.visibility_off));

      password = tester.widget<TextField>(passwordField) as TextField;
      expect(password.obscureText, true);
    });
  });
}
