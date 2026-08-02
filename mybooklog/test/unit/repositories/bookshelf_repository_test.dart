/// Unit tests for [BookshelfRepository].
///
/// BUSINESS LOGIC:
/// The bookshelf repository is the only gateway between the app and the
/// user's shelf data. If it filters by the wrong user, drops the catalog
/// join, or misreads the "already on shelf" flag, users see someone else's
/// books, blank titles, or silent duplicate adds. These tests pin down that
/// behavior without touching a real database.
///
/// TECHNICAL IMPLEMENTATION:
/// Supabase query builders (`from().select().eq()` chains and `rpc()`)
/// implement `Future<T>`, which mocktail cannot stub cleanly. Instead we use
/// small hand-rolled fakes that:
/// 1. Record every filter (`eq`) and payload (`update`) they receive
/// 2. Complete with a canned result — or a canned error — when awaited
/// This lets each test assert both WHAT was asked of the database and HOW
/// the repository translates the answer.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

/// Fake query/filter builder that records the filters applied to it and,
/// when awaited, completes with [result] (or throws [error] if set).
///
/// One fake plays every role in the chain: `eq` returns `this`, so
/// `.eq('a', 1).eq('b', 2)` accumulates into [eqCalls] and the final await
/// resolves through [then] — exactly how the real builder behaves.
class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  FakeFilterBuilder({this.result, this.error});

  final T? result;
  final Object? error;

  /// Every eq() filter applied, as 'column=value' strings, in call order.
  final List<String> eqCalls = [];

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    eqCalls.add('$column=$value');
    return this;
  }

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

