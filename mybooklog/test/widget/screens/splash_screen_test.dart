import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mybooklog/src/features/auth/splash_screen.dart';

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

  group('SplashScreen', () {
    testWidgets('displays splash screen on startup', (
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

      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('shows loading spinner during splash', (
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

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('displays text on splash', (WidgetTester tester) async {
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

      await tester.pump();

      expect(find.byType(Text), findsWidgets);
      expect(find.byType(SplashScreen), findsOneWidget);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('navigates away from splash eventually', (
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

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('responds to auth state changes', (WidgetTester tester) async {
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

      await tester.pump();
      expect(find.byType(SplashScreen), findsOneWidget);

      final testBooks = TestBookFactory.createTestBooks(1);
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuthRepository,
        mockBookshelfRepository,
        testBooks,
        authStateController,
      );

      await tester.pumpAndSettle();
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('splash screen mounts without error', (
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

      await tester.pump();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Cleanup: wait for timers to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    });
  });
}
