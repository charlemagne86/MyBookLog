/// Unit tests for [ProfileRepository].
///
/// TECHNICAL IMPLEMENTATION:
/// Same hand-rolled-fake approach as bookshelf_repository_test.dart: real
/// Supabase query builders implement `Future<T>` in a way mocktail can't
/// stub directly, so small fakes record what was asked and complete with a
/// canned result (or error) when awaited.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/data/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

/// Fake query/filter builder that records the eq() filters applied to it
/// and, when awaited, completes with [result] (or throws [error] if set).
/// [singleResult]/[singleError] back a subsequent single() call, which the
/// real SDK types as PostgrestMap regardless of this builder's own T.
class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder({
    this.result,
    this.error,
    this.singleResult,
    this.singleError,
  });

  final T? result;
  final Object? error;
  final PostgrestMap? singleResult;
  final Object? singleError;

  final List<String> eqCalls = [];

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    eqCalls.add('$column=$value');
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestMap> single() =>
      FakeFilterBuilder<PostgrestMap>(
        result: singleResult,
        error: singleError,
      );

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) {
    final future = error != null
        ? Future<T>.error(error!)
        : Future<T>.value(result as T);
    return future.then(onValue, onError: onError);
  }
}

// The SDK marks builders immutable; this fake deliberately mutates a
// recording field so tests can assert what the repository asked for.
// ignore: must_be_immutable
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder({
    FakeFilterBuilder<PostgrestList>? selectBuilder,
    FakeFilterBuilder<dynamic>? mutateBuilder,
  }) : selectBuilder = selectBuilder ?? FakeFilterBuilder(result: []),
       mutateBuilder = mutateBuilder ?? FakeFilterBuilder(result: null);

  final FakeFilterBuilder<PostgrestList> selectBuilder;
  final FakeFilterBuilder<dynamic> mutateBuilder;

  Map<dynamic, dynamic>? updatePayload;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) =>
      selectBuilder;

  @override
  PostgrestFilterBuilder<dynamic> update(Map<dynamic, dynamic> values) {
    updatePayload = values;
    return mutateBuilder;
  }
}

void main() {
  const testUserId = 'user-123';

  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late ProfileRepository repository;

  void logIn() {
    final user = MockUser();
    when(() => user.id).thenReturn(testUserId);
    when(() => auth.currentUser).thenReturn(user);
  }

  void logOut() => when(() => auth.currentUser).thenReturn(null);

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    repository = ProfileRepository(client);
    logIn();
  });

  group('ProfileRepository', () {
    group('fetchProfile', () {
      test('returns a typed UserProfile parsed from the row', () async {
        final table = FakeQueryBuilder(
          selectBuilder: FakeFilterBuilder(
            singleResult: {
              'id': testUserId,
              'username': 'jane@example.com',
              'first_name': 'Jane',
              'last_name': 'Doe',
            },
          ),
        );
        when(() => client.from('users')).thenAnswer((_) => table);

        final profile = await repository.fetchProfile();

        expect(profile.id, testUserId);
        expect(profile.username, 'jane@example.com');
        expect(profile.firstName, 'Jane');
        expect(profile.lastName, 'Doe');
      });

      test('filters by the signed-in user\'s id', () async {
        final table = FakeQueryBuilder(
          selectBuilder: FakeFilterBuilder(
            singleResult: {'id': testUserId},
          ),
        );
        when(() => client.from('users')).thenAnswer((_) => table);

        await repository.fetchProfile();

        expect(table.selectBuilder.eqCalls, ['id=$testUserId']);
      });

      test('throws NotAuthenticatedException when nobody is logged in', () async {
        logOut();
        final table = FakeQueryBuilder();
        when(() => client.from('users')).thenAnswer((_) => table);

        // The guard fires while the query chain is still being built (the
        // uid is the eq() argument), so the request is never executed.
        await expectLater(
          () => repository.fetchProfile(),
          throwsA(isA<NotAuthenticatedException>()),
        );
        expect(table.selectBuilder.eqCalls, isEmpty);
      });
    });

    group('updateProfile', () {
      test('sends trimmed first and last name for the signed-in user', () async {
        final table = FakeQueryBuilder();
        when(() => client.from('users')).thenAnswer((_) => table);

        await repository.updateProfile(
          firstName: '  Jane  ',
          lastName: '  Doe  ',
        );

        expect(table.updatePayload, {'first_name': 'Jane', 'last_name': 'Doe'});
        expect(table.mutateBuilder.eqCalls, ['id=$testUserId']);
      });

      test('throws NotAuthenticatedException when nobody is logged in', () async {
        logOut();
        final table = FakeQueryBuilder();
        when(() => client.from('users')).thenAnswer((_) => table);

        await expectLater(
          () => repository.updateProfile(firstName: 'Jane', lastName: 'Doe'),
          throwsA(isA<NotAuthenticatedException>()),
        );
        expect(table.mutateBuilder.eqCalls, isEmpty);
      });
    });

    group('deleteAccount', () {
      test('calls the delete_own_account RPC then signs out', () async {
        when(
          () => client.rpc<dynamic>('delete_own_account'),
        ).thenAnswer((_) => FakeFilterBuilder<dynamic>(result: null));
        when(() => auth.signOut()).thenAnswer((_) async {});

        await repository.deleteAccount();

        verify(() => client.rpc<dynamic>('delete_own_account')).called(1);
        verify(() => auth.signOut()).called(1);
      });

      test('does not sign out when the RPC fails', () async {
        when(
          () => client.rpc<dynamic>('delete_own_account'),
        ).thenAnswer(
          (_) => FakeFilterBuilder<dynamic>(
            error: PostgrestException(message: 'not authenticated'),
          ),
        );

        await expectLater(
          () => repository.deleteAccount(),
          throwsA(isA<PostgrestException>()),
        );
        verifyNever(() => auth.signOut());
      });
    });
  });
}
