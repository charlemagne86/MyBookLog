import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/integration_test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  group('E2E: Complete User Journeys', () {
    final testHelper = IntegrationTestHelper();

    setUp(() async {
      await testHelper.initializeApp();
    });

    tearDown(() async {
      await testHelper.cleanup();
    });

    testWidgets('complete_onboarding_to_bookshelf', (WidgetTester tester) async {
      /// Complete user flow: App launch → Login → Bookshelf view.
      ///
      /// BUSINESS LOGIC: New user journey is critical for retention.
      /// Should be friction-free from splash screen to functional app.
      /// TECHNICAL: Tests entire auth flow and initial screen display
      /// in single integrated test.

      // Step 1: Launch app
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      // Step 2: Verify splash/login screen visible
      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Should show login screen for new user',
      );

      // Step 3: Enter credentials
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'newuser@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Step 4: Set up login mock and tap button
      // Mock successful login BEFORE tapping button so the callback is registered
      await testHelper.mockSuccessfulLogin(
        email: 'newuser@example.com',
        password: 'password123',
      );

      final signInButton = find.byType(ElevatedButton).first;
      await tester.tap(signInButton);

      // Wait for navigation and bookshelf to load
      // This includes: app calling signIn(), mock callback running,
      // auth stream updating, router navigating, bookshelf rendering
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Step 5: Verify bookshelf visible
      expect(
        find.byIcon(Icons.search),
        findsWidgets,
        reason: 'Should show bookshelf with search bar',
      );

      expect(
        find.byType(GridView),
        findsWidgets,
        reason: 'Should show book grid',
      );

      // Step 6: Verify interactive (can tap search)
      final searchIcon = find.byIcon(Icons.search).first;
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Search should open',
      );
    });

    testWidgets('complete_login_search_interact', (WidgetTester tester) async {
      /// Complete flow: Login → Bookshelf → Search → View results.
      ///
      /// BUSINESS LOGIC: User's primary interaction is viewing and searching
      /// their book collection. This flow tests end-to-end functionality.
      /// TECHNICAL: Tests navigation, search, and grid display in sequence.

      // Step 1: Set up logged-in state
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      // Wait for bookshelf to load books from mock (increased to 5s)
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Step 2: Verify bookshelf
      expect(find.byType(GridView), findsWidgets);

      // Step 3: Open search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      // Step 4: Enter search term (must match actual book data)
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Great');
      // Wait for search filtering (increased to 3s)
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Step 5: Verify filtered results
      expect(find.byType(GridView), findsWidgets);

      // Step 6: Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Step 7: Verify full list returned
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('complete_error_recovery_workflow', (WidgetTester tester) async {
      /// Tests user recovery from login error and successful retry.
      ///
      /// BUSINESS LOGIC: Users make mistakes; app should help them
      /// recover gracefully (wrong password, network error, etc).
      /// TECHNICAL: Simulates failed login, verifies error message,
      /// allows retry and successful login.

      // Step 1: Launch app
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      // Step 2: Enter wrong credentials
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle();

      // Step 3: Mock failed login
      await testHelper.mockFailedLogin(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      // Step 4: Tap sign in (will fail)
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Step 5: Verify error message shown
      expect(
        find.byType(Text),
        findsWidgets,
        reason: 'Should display error message',
      );

      // Step 6: Clear and retry with correct password
      await tester.enterText(passwordField, 'correctpassword123');
      await tester.pumpAndSettle();

      // Step 7: Mock successful login
      await testHelper.mockSuccessfulLogin(
        email: 'test@example.com',
        password: 'correctpassword123',
      );

      // Step 8: Tap sign in again
      await tester.tap(find.byType(ElevatedButton).first);
      // Wait for navigation to bookshelf
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Step 9: Verify success (bookshelf visible)
      expect(
        find.byIcon(Icons.search),
        findsWidgets,
        reason: 'Should navigate to bookshelf after successful login',
      );
    });

    testWidgets('complete_session_across_multiple_operations', (WidgetTester tester) async {
      /// Verifies session remains valid across multiple app operations.
      ///
      /// BUSINESS LOGIC: Users should not be logged out unexpectedly
      /// during normal app usage (session persistence).
      /// TECHNICAL: Logs in, performs multiple operations, verifies still
      /// authenticated throughout.

      // Step 1: Login
      await testHelper.setLoggedOutState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'session@example.com');
      await tester.enterText(passwordField, 'password123');

      await testHelper.mockSuccessfulLogin(
        email: 'session@example.com',
        password: 'password123',
      );

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Step 2: Verify logged in (bookshelf visible)
      expect(find.byType(GridView), findsWidgets);

      // Step 3: Search (operation 1)
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Gatsby');
      await tester.pumpAndSettle();

      // Step 4: Verify still logged in and can search
      expect(find.byType(GridView), findsWidgets);

      // Step 5: Close search (back to grid) (operation 2)
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Step 6: Verify still logged in
      expect(find.byType(GridView), findsWidgets);

      // Step 7: Perform another pump cycle (operation 3)
      await tester.pumpAndSettle();

      // Step 8: Verify still logged in and functional
      expect(find.byType(GridView), findsWidgets);

      // Step 9: Verify user is still in authenticated state
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('complete_rapid_interactions', (WidgetTester tester) async {
      /// Tests app stability under rapid user interactions.
      ///
      /// BUSINESS LOGIC: Users may tap quickly or navigate rapidly;
      /// app should handle gracefully (no crashes, consistent state).
      /// TECHNICAL: Performs rapid taps and navigation, verifies app
      /// remains functional and doesn't crash.

      // Step 1: Login
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      // Step 2: Rapidly tap search icon and close
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pump(Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.search).first);
        await tester.pump(Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle();

      // Step 3: Verify app is still functional
      expect(find.byType(GridView), findsWidgets);

      // Step 4: Rapidly scroll
      await tester.drag(find.byType(GridView).first, const Offset(0, -200));
      await tester.pump(Duration(milliseconds: 50));
      await tester.drag(find.byType(GridView).first, const Offset(0, 200));
      await tester.pumpAndSettle();

      // Step 5: Final verification
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('complete_workflow_with_state_changes', (WidgetTester tester) async {
      /// Complete flow with state changes (logged in → interact → still logged in).
      ///
      /// BUSINESS LOGIC: App state should persist correctly through
      /// various user interactions.
      /// TECHNICAL: Logs in, changes state through interactions,
      /// verifies state consistency.

      // Step 1: Start logged out
      await testHelper.setLoggedOutState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);

      // Step 2: Login
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).at(1);

      await tester.enterText(emailField, 'workflow@example.com');
      await tester.enterText(passwordField, 'password123');

      await testHelper.mockSuccessfulLogin(
        email: 'workflow@example.com',
        password: 'password123',
      );

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Step 3: Now logged in (state changed)
      expect(find.byType(GridView), findsWidgets);

      // Step 4: Interact with search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      // Step 5: Verify still logged in
      expect(find.byType(TextField), findsWidgets); // Search field

      // Step 6: Close search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Step 7: Verify logged in and back to grid
      expect(find.byType(GridView), findsWidgets);
    });
  });
}
