import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/features/auth/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

// BUSINESS LOGIC:
// The forgot-password screen is a two-stage flow: ask for an email and send
// a 6-digit code, then collect the code plus a new password. These tests
// verify the behaviors that matter to users and to security:
//  - the email typed on the login screen arrives pre-filled
//  - the "code sent" message never reveals whether an account exists
//  - the code and new password are validated before any server call
//  - wrong/expired codes show a friendly error and allow retry
//  - the Resend link honors a visible 60-second cooldown
//  - a retry after a mid-flow failure does not re-verify the used-up code
//
// TECHNICAL:
// AuthRepository is a mocktail mock. Tests that reach stage 2 start a real
// 60-second countdown Timer, so each test ends by pumping an empty widget
// (disposing the screen cancels the timer) or by advancing fake time.

class MockAuthRepository extends Mock implements AuthRepository {}

/// Pumps the screen with a mocked AuthRepository inside a plain MaterialApp.
Future<MockAuthRepository> _pumpScreen(
  WidgetTester tester, {
  String? initialEmail,
}) async {
  final mockAuth = MockAuthRepository();
  await tester.pumpWidget(
    Provider<AuthRepository>.value(
      value: mockAuth,
      child: MaterialApp(
        home: ForgotPasswordScreen(initialEmail: initialEmail),
      ),
    ),
  );
  return mockAuth;
}

/// Stubs a successful "send code" call.
void _stubSendCodeSuccess(MockAuthRepository mockAuth) {
  when(
    () => mockAuth.requestPasswordReset(email: any(named: 'email')),
  ).thenAnswer((_) async {});
}

/// Drives the screen from stage 1 to stage 2 (code + password entry).
Future<void> _advanceToStage2(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'user@example.com');
  await tester.tap(find.text('Send code'));
  await tester.pumpAndSettle();
}

/// Fills stage 2's three fields: code, new password, confirmation.
Future<void> _fillStage2(
  WidgetTester tester, {
  String code = '123456',
  String password = 'NewPass1!',
  String? confirm,
}) async {
  final formFields = find.byType(TextFormField);
  await tester.enterText(formFields.at(0), code);
  await tester.enterText(formFields.at(1), password);
  await tester.enterText(formFields.at(2), confirm ?? password);
}

