import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// BUSINESS LOGIC:
// Supabase client provides database access. Mock it to test repository logic
// without hitting real database. RPC calls need special handling.

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthClient extends Mock implements GoTrueClient {}

class MockRealtimeClient extends Mock implements RealtimeClient {}

class MockStorageClient extends Mock implements SupabaseStorageClient {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

class MockPostgrestTransformBuilder extends Mock implements PostgrestTransformBuilder {}

// TECHNICAL: Helper functions to reduce boilerplate in tests
// These make it easy to stub common Supabase patterns

/// Stub an RPC call that returns a single value
Future<void> mockRpcCall(
  MockSupabaseClient client, {
  required String method,
  required dynamic Function() response,
}) async {
  when(
    () => client.rpc(method),
  ).thenAnswer((_) async => response());
}

/// Stub a query that returns multiple rows
void mockQuerySelect(
  MockSupabaseClient client, {
  required String table,
  required List<Map<String, dynamic>> rows,
}) {
  final mockQuery = MockPostgrestQueryBuilder();
  when(() => client.from(table).select()).thenReturn(mockQuery);
  when(() => mockQuery.execute()).thenAnswer((_) async => rows);
}

/// Stub a query that throws an error
void mockQueryError(
  MockSupabaseClient client, {
  required String table,
  required String errorMessage,
}) {
  final mockQuery = MockPostgrestQueryBuilder();
  when(() => client.from(table).select()).thenReturn(mockQuery);
  when(() => mockQuery.execute()).thenThrow(Exception(errorMessage));
}
