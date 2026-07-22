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

/// Mock [GoTrustClient] (Supabase Auth) for auth testing.
class MockGoTrustClient extends Mock implements GoTrustClient {}

/// Mock [PostgrestFilterBuilder] for query builder testing.
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder {}

/// Mock [PostgrestQueryBuilder] for starting queries.
class MockPostgrestQueryBuilder extends Mock
    implements PostgrestQueryBuilder {}

// ============================================================================
// Mock Authentication Results
// ============================================================================

/// Mock [Session] representing an authenticated user.
class MockSession implements Session {
  MockSession({
    this.accessToken = 'test-access-token',
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
    this.expiresAt,
    this.refreshToken,
    this.user,
  });

  @override
  final String accessToken;

  @override
  final String tokenType;

  @override
  final int expiresIn;

  @override
  final int? expiresAt;

  @override
  final String? refreshToken;

  @override
  final User? user;

  @override
  bool get isExpired => false;

  @override
  DateTime? get persistSessionString => null;

  // Unused in tests
  @override
  set persistSessionString(DateTime? value) {}
}

/// Mock [User] representing an authenticated user account.
class MockUser implements User {
  MockUser({
    this.id = 'user-123',
    this.appMetadata = const {},
    this.userMetadata = const {},
    this.aud = 'authenticated',
    this.confirmationSentAt,
    this.confirmedAt = DateTime(2026, 1, 1),
    this.email = 'test@example.com',
    this.emailConfirmedAt,
    this.phone,
    this.phoneConfirmedAt,
    this.lastSignInAt,
    this.createdAt = DateTime(2026, 1, 1),
    this.updatedAt = DateTime(2026, 1, 1),
    this.identities,
  });

  @override
  final String id;

  @override
  final Map<String, dynamic> appMetadata;

  @override
  final Map<String, dynamic> userMetadata;

  @override
  final String aud;

  @override
  final DateTime? confirmationSentAt;

  @override
  final DateTime? confirmedAt;

  @override
  final String? email;

  @override
  final DateTime? emailConfirmedAt;

  @override
  final String? phone;

  @override
  final DateTime? phoneConfirmedAt;

  @override
  final DateTime? lastSignInAt;

  @override
  final DateTime createdAt;

  @override
  final DateTime updatedAt;

  @override
  final List<UserIdentity>? identities;
}

// ============================================================================
// Setup Helpers
// ============================================================================

/// Configure [MockSupabaseClient] for typical auth scenarios.
void setupMockAuthSuccess(
  MockSupabaseClient mockClient, {
  String userId = 'user-123',
  String email = 'test@example.com',
}) {
  final mockUser = MockUser(id: userId, email: email);
  final mockSession = MockSession(user: mockUser);

  when(() => mockClient.auth.currentUser).thenReturn(mockUser);
  when(() => mockClient.auth.currentSession).thenReturn(mockSession);
  when(() => mockClient.auth.onAuthStateChange).thenAnswer(
    (_) => Stream.value(
      AuthState(
        event: AuthChangeEvent.signedIn,
        session: mockSession,
      ),
    ),
  );
}

/// Configure [MockSupabaseClient] for auth failure scenarios.
void setupMockAuthFailure(MockSupabaseClient mockClient) {
  when(() => mockClient.auth.currentUser).thenReturn(null);
  when(() => mockClient.auth.currentSession).thenReturn(null);
  when(() => mockClient.auth.onAuthStateChange).thenAnswer(
    (_) => Stream.value(
      AuthState(event: AuthChangeEvent.signedOut, session: null),
    ),
  );
}

/// Configure [MockSupabaseClient] to return shelf books from a query.
void setupMockShelfFetch(
  MockSupabaseClient mockClient, {
  required List<Map<String, dynamic>> books,
}) {
  // Build the chain: client.from('table').select(...).eq(...)
  final mockFilterBuilder = MockPostgrestFilterBuilder();
  when(() => mockFilterBuilder.eq(any(), any()))
      .thenAnswer((_) async => books);

  final mockQueryBuilder = MockPostgrestQueryBuilder();
  when(() => mockQueryBuilder.select(any()))
      .thenReturn(mockFilterBuilder);

  when(() => mockClient.from('bookshelf_items'))
      .thenReturn(mockQueryBuilder);
}
