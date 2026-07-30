/// Mock implementations of repositories for testing.
///
/// Use these mocks in widget and integration tests where you need to
/// control the behavior of data layers without hitting the real Supabase.

import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================================
// Mock Repositories
// ============================================================================

/// Mock [AuthRepository] for testing auth flows without network.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Mock [BookshelfRepository] for testing bookshelf operations.
class MockBookshelfRepository extends Mock implements BookshelfRepository {}

// ============================================================================
// Mock Supabase Components
// ============================================================================

/// Mock [SupabaseClient] to replace the real database client.
class MockSupabaseClient extends Mock implements SupabaseClient {}

/// Mock [PostgrestFilterBuilder] for query builder testing.
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

/// Mock [SupabaseQueryBuilder] for starting queries.
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// ============================================================================
// Mock Session & User (use Mock directly to avoid SDK interface changes)
// ============================================================================

/// Mock [Session] using mocktail's Mock (handles interface changes automatically)
class MockSession extends Mock implements Session {}

/// Mock [User] using mocktail's Mock (handles interface changes automatically)
class MockUser extends Mock implements User {}

// ============================================================================
// Setup Helpers
// ============================================================================

/// Configure [MockSupabaseClient] for typical auth scenarios.
void setupMockAuthSuccess(
  MockSupabaseClient mockClient, {
  String userId = 'user-123',
  String email = 'test@example.com',
}) {
  final mockUser = MockUser();
  when(() => mockUser.id).thenReturn(userId);
  when(() => mockUser.email).thenReturn(email);

  final mockSession = MockSession();
  when(() => mockSession.user).thenReturn(mockUser);
  when(() => mockSession.accessToken).thenReturn('test-token');

  when(() => mockClient.auth.currentUser).thenReturn(mockUser);
  when(() => mockClient.auth.currentSession).thenReturn(mockSession);
  when(() => mockClient.auth.onAuthStateChange).thenAnswer(
    (_) => Stream.value(AuthState(AuthChangeEvent.signedIn, mockSession)),
  );
}

/// Configure [MockSupabaseClient] for auth failure scenarios.
void setupMockAuthFailure(MockSupabaseClient mockClient) {
  when(() => mockClient.auth.currentUser).thenReturn(null);
  when(() => mockClient.auth.currentSession).thenReturn(null);
  when(
    () => mockClient.auth.onAuthStateChange,
  ).thenAnswer((_) => Stream.value(AuthState(AuthChangeEvent.signedOut, null)));
}