/// Disposes the screen so its countdown timer is cancelled; without this,
/// flutter_test fails the test for a still-pending Timer.
Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  group('ForgotPasswordScreen — stage 1 (request code)', () {
    // BUSINESS LOGIC: The email typed on the login screen must carry over so
    // the user never types it twice.
    testWidgets('pre-fills the email passed from the login screen', (
      tester,
    ) async {
      await _pumpScreen(tester, initialEmail: 'typed@example.com');
      expect(find.text('typed@example.com'), findsOneWidget);
    });

    // BUSINESS LOGIC: An empty email is caught locally — no server call.
    testWidgets('shows an error and calls nothing when email is empty', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      await tester.tap(find.text('Send code'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      verifyNever(
        () => mockAuth.requestPasswordReset(email: any(named: 'email')),
      );
    });

    // BUSINESS LOGIC: After sending, the confirmation is deliberately vague
    // ("If an account exists...") so the form cannot be used to discover
    // which emails have accounts. The same message appears for existing and
    // non-existing accounts because the repository call succeeds either way.
    testWidgets(
      'advances to code entry with the no-account-enumeration message',
      (tester) async {
        final mockAuth = await _pumpScreen(tester);
        _stubSendCodeSuccess(mockAuth);

        await _advanceToStage2(tester);

        expect(
          find.textContaining('If an account exists for that email'),
          findsOneWidget,
        );
        expect(find.text('6-digit code'), findsOneWidget);
        expect(find.text('New password'), findsOneWidget);
        expect(find.text('Confirm new password'), findsOneWidget);
        verify(
          () => mockAuth.requestPasswordReset(email: 'user@example.com'),
        ).called(1);

        await _disposeScreen(tester);
      },
    );

    // BUSINESS LOGIC: If the send fails (no internet, throttled), the user
    // stays on the email stage with a friendly explanation.
    testWidgets('stays on stage 1 with a friendly error when send fails', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      when(
        () => mockAuth.requestPasswordReset(email: any(named: 'email')),
      ).thenThrow(Exception('socket error'));

      await _advanceToStage2(tester);

      expect(
        find.text('Something went wrong. Please check your connection and retry.'),
        findsOneWidget,
      );
      expect(find.text('6-digit code'), findsNothing); // still stage 1
    });
  });

  group('ForgotPasswordScreen — stage 2 (code + new password)', () {
    // BUSINESS LOGIC: Obvious mistakes are caught before any server call:
    // short code, weak password, mismatched confirmation.
    testWidgets('rejects a short code before calling the server', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      await _advanceToStage2(tester);

      await _fillStage2(tester, code: '123');
      await tester.tap(find.text('Reset password'));
      await tester.pump();

      expect(
        find.text('Enter the 6-digit code from the email.'),
        findsOneWidget,
      );
      verifyNever(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      );
      await _disposeScreen(tester);
    });

    // BUSINESS LOGIC: The new password obeys the exact same strength rules
    // as signup — one standard everywhere.
    testWidgets('rejects a weak password with the signup rule message', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      await _advanceToStage2(tester);

      await _fillStage2(tester, password: 'weakpassword', confirm: 'weakpassword');
      await tester.tap(find.text('Reset password'));
      await tester.pump();

      expect(
        find.text(
          'Password must have at least 1 letter, 1 number, and 1 special character.',
        ),
        findsOneWidget,
      );
      verifyNever(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      );
      await _disposeScreen(tester);
    });

    testWidgets('rejects mismatched password confirmation', (tester) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      await _advanceToStage2(tester);

      await _fillStage2(tester, password: 'NewPass1!', confirm: 'Different1!');
      await tester.tap(find.text('Reset password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      verifyNever(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      );
      await _disposeScreen(tester);
    });

    // BUSINESS LOGIC: A wrong or expired code is the most common failure.
    // The user stays put (typed passwords intact) with a clear explanation,
    // and the password is never touched.
    testWidgets('shows friendly error for a wrong code, does not update', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      when(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenThrow(const AuthException('Token has expired or is invalid'));
      await _advanceToStage2(tester);

      await _fillStage2(tester);
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('That code is incorrect or has expired.'),
        findsOneWidget,
      );
      verifyNever(
        () => mockAuth.updatePassword(newPassword: any(named: 'newPassword')),
      );
      await _disposeScreen(tester);
    });

    // BUSINESS LOGIC: If the code was accepted but the password save failed
    // (network blip between the two calls), pressing the button again must
    // NOT re-send the now-used-up code — only the password save is retried.
    testWidgets('retry after a failed save skips re-verifying the code', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      when(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async {});
      // First save fails, second succeeds.
      var saveAttempts = 0;
      when(
        () => mockAuth.updatePassword(newPassword: any(named: 'newPassword')),
      ).thenAnswer((_) async {
        saveAttempts++;
        if (saveAttempts == 1) throw Exception('network blip');
      });
      await _advanceToStage2(tester);
      await _fillStage2(tester);

      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      // The code was verified exactly once across both attempts.
      verify(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).called(1);
      expect(saveAttempts, 2);
      await _disposeScreen(tester);
    });
  });

  group('ForgotPasswordScreen — resend cooldown', () {
    // BUSINESS LOGIC: The server allows one reset email per 60 seconds.
    // Rather than letting a tap silently fail, the Resend link shows a
    // countdown and only becomes tappable when the server would accept.
    testWidgets('disables Resend for 60 seconds, then re-enables it', (
      tester,
    ) async {
      final mockAuth = await _pumpScreen(tester);
      _stubSendCodeSuccess(mockAuth);
      await _advanceToStage2(tester);

      // Right after sending: disabled, counting down from 60.
      final countdownButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Resend code (60s)'),
      );
      expect(countdownButton.onPressed, isNull);

      // Advance past the cooldown: the plain "Resend code" label returns
      // and the button is live again.
      await tester.pump(const Duration(seconds: 61));
      final liveButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Resend code'),
      );
      expect(liveButton.onPressed, isNotNull);

      // Tapping it requests a second code (2 calls total).
      await tester.tap(find.text('Resend code'));
      await tester.pumpAndSettle();
      verify(
        () => mockAuth.requestPasswordReset(email: any(named: 'email')),
      ).called(2);

      await _disposeScreen(tester);
    });
  });

  group('ForgotPasswordScreen — successful reset', () {
    // BUSINESS LOGIC: The happy path end-to-end: code accepted, password
    // saved, confirmation shown, and the user lands on their shelf signed
    // in — no redundant "now log in again" step.
    testWidgets('verifies code, saves password, confirms, goes to shelf', (
      tester,
    ) async {
      final mockAuth = MockAuthRepository();
      _stubSendCodeSuccess(mockAuth);
      when(
        () => mockAuth.verifyRecoveryCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockAuth.updatePassword(newPassword: any(named: 'newPassword')),
      ).thenAnswer((_) async {});

      // A minimal router: the screen under test plus a stand-in shelf, so
      // the final context.go('/shelf') has somewhere real to land.
      final router = GoRouter(
        initialLocation: '/forgot-password',
        routes: [
          GoRoute(
            path: '/forgot-password',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: '/shelf',
            builder: (_, _) =>
                const Scaffold(body: Center(child: Text('SHELF-DESTINATION'))),
          ),
        ],
      );
      await tester.pumpWidget(
        Provider<AuthRepository>.value(
          value: mockAuth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await _advanceToStage2(tester);
      await _fillStage2(tester);
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      // Both server calls happened, in the right shape.
      verify(
        () => mockAuth.verifyRecoveryCode(
          email: 'user@example.com',
          code: '123456',
        ),
      ).called(1);
      verify(
        () => mockAuth.updatePassword(newPassword: 'NewPass1!'),
      ).called(1);
      // The user was told, and moved to the shelf.
      expect(find.text('Your password has been updated.'), findsOneWidget);
      expect(find.text('SHELF-DESTINATION'), findsOneWidget);

      await _disposeScreen(tester);
    });
  });
}