/// Fake table handle (`client.from('bookshelf_items')`) that hands out
/// pre-configured [FakeFilterBuilder]s and records what select()/update()
/// were called with.
// The SDK marks builders immutable; this fake deliberately mutates two
// recording fields so tests can assert what the repository asked for.
// ignore: must_be_immutable
class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  FakeQueryBuilder({
    FakeFilterBuilder<PostgrestList>? selectBuilder,
    FakeFilterBuilder<dynamic>? mutateBuilder,
  }) : selectBuilder = selectBuilder ?? FakeFilterBuilder(result: []),
       mutateBuilder = mutateBuilder ?? FakeFilterBuilder(result: null);

  final FakeFilterBuilder<PostgrestList> selectBuilder;
  final FakeFilterBuilder<dynamic> mutateBuilder;

  String? selectedColumns;
  Map<dynamic, dynamic>? updatePayload;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String columns = '*']) {
    selectedColumns = columns;
    return selectBuilder;
  }

  @override
  PostgrestFilterBuilder<dynamic> delete() => mutateBuilder;

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
  late BookshelfRepository repository;

  /// Wires the mock auth chain so the repository sees a logged-in user.
  void logIn() {
    final user = MockUser();
    when(() => user.id).thenReturn(testUserId);
    when(() => auth.currentUser).thenReturn(user);
  }

  /// Simulates a signed-out session (currentUser == null).
  void logOut() => when(() => auth.currentUser).thenReturn(null);

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    when(() => client.auth).thenReturn(auth);
    repository = BookshelfRepository(client);
    logIn();
  });

  group('BookshelfRepository', () {
    group('fetchShelf', () {
      // A realistic joined row: shelf entry + nested catalog record, the
      // shape produced by `select('*, books_catalog(...)')`.
      final joinedRows = [
        {
          'book_id': 42,
          'is_read': true,
          'books_catalog': {
            'id': 42,
            'title': 'The Great Gatsby',
            'author': 'F. Scott Fitzgerald',
            'thumbnail_uri': 'http://example.com/gatsby.jpg',
          },
        },
        {
          'book_id': 43,
          'is_read': false,
          'books_catalog': {
            'id': 43,
            'title': 'To Kill a Mockingbird',
            'author': 'Harper Lee',
            'thumbnail_uri': null,
          },
        },
      ];

      test('returns typed ShelfBooks parsed from joined rows', () async {
        final table = FakeQueryBuilder(
          selectBuilder: FakeFilterBuilder(result: joinedRows),
        );
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        final shelf = await repository.fetchShelf();

        expect(shelf, hasLength(2));
        expect(shelf[0].bookId, '42');
        expect(shelf[0].title, 'The Great Gatsby');
        expect(shelf[0].isRead, isTrue);
        // Insecure http:// covers are upgraded to https:// during parsing.
        expect(shelf[0].thumbnailUri, startsWith('https://'));
        expect(shelf[1].author, 'Harper Lee');
        expect(shelf[1].isRead, isFalse);
      });

      test('fetches shelf and catalog data in one joined query', () async {
        final table = FakeQueryBuilder(
          selectBuilder: FakeFilterBuilder(result: joinedRows),
        );
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await repository.fetchShelf();

        // The join is the PERF-1 guarantee: one request, not N+1.
        expect(
          table.selectedColumns,
          '*, books_catalog(id, title, author, thumbnail_uri)',
        );
      });

      test('only asks for the logged-in user\'s shelf', () async {
        final table = FakeQueryBuilder(
          selectBuilder: FakeFilterBuilder(result: joinedRows),
        );
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await repository.fetchShelf();

        expect(table.selectBuilder.eqCalls, ['bookshelf_user_id=$testUserId']);
      });

      test('returns an empty list for an empty shelf', () async {
        when(() => client.from('bookshelf_items')).thenAnswer(
          (_) => FakeQueryBuilder(selectBuilder: FakeFilterBuilder(result: [])),
        );

        expect(await repository.fetchShelf(), isEmpty);
      });

      test('throws NotAuthenticatedException when signed out', () async {
        logOut();
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        // The guard fires while the query chain is still being built (the
        // uid is the eq() argument), so the request is never executed:
        // no user filter is ever applied.
        await expectLater(
          () => repository.fetchShelf(),
          throwsA(isA<NotAuthenticatedException>()),
        );
        expect(table.selectBuilder.eqCalls, isEmpty);
      });

      test('propagates server errors to the caller', () async {
        when(() => client.from('bookshelf_items')).thenAnswer(
          (_) => FakeQueryBuilder(
            selectBuilder: FakeFilterBuilder(
              error: const PostgrestException(message: 'connection refused'),
            ),
          ),
        );

        expect(
          () => repository.fetchShelf(),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('addBook', () {
      // Stubs the atomic server-side RPC with a canned response or error.
      void stubRpc({dynamic result, Object? error}) {
        when(
          () => client.rpc<dynamic>(
            'add_book_to_shelf',
            params: any(named: 'params'),
          ),
        ).thenAnswer(
          (_) => FakeFilterBuilder<dynamic>(result: result, error: error),
        );
      }

      test('returns true when the book was already on the shelf', () async {
        stubRpc(result: {'already_on_shelf': true});

        final alreadyThere = await repository.addBook(
          isbn: '9780743273565',
          title: 'The Great Gatsby',
          author: 'F. Scott Fitzgerald',
          thumbnail: 'https://example.com/gatsby.jpg',
        );

        expect(alreadyThere, isTrue);
      });

      test('returns false when the book is newly added', () async {
        stubRpc(result: {'already_on_shelf': false, 'book_id': 42});

        final alreadyThere = await repository.addBook(
          isbn: '9780061120084',
          title: 'To Kill a Mockingbird',
          author: 'Harper Lee',
          thumbnail: null,
        );

        expect(alreadyThere, isFalse);
      });

      test('treats a missing or non-map RPC result as "newly added"', () async {
        // Defensive parsing: an unexpected response shape must not be read
        // as a duplicate (which would suppress the add in the UI).
        for (final odd in [null, 'ok', 42, []]) {
          stubRpc(result: odd);
          expect(
            await repository.addBook(
              isbn: '1',
              title: 't',
              author: 'a',
              thumbnail: null,
            ),
            isFalse,
          );
        }
      });

      test('sends every book field to the atomic RPC', () async {
        stubRpc(result: {'already_on_shelf': false});

        await repository.addBook(
          isbn: '9780743273565',
          title: 'The Great Gatsby',
          author: 'F. Scott Fitzgerald',
          thumbnail: 'https://example.com/gatsby.jpg',
        );

        final captured =
            verify(
                  () => client.rpc<dynamic>(
                    'add_book_to_shelf',
                    params: captureAny(named: 'params'),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured, {
          'p_isbn': '9780743273565',
          'p_title': 'The Great Gatsby',
          'p_author': 'F. Scott Fitzgerald',
          'p_thumbnail_uri': 'https://example.com/gatsby.jpg',
        });
      });

      test('propagates RPC failures (e.g. permission denied)', () async {
        stubRpc(error: const PostgrestException(message: 'permission denied'));

        expect(
          () => repository.addBook(
            isbn: '1',
            title: 't',
            author: 'a',
            thumbnail: null,
          ),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('removeBook', () {
      test('deletes only this user\'s link to the book', () async {
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await repository.removeBook('42');

        // Both filters are required: without the user filter a bug here
        // could delete the book off every user's shelf.
        expect(table.mutateBuilder.eqCalls, [
          'bookshelf_user_id=$testUserId',
          'book_id=42',
        ]);
      });

      test('throws NotAuthenticatedException when signed out', () async {
        logOut();
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await expectLater(
          () => repository.removeBook('42'),
          throwsA(isA<NotAuthenticatedException>()),
        );
        // The delete chain was abandoned before any filter was applied,
        // so nothing could reach the database.
        expect(table.mutateBuilder.eqCalls, isEmpty);
      });

      test('propagates server errors during delete', () async {
        when(() => client.from('bookshelf_items')).thenAnswer(
          (_) => FakeQueryBuilder(
            mutateBuilder: FakeFilterBuilder(
              error: const PostgrestException(message: 'row not found'),
            ),
          ),
        );

        expect(
          () => repository.removeBook('42'),
          throwsA(isA<PostgrestException>()),
        );
      });
    });

    group('setReadStatus', () {
      test('marking read stamps today\'s date', () async {
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        final before = DateTime.now();
        await repository.setReadStatus('42', isRead: true);
        final after = DateTime.now();

        expect(table.updatePayload?['is_read'], isTrue);
        // The read date must be "now" (between the timestamps bracketing
        // the call), serialized in ISO form for the database.
        final stamped = DateTime.parse(
          table.updatePayload?['marked_read_on'] as String,
        );
        expect(stamped.isBefore(before), isFalse);
        expect(stamped.isAfter(after), isFalse);
      });

      test('marking unread clears the read date', () async {
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await repository.setReadStatus('42', isRead: false);

        expect(table.updatePayload?['is_read'], isFalse);
        expect(table.updatePayload?['marked_read_on'], isNull);
      });

      test('updates only this user\'s copy of the book', () async {
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await repository.setReadStatus('42', isRead: true);

        expect(table.mutateBuilder.eqCalls, [
          'bookshelf_user_id=$testUserId',
          'book_id=42',
        ]);
      });

      test('throws NotAuthenticatedException when signed out', () async {
        logOut();
        final table = FakeQueryBuilder();
        when(() => client.from('bookshelf_items')).thenAnswer((_) => table);

        await expectLater(
          () => repository.setReadStatus('42', isRead: true),
          throwsA(isA<NotAuthenticatedException>()),
        );
        expect(table.mutateBuilder.eqCalls, isEmpty);
      });

      test('propagates server errors during update', () async {
        when(() => client.from('bookshelf_items')).thenAnswer(
          (_) => FakeQueryBuilder(
            mutateBuilder: FakeFilterBuilder(
              error: const PostgrestException(message: 'timeout'),
            ),
          ),
        );

        expect(
          () => repository.setReadStatus('42', isRead: true),
          throwsA(isA<PostgrestException>()),
        );
      });
    });
  });
}
