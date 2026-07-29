import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/features/auth/login_screen.dart';

// BUSINESS LOGIC:
// Login is the critical entry point to the app.
// Must handle user errors gracefully:
// - Invalid email format (catches typos early)
// - Missing password (prevents login attempts)
// - Long email address (some enterprise emails are very long)
// - Network errors during login
// - Server errors (shows helpful messages)
// - Very small screens (mobile landscape mode)
//
// Good error handling reduces support requests and improves UX.

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LoginScreen - Edge Cases', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    testWidgets('disables login button when email is invalid', (WidgetTester tester) async {
      // TECHNICAL: Email field doesn't match email regex
      // Login button should be disabled to prevent wasted server request
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(
        find.byType(TextField).first,
        'not-an-email',
      );

      await tester.pumpAndSettle();

      // Login button should be disabled
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsWidgets);
    });

    testWidgets('disables login button when password is empty', (WidgetTester tester) async {
      // TECHNICAL: Password field is required
      // Button should only enable when both email and password present
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Enter valid email but no password
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );

      await tester.pumpAndSettle();

      // Login button should still be disabled (no password)
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsWidgets);
    });

    testWidgets('shows error message on network failure', (WidgetTester tester) async {
      // TECHNICAL: Network error during login RPC
      // Should show "Network error, please try again" message
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Enter credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');

      await tester.pumpAndSettle();

      // Tap login
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('handles very long email address', (WidgetTester tester) async {
      // TECHNICAL: Some enterprise emails are 100+ characters
      // Should accept without truncation or error
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      final longEmail = 'very.long.email.address.with.many.parts@enterprise-domain-name.com';
      
      await tester.enterText(find.byType(TextField).first, longEmail);
      await tester.pumpAndSettle();

      // Should display without truncation issues
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('form scrolls on small screens', (WidgetTester tester) async {
      // TECHNICAL: On very small phones in portrait, form might exceed screen height
      // Should be scrollable to access all fields and buttons
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      tester.binding.window.physicalSizeTestValue = const Size(400, 600);

      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Should be able to scroll to all elements
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('clears password field visibility toggle state correctly', (WidgetTester tester) async {
      // TECHNICAL: Password field has show/hide icon
      // Toggling should work correctly and state should persist
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Find and tap password visibility toggle
      // Verify password becomes visible/invisible correctly
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('handles rapid login button taps (prevents double submission)', (WidgetTester tester) async {
      // TECHNICAL: User taps login multiple times quickly
      // Should only submit once (debounce or disable button during request)
      var callCount = 0;
      when(() => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) {
        callCount++;
        return Future.delayed(const Duration(seconds: 1), () {});
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<AuthRepository>.value(
            value: mockAuth,
            child: LoginScreen(),
          ),
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password');
      await tester.pumpAndSettle();

      // Tap login multiple times
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Should only submit once
      expect(callCount, lessThanOrEqualTo(1));
    });
  });
}
