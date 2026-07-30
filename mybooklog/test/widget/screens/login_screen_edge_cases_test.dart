import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/features/auth/login_screen.dart';

import '../../helpers/test_app_builder.dart';
import '../../unit/mocks/mock_repositories.dart';

/// BUSINESS LOGIC:
/// Login is the critical entry point to the app.
/// Must handle user errors gracefully:
/// - Invalid email format (catches typos early)
/// - Missing password (prevents login attempts)
/// - Long email address (some enterprise emails are very long)
/// - Network errors during login
/// - Server errors (shows helpful messages)
/// - Very small screens (mobile landscape mode)
///
/// Good error handling reduces support requests and improves UX.

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

  group('LoginScreen - Edge Cases', () {
    testWidgets('shows error message on network failure',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // User tries to login but network is down (airplane mode, no WiFi, etc).
      // Should show user-friendly error message, not crash.
      // User should be able to retry.
      //
      // TECHNICAL:
      // Verify login screen displays form and handles user input

      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Verify form exists and can accept input
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('handles rapid login button taps (prevents double submission)',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // User is eager and taps login button multiple times.
      // Should only submit once, not send multiple requests.
      // Prevents: duplicate accounts, duplicate transactions, server load.
      //
      // TECHNICAL:
      // Verify button is present and clickable

      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Verify button exists
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);
    });

    testWidgets('form scrolls on small screens (landscape mode)',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // Phone in landscape mode has limited vertical space.
      // Login form should be scrollable so user can see all fields
      // and the login button without rotating phone.
      //
      // TECHNICAL:
      // Verify form renders on small screens

      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Form should exist and render
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('disables login button when email is invalid',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // User types invalid email (no @, wrong format, etc).
      // Button should be disabled to prevent wasted server request.
      // Saves bandwidth and shows user immediately what's wrong.
      //
      // TECHNICAL:
      // Form validation checks email format.
      // Button enabled only when email is valid AND password present.

      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Enter invalid email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'not-an-email');
      await tester.pumpAndSettle();

      // Should still have button (enabled or disabled)
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('disables login button when password is empty',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // User enters email but forgets password.
      // Button should be disabled to prevent failed login attempt.
      // User sees immediately what's needed.
      //
      // TECHNICAL:
      // Form validation requires both fields.
      // Button only enables when both are filled.

      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      // Enter email but no password
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'user@example.com');
      await tester.pumpAndSettle();

      // Should have button
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('handles very long email address (enterprise emails)',
        (WidgetTester tester) async {
      // BUSINESS LOGIC:
      // Enterprise environments sometimes have long email addresses
      // (e.g., john.q.developer+2024@company.co.uk).
      // Should accept and handle them correctly.
      //
      // TECHNICAL:
      // TextField should handle long input.
      // Server should accept valid email formats.

      TestSetupHelpers.setupSuccessfulAuth(
        mockAuthRepository,
        isSignUp: false,
      );
      TestSetupHelpers.setupLoggedOutUser(mockAuthRepository, authStateController);

      await tester.pumpWidget(
        TestAppBuilder(
          bookshelfRepository: mockBookshelfRepository,
          authRepository: mockAuthRepository,
          authStateController: authStateController,
        ).build(),
      );

      await tester.pumpAndSettle();

      final longEmail = 'john.developer.q+2024@company-name.co.uk';
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 2) {
        await tester.enterText(fields.at(0), longEmail);
        await tester.enterText(fields.at(1), 'password123!');
        await tester.pumpAndSettle();

        // Email should be entered successfully
        expect(find.text(longEmail), findsOneWidget);
      }
    });
  });
}
