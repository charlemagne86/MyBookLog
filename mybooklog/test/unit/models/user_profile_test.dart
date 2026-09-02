/// Unit tests for [UserProfile] model.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    group('fromRow', () {
      test('parses a full database row correctly', () {
        final row = {
          'id': 'user-123',
          'username': 'jane@example.com',
          'first_name': 'Jane',
          'last_name': 'Doe',
        };

        final result = UserProfile.fromRow(row);

        expect(result.id, 'user-123');
        expect(result.username, 'jane@example.com');
        expect(result.firstName, 'Jane');
        expect(result.lastName, 'Doe');
      });

      test('handles missing name fields gracefully', () {
        final row = {'id': 'user-123', 'username': 'jane@example.com'};

        final result = UserProfile.fromRow(row);

        expect(result.firstName, isNull);
        expect(result.lastName, isNull);
      });

      test('handles a missing username gracefully', () {
        final row = {'id': 'user-123'};

        final result = UserProfile.fromRow(row);

        expect(result.username, '');
      });
    });

    group('displayName', () {
      test('joins first and last name when both are present', () {
        const profile = UserProfile(
          id: 'user-123',
          username: 'jane@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
        );

        expect(profile.displayName, 'Jane Doe');
      });

      test('falls back to whichever name is present', () {
        const profile = UserProfile(
          id: 'user-123',
          username: 'jane@example.com',
          firstName: 'Jane',
        );

        expect(profile.displayName, 'Jane');
      });

      test('falls back to username when no names are present', () {
        const profile = UserProfile(
          id: 'user-123',
          username: 'jane@example.com',
        );

        expect(profile.displayName, 'jane@example.com');
      });
    });

    group('copyWith', () {
      test('overrides only the given fields', () {
        const profile = UserProfile(
          id: 'user-123',
          username: 'jane@example.com',
          firstName: 'Jane',
          lastName: 'Doe',
        );

        final updated = profile.copyWith(firstName: 'Janet');

        expect(updated.firstName, 'Janet');
        expect(updated.lastName, 'Doe');
        expect(updated.id, 'user-123');
        expect(updated.username, 'jane@example.com');
      });
    });
  });
}
