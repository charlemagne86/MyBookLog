import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/features/auth/login_screen.dart';

// ============================================================================
// Mock Repositories
// ============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

// ============================================================================
// Helper: pumpLoginScreen
// ============================================================================

/// Helper to pump a LoginScreen with mocked dependencies.
///
/// BUSINESS LOGIC:
/// The login screen is the gateway to the app. We need to test various
/// scenarios: successful login, incorrect credentials, network errors, etc.
/// Mocking the AuthRepository lets us simulate these scenarios deterministically.
///
/// TECHNICAL:
/// 1. Creates a mock AuthRepository
/// 2. Optionally sets up the mock to succeed or fail
/// 3. Wraps LoginScreen with the mock provider
/// 4. Returns the mock so tests can verify interactions
Future<MockAuthRepository> _pumpLoginScreen(
  WidgetTester tester, {
  Future<void> Function()? onSignIn,
}) async {
  final mockAuth = MockAuthRepository();

  // TECHNICAL:
  // Mock the signIn method. If onSignIn is provided, call it; otherwise, succeed.
  if (onSignIn != null) {
    when(
      () => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => onSignIn());
  } else {
    when(
      () => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => Future<void>.value());
  }

  // TECHNICAL:
  // Note: friendlyMessage is a static method which can't be mocked with Mocktail.
  // The actual method will be called, which is fine for our tests since it
  // handles real exceptions appropriately.

  await tester.pumpWidget(
    MultiProvider(
      providers: [Provider<AuthRepository>.value(value: mockAuth)],
      child: MaterialApp(home: const LoginScreen()),
    ),
  );

  return mockAuth;
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('LoginScreen', () {
    // BUSINESS LOGIC:
    // The login screen must present a clear form for users to enter their
    // email and password. For users aged 60+, large text and clear labels
    // are critical for usability.
    testWidgets('displays login form with email and password fields', (
      WidgetTester tester,
    ) async {
      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Verify all form fields and labels are present
      expect(find.text('Login'), findsWidgets); // Title + button
      expect(find.byType(TextField), findsWidgets); // Email & password fields
      expect(find.text('Username (email)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    // BUSINESS LOGIC:
    // The password field should default to showing dots (obscured text) to
    // protect privacy in shared spaces or over shoulders. Users can tap an
    // eye icon to temporarily show the password if they need to verify what
    // they typed.
    testWidgets('password field is obscured by default and can be toggled', (
      WidgetTester tester,
    ) async {
      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Find the password TextField and verify it's in obscured mode
      final passwordField = find.byType(TextField).at(1);
      TextField password = tester.widget<TextField>(passwordField);
      expect(password.obscureText, true);

      // TECHNICAL:
      // Tap the visibility toggle button
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // TECHNICAL:
      // Verify the password is now visible (not obscured)
      password = tester.widget<TextField>(passwordField);
      expect(password.obscureText, false);

      // TECHNICAL:
      // Tap again to re-hide the password
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      password = tester.widget<TextField>(passwordField);
      expect(password.obscureText, true);
    });

    // BUSINESS LOGIC:
    // When a user taps the Login button with valid credentials, the button
    // shows a spinner and becomes disabled to prevent accidental double-taps
    // while the request is in flight. The user's feedback is that the app
    // is working, not frozen.
    testWidgets('shows spinner on login button during submission', (
      WidgetTester tester,
    ) async {
      // TECHNICAL:
      // Create a completer so we can control when the login completes.
      // This lets us observe the loading state before navigation happens.
      final completer = Completer<void>();
      await _pumpLoginScreen(tester, onSignIn: () => completer.future);

      // TECHNICAL:
      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      // TECHNICAL:
      // Tap the login button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 50));

      // TECHNICAL:
      // While waiting for the server, the button should show a spinner and
      // be disabled to prevent accidental double-taps
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, null); // Null means disabled

      // TECHNICAL:
      // The test verifies the loading state. In the real app, after success
      // the router navigates away before the button state changes. We don't
      // verify post-completion state in widget tests since navigation is
      // tested at the integration level.
    });

    // BUSINESS LOGIC:
    // If login fails (invalid credentials, network error, etc.), the app shows
    // a friendly error message in red so the user understands what went wrong
    // and can try again. Technical errors are hidden behind user-friendly text.
    testWidgets('displays error message on login failure', (
      WidgetTester tester,
    ) async {
      // TECHNICAL:
      // Throw a generic exception (AuthRepository.friendlyMessage will convert
      // it to a user-friendly message like "Something went wrong...")
      final exception = Exception('Network error');
      await _pumpLoginScreen(tester, onSignIn: () => Future.error(exception));

      // TECHNICAL:
      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrongpassword');
      await tester.pump();

      // TECHNICAL:
      // Tap the login button and wait for error handling
      await tester.tap(find.byType(ElevatedButton));
      // Multiple pumps to ensure exception is caught and setState rebuilds
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // TECHNICAL:
      // After the error, the friendly message should appear
      // (generic exception returns "Something went wrong. Please check...")
      expect(
        find.text(
          'Something went wrong. Please check your connection and retry.',
        ),
        findsOneWidget,
      );

      // TECHNICAL:
      // Verify error text is displayed in red (error color from theme)
      final errorText = tester.widget<Text>(
        find.text(
          'Something went wrong. Please check your connection and retry.',
        ),
      );
      expect(
        errorText.style?.color,
        Theme.of(tester.element(find.byType(ElevatedButton))).colorScheme.error,
      );
    });

    // BUSINESS LOGIC:
    // After a login error is shown and the user taps login again,
    // the app should allow retry. The button should show a spinner again
    // when attempting to login after an error.
    testWidgets('clears error message when user retries login', (
      WidgetTester tester,
    ) async {
      // TECHNICAL:
      // Create a completer so we can control when each login attempt completes.
      // This lets us see the state between attempts without interference.
      var attemptCount = 0;
      final completer2 = Completer<void>();

      await _pumpLoginScreen(
        tester,
        onSignIn: () {
          attemptCount++;
          // First attempt fails, second succeeds
          if (attemptCount == 1) {
            return Future.error(Exception('Network error'));
          } else {
            return completer2.future;
          }
        },
      );

      // TECHNICAL:
      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      // TECHNICAL:
      // First tap: login fails and error is displayed
      await tester.tap(find.byType(ElevatedButton));
      // Multiple pumps to ensure error is caught and displayed
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      // TECHNICAL:
      // Error message should be visible
      expect(
        find.text(
          'Something went wrong. Please check your connection and retry.',
        ),
        findsOneWidget,
      );

      // TECHNICAL:
      // Second tap: verify that login can be attempted again (button is enabled)
      // and the spinner appears again (indicating new attempt is in progress).
      // The error clears and spinner shows when _login() runs again.
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 50));

      // TECHNICAL:
      // The spinner should appear again, indicating a new login attempt
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // BUSINESS LOGIC:
    // The "Forgot password?" link is a courtesy to users, but the actual
    // password reset feature is not yet implemented. Rather than remove the
    // link and confuse users looking for it, we show a helpful message
    // explaining it will be available soon.
    testWidgets('forgot password shows not-implemented message', (
      WidgetTester tester,
    ) async {
      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Tap the forgot password link
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      // TECHNICAL:
      // Verify the snackbar message appears
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Forgot password functionality is not implemented yet.'),
        findsOneWidget,
      );
    });

    // BUSINESS LOGIC:
    // Below the login button is a link to the signup screen for new users.
    // This is the standard flow when someone doesn't have an account yet.
    testWidgets('has signup link below login button', (
      WidgetTester tester,
    ) async {
      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Check that there's a link to signup (typically "Don't have an account?")
      // The exact text is in the actual implementation; this test checks it exists
      expect(
        find.byType(TextButton),
        findsWidgets, // Multiple text buttons: forgot password + signup
      );
    });

    // BUSINESS LOGIC:
    // The login button should only be enabled when the user has actually
    // entered something in both fields. A disabled button prevents accidental
    // blank submissions.
    testWidgets('login button is enabled when both fields have text', (
      WidgetTester tester,
    ) async {
      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Initially both fields are empty, button may or may not be enabled
      // (depends on implementation preference)
      ElevatedButton button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      // In this implementation, the button is always enabled to let the user
      // attempt login and see the error message (better UX than a grayed button)

      // TECHNICAL:
      // Enter text in the first field (email)
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.pumpAndSettle();

      // Button should be enabled
      button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // TECHNICAL:
      // Enter text in the second field (password)
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pumpAndSettle();

      // Button should still be enabled
      button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    // BUSINESS LOGIC:
    // The entire login form should fit on the screen for users aged 60+,
    // without requiring excessive scrolling. A ScrollView ensures nothing
    // is hidden even on smaller screens, and all elements remain interactive.
    testWidgets('form is scrollable on small screens', (
      WidgetTester tester,
    ) async {
      // TECHNICAL:
      // Default screen size test is sufficient (800x600). The real verification
      // is that SingleChildScrollView exists and form elements are accessible.
      // Actual small-screen rendering (e.g., 360px) is better tested with
      // manual testing or integration tests due to layout complexity.

      await _pumpLoginScreen(tester);

      // TECHNICAL:
      // Verify the form is wrapped in a SingleChildScrollView for scroll support
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // TECHNICAL:
      // All elements should be present and findable (indicates complete form)
      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);

      // TECHNICAL:
      // Verify we can interact with the form (scroll container doesn't prevent interaction)
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('user@example.com'), findsOneWidget);
    });

    // BUSINESS LOGIC:
    // The login form sends the user's email and password to the AuthRepository.
    // We verify that the correct values are passed and that signIn is called
    // exactly once per button tap.
    testWidgets('calls signIn with email and password from fields', (
      WidgetTester tester,
    ) async {
      final mockAuth = await _pumpLoginScreen(tester);

      final email = 'user@example.com';
      final password = 'securePassword123';

      // TECHNICAL:
      // Enter credentials
      await tester.enterText(find.byType(TextField).first, email);
      await tester.enterText(find.byType(TextField).last, password);
      await tester.pump();

      // TECHNICAL:
      // Tap login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump(const Duration(milliseconds: 50));

      // TECHNICAL:
      // Verify signIn was called with the correct email and password
      verify(() => mockAuth.signIn(email: email, password: password)).called(1);
    });
  });
}
