import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';

// BUSINESS LOGIC:
// Authentication error messages must be clear, friendly, and actionable.
// Technical error codes from Supabase are confusing for users, so we translate
// them into plain English. Every common error has a friendly message.
//
// TECHNICAL:
// Test the friendlyMessage() static method which converts AuthException
// and other errors into user-friendly messages.

void main() {
  group('AuthRepository.friendlyMessage', () {
    // BUSINESS LOGIC: Invalid login credentials (wrong password or email)
    // TECHNICAL: Supabase auth returns "Invalid login credentials"
    test('translates invalid login credentials to friendly message', () {
      final error = AuthException('Invalid login credentials');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Incorrect email or password.');
    });

    // BUSINESS LOGIC: Invalid credentials (alternate message)
    test('translates invalid credentials to friendly message', () {
      final error = AuthException('Invalid credentials');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Incorrect email or password.');
    });

    // BUSINESS LOGIC: Email not confirmed before login
    test('translates email not confirmed to friendly message', () {
      final error = AuthException('Email not confirmed');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Please confirm your email address before logging in.');
    });

    // BUSINESS LOGIC: Unknown auth error should be passed through unchanged
    test('passes through unknown AuthException message', () {
      final error = AuthException('Some unexpected error');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Some unexpected error');
    });

    // BUSINESS LOGIC: Non-auth errors (network, etc) get generic message
    test('translates generic exceptions to connection error message', () {
      final error = Exception('Socket exception: Connection refused');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Something went wrong. Please check your connection and retry.');
    });

    // BUSINESS LOGIC: Network error string should trigger generic message
    test('translates network error to connection error message', () {
      final error = Exception('Failed host lookup');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Something went wrong. Please check your connection and retry.');
    });

    // BUSINESS LOGIC: Case-insensitive error matching (user input varies)
    test('performs case-insensitive error matching for invalid login', () {
      final error = AuthException('INVALID LOGIN CREDENTIALS');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Incorrect email or password.');
    });

    // BUSINESS LOGIC: Case-insensitive error matching for email confirmation
    test('performs case-insensitive error matching for email not confirmed', () {
      final error = AuthException('EMAIL NOT CONFIRMED');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Please confirm your email address before logging in.');
    });

    // BUSINESS LOGIC: Multiple auth errors - both conditions could match
    test('prioritizes invalid login check over others', () {
      final error = AuthException('Invalid login credentials with email confirmation');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Incorrect email or password.');
    });

    // BUSINESS LOGIC: Partial matches for error messages
    test('matches partial email not confirmed message', () {
      final error = AuthException('ERROR: email not confirmed by admin');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Please confirm your email address before logging in.');
    });

    // BUSINESS LOGIC: Server error messages
    test('passes through generic server errors unchanged', () {
      final error = AuthException('Internal Server Error (500)');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Internal Server Error (500)');
    });

    // BUSINESS LOGIC: User not found error
    test('passes through user not found error', () {
      final error = AuthException('User not found');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'User not found');
    });

    // BUSINESS LOGIC: Empty error message
    test('handles empty auth exception message', () {
      final error = AuthException('');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, '');
    });

    // BUSINESS LOGIC: Various generic exceptions
    test('handles String error type', () {
      const error = 'Some string error';
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Something went wrong. Please check your connection and retry.');
    });

    // BUSINESS LOGIC: Multiple error types
    test('handles FormatException (malformed data)', () {
      final error = FormatException('Invalid JSON response');
      final friendly = AuthRepository.friendlyMessage(error);
      expect(friendly, 'Something went wrong. Please check your connection and retry.');
    });
  });
}
