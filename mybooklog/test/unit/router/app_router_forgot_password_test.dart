import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/core/router/app_router.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/features/auth/forgot_password_screen.dart';
import 'package:mybooklog/src/features/auth/login_screen.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_app_builder.dart';

// BUSINESS LOGIC:
// The router's redirect is the app's security guard, and the forgot-password
// flow forces it to distinguish two ideas that used to be one:
//  * screens a logged-OUT user may see (login, signup, AND forgot-password —
//    the flow exists precisely for people who cannot log in), and
//  * screens a logged-IN user gets bounced away from (login, signup only).
// Forgot-password must NOT be in the second list: verifying the emailed
// code signs the user in MIDWAY through the flow, and bouncing them to the
// shelf at that moment would strand them with the old password unchanged.
//
// TECHNICAL:
// Real buildRouter + mocked repositories via TestAppBuilder. Each test
// navigates and asserts which screen actually rendered.

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBookshelfRepository extends Mock implements BookshelfRepository {}

void main() {
  late MockAuthRepository mockAuth;
  late MockBookshelfRepository mockBookshelf;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockAuth = MockAuthRepository();
    mockBookshelf = MockBookshelfRepository();
    authStateController = StreamController<AuthState>.broadcast();
  });

  tearDown(() async {
    await authStateController.close();
  });

  /// Pumps the full app with the REAL production router and returns that
  /// router so tests can drive navigation exactly as app code does.
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = buildRouter(mockAuth);
    final builder = TestAppBuilder(
      bookshelfRepository: mockBookshelf,
      authRepository: mockAuth,
      router: router,
      authStateController: authStateController,
    );
    await tester.pumpWidget(builder.build());
    await tester.pumpAndSettle();
    return router;
  }

  group('Router redirect — forgot-password access', () {
    // BUSINESS LOGIC: A logged-out user (the whole audience of this flow)
    // must be able to reach the forgot-password screen without being
    // bounced to /login like other protected locations.
    testWidgets('logged-out user can open /forgot-password', (tester) async {
      TestSetupHelpers.setupLoggedOutUser(mockAuth, authStateController);
      final router = await pumpApp(tester);
      router.go('/forgot-password');
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    // BUSINESS LOGIC: Sanity check that the redirect split did not loosen
    // the guard — protected screens still require login.
    testWidgets('logged-out user is still bounced from /shelf to login', (
      tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(mockAuth, authStateController);
      final router = await pumpApp(tester);
      router.go('/shelf');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(BookshelfScreen), findsNothing);
    });

    // BUSINESS LOGIC: This is the mid-flow moment the redirect split exists
    // for — the reset code was just verified, so a session now exists, but
    // the user is still on the forgot-password screen choosing their new
    // password. They must stay there, not be yanked to the shelf.
    testWidgets('a session mid-flow does NOT eject the user from the screen', (
      tester,
    ) async {
      TestSetupHelpers.setupLoggedOutUser(mockAuth, authStateController);
      TestSetupHelpers.setupEmptyShelf(mockBookshelf);
      final router = await pumpApp(tester);
      router.go('/forgot-password');
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);

      // Simulate verifyOTP succeeding: a session appears and the auth
      // stream fires, which re-runs the router's redirect rules.
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuth,
        mockBookshelf,
        [],
        authStateController,
      );
      await tester.pumpAndSettle();

      // Still on the forgot-password screen — the flow was not interrupted.
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(find.byType(BookshelfScreen), findsNothing);
    });

    // BUSINESS LOGIC: The old behavior must survive for login/signup — a
    // logged-in user visiting /login is still sent to their shelf.
    testWidgets('logged-in user is still bounced from /login to the shelf', (
      tester,
    ) async {
      TestSetupHelpers.setupLoggedInUserWithBooks(
        mockAuth,
        mockBookshelf,
        [],
        authStateController,
      );
      final router = await pumpApp(tester);
      router.go('/login');
      await tester.pumpAndSettle();

      expect(find.byType(BookshelfScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

