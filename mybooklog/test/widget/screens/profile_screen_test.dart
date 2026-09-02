/// Widget tests for [ProfileScreen].
///
/// BUSINESS LOGIC:
/// This screen is where a user edits their name, changes their password
/// (only after re-proving they know the current one), or permanently
/// deletes their account. These tests verify: the loaded fields populate
/// correctly, saving calls the repository, a wrong current password blocks
/// the change with an inline error instead of ever calling updatePassword,
/// and the delete confirmation dialog states plainly that deletion is final
/// and cannot be undone — Cancel must not delete, Delete must call through.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/profile_repository.dart';
import 'package:mybooklog/src/features/profile/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../unit/mocks/mock_repositories.dart';

/// Pumps the screen with mocked repositories inside a plain MaterialApp.
Future<void> _pumpScreen(
  WidgetTester tester, {
  required MockAuthRepository mockAuth,
  required MockProfileRepository mockProfile,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: mockAuth),
        Provider<ProfileRepository>.value(value: mockProfile),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthRepository mockAuth;
  late MockProfileRepository mockProfile;

  setUp(() {
    mockAuth = MockAuthRepository();
    mockProfile = MockProfileRepository();
    RepositorySetupHelpers.setupSuccessfulFetchProfile(
      mockProfile,
      profile: TestProfileFactory.createTestProfile(
        username: 'jane@example.com',
        firstName: 'Jane',
        lastName: 'Doe',
      ),
    );
  });

  group('ProfileScreen — loading profile details', () {
    testWidgets('populates fields from the fetched profile', (tester) async {
      await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'First Name'), findsOneWidget);
      final firstNameField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'First Name'),
      );
      expect(firstNameField.controller?.text, 'Jane');
    });
  });

  group('ProfileScreen — saving profile details', () {
    testWidgets('Save Changes calls updateProfile with the edited names', (
      tester,
    ) async {
      when(
        () => mockProfile.updateProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async {});
      await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'First Name'),
        'Janet',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(
        () => mockProfile.updateProfile(firstName: 'Janet', lastName: 'Doe'),
      ).called(1);
    });
  });

  group('ProfileScreen — changing password', () {
    Future<void> fillPasswordForm(
      WidgetTester tester, {
      required String current,
      required String next,
      String? confirm,
    }) async {
      await tester.ensureVisible(
        find.widgetWithText(TextFormField, 'Current Password'),
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current Password'),
        current,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New Password'),
        next,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm New Password'),
        confirm ?? next,
      );
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'wrong current password blocks the change and shows an inline error',
      (tester) async {
        when(
          () => mockAuth.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('Invalid login credentials'));
        await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

        await fillPasswordForm(
          tester,
          current: 'WrongPass1!',
          next: 'NewPass1!',
        );

        expect(find.text('Current password is incorrect.'), findsOneWidget);
        verifyNever(
          () => mockAuth.updatePassword(newPassword: any(named: 'newPassword')),
        );
      },
    );

    testWidgets(
      'correct current password + valid new password calls updatePassword',
      (tester) async {
        when(
          () => mockAuth.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockAuth.updatePassword(newPassword: any(named: 'newPassword')),
        ).thenAnswer((_) async {});
        await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

        await fillPasswordForm(
          tester,
          current: 'CorrectPass1!',
          next: 'NewPass1!',
        );

        verify(
          () => mockAuth.signIn(
            email: 'jane@example.com',
            password: 'CorrectPass1!',
          ),
        ).called(1);
        verify(
          () => mockAuth.updatePassword(newPassword: 'NewPass1!'),
        ).called(1);
      },
    );
  });

  group('ProfileScreen — deleting the account', () {
    testWidgets('delete dialog states the deletion is final', (tester) async {
      await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('final and cannot be undone'), findsOneWidget);
    });

    testWidgets('Cancel does not delete the account', (tester) async {
      await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockProfile.deleteAccount());
    });

    testWidgets('confirming Delete calls deleteAccount', (tester) async {
      when(() => mockProfile.deleteAccount()).thenAnswer((_) async {});
      await _pumpScreen(tester, mockAuth: mockAuth, mockProfile: mockProfile);

      await tester.ensureVisible(find.text('Delete Account'));
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      // Not pumpAndSettle: on success the screen has no router here to
      // navigate away, so it's left showing an indeterminate spinner
      // (_deleting stays true) that would animate forever.
      await tester.pump();
      await tester.pump();

      verify(() => mockProfile.deleteAccount()).called(1);
    });
  });
}
