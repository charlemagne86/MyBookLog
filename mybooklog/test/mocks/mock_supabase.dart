import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// BUSINESS LOGIC:
// Supabase client provides database access. Mock it to test repository logic
// without hitting real database.

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuthClient extends Mock implements GoTrueClient {}

class MockRealtimeClient extends Mock implements RealtimeClient {}

class MockStorageClient extends Mock implements SupabaseStorageClient {}

class MockPostgrestQueryBuilder extends Mock
    implements PostgrestQueryBuilder<dynamic> {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

class MockPostgrestTransformBuilder extends Mock
    implements PostgrestTransformBuilder<dynamic> {}
