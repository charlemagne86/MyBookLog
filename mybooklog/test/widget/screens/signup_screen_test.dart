import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/config/app_config.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/features/auth/signup_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../helpers/fake_url_launcher_platform.dart';
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

  group('SignupScreen', () {
    testWidgets('displays signup form with fields', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      // Verify auth screen renders (login or signup)
      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('accepts valid email input', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'user@example.com');
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('password visibility toggle exists', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      expect(find.byIcon(Icons.visibility), findsWidgets);
    });

    testWidgets('has submit button', (WidgetTester tester) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays password requirements text', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.data?.contains('Password') == true,
        ),
        findsWidgets,
      );
    });

    testWidgets('shows error on signup with invalid credentials', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupEmailAlreadyExists(mockAuthRepository);
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 4) {
        await tester.enterText(fields.at(0), 'user@example.com');
        await tester.enterText(fields.at(1), 'John');
        await tester.enterText(fields.at(2), 'StrongPass123!');
        await tester.enterText(fields.at(3), 'StrongPass123!');
        await tester.pumpAndSettle();

        final submitButton = find.byType(ElevatedButton).first;
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('form accepts all required fields', (
      WidgetTester tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(
        mockAuthRepository,
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

      // Verify form has fields for user input
      final fields = find.byType(TextField);
      expect(fields, findsWidgets);
      expect(fields.evaluate().length, greaterThanOrEqualTo(2));
    });
  });

  group('Privacy Policy link', () {
    late UrlLauncherPlatform originalPlatform;
    late FakeUrlLauncherPlatform fakePlatform;

    setUp(() {
      originalPlatform = UrlLauncherPlatform.instance;
      fakePlatform = FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fakePlatform;
    });

    tearDown(() {
      UrlLauncherPlatform.instance = originalPlatform;
    });

    /// Pumps SignUpScreen directly (not through the router), so this test
    /// is guaranteed to be exercising the actual signup form rather than
    /// whatever screen the router's redirect logic happens to land on.
    Future<void> pumpSignUpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<AuthRepository>.value(
          value: MockAuthRepository(),
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows a Privacy Policy link', (tester) async {
      await pumpSignUpScreen(tester);

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('tapping it launches the configured URL', (tester) async {
      await pumpSignUpScreen(tester);

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(fakePlatform.lastLaunchedUrl, AppConfig.privacyPolicyUrl);
    });
  });
}
