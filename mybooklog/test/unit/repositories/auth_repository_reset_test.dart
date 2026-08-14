import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../mocks/mock_supabase.dart';

// BUSINESS LOGIC:
// "Forgot password" is a three-step conversation with the server: request a
// 6-digit code by email, prove ownership by typing the code back, then save
// a new password. These tests verify AuthRepository relays each step to
// Supabase correctly (right method, right arguments, typos trimmed) and that
// server errors surface as friendly, actionable messages.
//
// TECHNICAL:
// The Supabase client and its auth sub-client are mocktail mocks, so no
// network is involved. Named-argument capture verifies exact values sent.

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUserResponse extends Mock implements UserResponse {}

void main() {
  late MockSupabaseClient client;
  late MockAuthClient authClient;
  late AuthRepository repo;

  setUpAll(() {
    // Fallback values let mocktail's any()/captureAny() stand in for these
    // non-primitive argument types.
    registerFallbackValue(OtpType.recovery);
    registerFallbackValue(UserAttributes());
  });

  setUp(() {
    client = MockSupabaseClient();
    authClient = MockAuthClient();
    when(() => client.auth).thenReturn(authClient);
    repo = AuthRepository(client);
  });

  group('AuthRepository.requestPasswordReset', () {
    // BUSINESS LOGIC: Step 1 sends the code email via Supabase.
    test('calls resetPasswordForEmail with the given email', () async {
      when(
        () => authClient.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});

      await repo.requestPasswordReset(email: 'user@example.com');

      verify(
        () => authClient.resetPasswordForEmail('user@example.com'),
      ).called(1);
    });

    // BUSINESS LOGIC: Stray spaces around the email are a common typo and
    // must not cause a "no such account" experience.
    test('trims whitespace from the email', () async {
      when(
        () => authClient.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});

      await repo.requestPasswordReset(email: '  user@example.com  ');

      verify(
        () => authClient.resetPasswordForEmail('user@example.com'),
      ).called(1);
    });

    // BUSINESS LOGIC: Server failures (e.g. rate limits) must reach the
    // screen so the user gets feedback instead of silent nothing.
    test('propagates server errors', () async {
      when(
        () => authClient.resetPasswordForEmail(any()),
      ).thenThrow(const AuthException('email rate limit exceeded'));

      expect(
        () => repo.requestPasswordReset(email: 'user@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthRepository.verifyRecoveryCode', () {
    // BUSINESS LOGIC: Step 2 checks the 6-digit code. It must use the
    // "recovery" code type — the password-reset flavor — not signup or
    // magic-link codes.
    test('verifies the code as a recovery OTP with trimmed inputs', () async {
      when(
        () => authClient.verifyOTP(
          type: any(named: 'type'),
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => MockAuthResponse());

      await repo.verifyRecoveryCode(
        email: ' user@example.com ',
        code: ' 123456 ',
      );

      verify(
        () => authClient.verifyOTP(
          type: OtpType.recovery,
          email: 'user@example.com',
          token: '123456',
        ),
      ).called(1);
    });

    // BUSINESS LOGIC: A wrong or expired code is an expected user mistake;
    // the exception must surface so the screen can explain and offer resend.
    test('propagates invalid/expired code errors', () async {
      when(
        () => authClient.verifyOTP(
          type: any(named: 'type'),
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('Token has expired or is invalid'));

      expect(
        () => repo.verifyRecoveryCode(email: 'user@example.com', code: '000000'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthRepository.updatePassword', () {
    // BUSINESS LOGIC: Step 3 saves the new password on the now-authorized
    // session.
    test('calls updateUser with the new password', () async {
      when(
        () => authClient.updateUser(any()),
      ).thenAnswer((_) async => MockUserResponse());

      await repo.updatePassword(newPassword: 'NewPass1!');

      final captured =
          verify(() => authClient.updateUser(captureAny())).captured;
      expect((captured.single as UserAttributes).password, 'NewPass1!');
    });
  });

  group('AuthRepository.friendlyMessage — password reset errors', () {
    // BUSINESS LOGIC: The server's wording for a bad code is technical
    // ("Token has expired or is invalid"); users see plain English plus the
    // way out (request a new one).
    test('translates expired/invalid token to friendly code message', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException('Token has expired or is invalid'),
      );
      expect(
        friendly,
        'That code is incorrect or has expired. '
        'Check the code or request a new one.',
      );
    });

    test('matches token errors case-insensitively', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException('TOKEN HAS EXPIRED OR IS INVALID'),
      );
      expect(friendly, contains('That code is incorrect or has expired.'));
    });

    // BUSINESS LOGIC: The server throttles repeated reset emails and code
    // attempts; the user should be told to wait, not shown raw server text.
    test('translates email rate limit to friendly wait message', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException('email rate limit exceeded'),
      );
      expect(friendly, 'Too many attempts. Please wait a moment and try again.');
    });

    test('translates "for security purposes" throttle to wait message', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException(
          'For security purposes, you can only request this once every 60 seconds',
        ),
      );
      expect(friendly, 'Too many attempts. Please wait a moment and try again.');
    });

    test('translates "too many requests" to wait message', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException('Too many requests'),
      );
      expect(friendly, 'Too many attempts. Please wait a moment and try again.');
    });

    // BUSINESS LOGIC: The original login errors must keep their translations
    // — the new rules must not shadow them.
    test('keeps invalid login translation ahead of token rules', () {
      final friendly = AuthRepository.friendlyMessage(
        const AuthException('Invalid login credentials'),
      );
      expect(friendly, 'Incorrect email or password.');
    });
  });
}
