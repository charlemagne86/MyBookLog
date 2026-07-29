import 'dart:async';
import 'package:mocktail/mocktail.dart';

// BUSINESS LOGIC:
// Auth state drives app behavior: logged-in users see bookshelf,
// logged-out users see login screen. State changes trigger navigation.
// These mocks help test state transitions without real auth backend.
//
// TECHNICAL:
// StreamController.broadcast() provides persistent stream for multiple listeners.
// State emission must happen BEFORE waiting for UI settlement.

class MockAuthState {
  final String? userId;
  final String? email;
  final String? sessionToken;
  final bool isAuthenticated;

  const MockAuthState({
    this.userId,
    this.email,
    this.sessionToken,
    this.isAuthenticated = false,
  });

  // BUSINESS LOGIC:
  // User successfully logged in
  // TECHNICAL: Create state with all auth fields populated
  static MockAuthState signedIn({
    String userId = 'user-123',
    String email = 'test@example.com',
    String sessionToken = 'session-token-abc',
  }) {
    return MockAuthState(
      userId: userId,
      email: email,
      sessionToken: sessionToken,
      isAuthenticated: true,
    );
  }

  // BUSINESS LOGIC:
  // User logged out or never logged in
  // TECHNICAL: Create empty state with all auth fields null
  static MockAuthState signedOut() {
    return const MockAuthState(isAuthenticated: false);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockAuthState &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          email == other.email &&
          sessionToken == other.sessionToken &&
          isAuthenticated == other.isAuthenticated;

  @override
  int get hashCode =>
      userId.hashCode ^
      email.hashCode ^
      sessionToken.hashCode ^
      isAuthenticated.hashCode;

  @override
  String toString() =>
      'MockAuthState(userId: $userId, email: $email, isAuthenticated: $isAuthenticated)';
}

// BUSINESS LOGIC:
// Auth events drive state transitions:
// - SignedIn: User login completed, enable bookshelf features
// - SignedOut: User logout, clear all user data, show login screen
//
// TECHNICAL:
// These events are emitted through a StreamController which routes to UI listeners
class MockAuthEvent {
  final String type; // "signedIn" or "signedOut"
  final MockAuthState? state;

  MockAuthEvent({
    required this.type,
    this.state,
  });

  static MockAuthEvent signedIn(MockAuthState state) =>
      MockAuthEvent(type: 'signedIn', state: state);

  static MockAuthEvent signedOut() =>
      MockAuthEvent(type: 'signedOut', state: null);

  @override
  String toString() => 'MockAuthEvent($type, ${state?.isAuthenticated})';
}

// BUSINESS LOGIC:
// Provides a realistic auth state stream for testing state management.
// Similar to Supabase's onAuthStateChange() stream.
//
// TECHNICAL:
// Uses broadcast() to support multiple listeners (router + UI).
// Exposes emitAuthState() for test control.
class MockAuthStateProvider {
  late StreamController<MockAuthState> _controller;

  MockAuthStateProvider() {
    // TECHNICAL:
    // broadcast() allows multiple listeners unlike default StreamController
    // This is critical for router + UI both receiving auth changes
    _controller = StreamController<MockAuthState>.broadcast();
  }

  // BUSINESS LOGIC:
  // Returns stream of auth state changes
  // TECHNICAL: Listeners receive emitted states
  Stream<MockAuthState> get stream => _controller.stream;

  // BUSINESS LOGIC:
  // Test helper: emit an auth state change
  // TECHNICAL: Call this BEFORE pumpAndSettle to ensure state reaches UI
  void emitAuthState(MockAuthState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  // BUSINESS LOGIC:
  // Emit "user logged in" state
  // TECHNICAL: Helper for common test scenario
  void emitSignedIn({
    String userId = 'user-123',
    String email = 'test@example.com',
  }) {
    emitAuthState(MockAuthState.signedIn(
      userId: userId,
      email: email,
    ));
  }

  // BUSINESS LOGIC:
  // Emit "user logged out" state
  // TECHNICAL: Helper for common test scenario
  void emitSignedOut() {
    emitAuthState(MockAuthState.signedOut());
  }

  // BUSINESS LOGIC:
  // Cleanup: close stream when test ends
  // TECHNICAL: Prevent memory leaks and stream warnings
  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

// BUSINESS LOGIC:
// Mock auth service for testing authentication flows
// without hitting real Supabase backend.
//
// TECHNICAL:
// Simulates success/failure scenarios and tracks call history.
class MockAuthService extends Mock {
  late MockAuthStateProvider _stateProvider;
  List<String> _loginAttempts = [];
  List<String> _signupAttempts = [];
  List<String> _logoutAttempts = [];

  MockAuthService() {
    _stateProvider = MockAuthStateProvider();
  }

  // BUSINESS LOGIC:
  // Returns current auth state stream
  // TECHNICAL: Router/UI listeners get this stream
  Stream<MockAuthState> get onAuthStateChange => _stateProvider.stream;

  // BUSINESS LOGIC:
  // Returns current login attempt history
  // TECHNICAL: Verify sign-in was called with correct params
  List<String> get loginAttempts => _loginAttempts;

  // BUSINESS LOGIC:
  // Sign in with email/password
  // TECHNICAL: Track attempt, then emit auth state
  Future<void> signIn(String email, String password) async {
    _loginAttempts.add(email);
    // Subclass overrides this to simulate success/failure
  }

  // BUSINESS LOGIC:
  // Sign up with email/password
  // TECHNICAL: Track attempt, then emit auth state
  Future<void> signUp(String email, String password) async {
    _signupAttempts.add(email);
    // Subclass overrides this to simulate success/failure
  }

  // BUSINESS LOGIC:
  // Sign out (logout)
  // TECHNICAL: Track attempt, then emit signed-out state
  Future<void> signOut() async {
    _logoutAttempts.add(DateTime.now().toIso8601String());
    _stateProvider.emitSignedOut();
  }

  // BUSINESS LOGIC:
  // Test helper: emit auth state change
  // TECHNICAL: Call before pumpAndSettle
  void emitAuthState(MockAuthState state) {
    _stateProvider.emitAuthState(state);
  }

  // BUSINESS LOGIC:
  // Cleanup: close state stream
  // TECHNICAL: Call in tearDown
  Future<void> dispose() async {
    await _stateProvider.close();
  }
}

// BUSINESS LOGIC:
// Successful login mock (always succeeds)
// TECHNICAL: Emits signed-in state after signIn() called
class SuccessfulAuthService extends MockAuthService {
  @override
  Future<void> signIn(String email, String password) async {
    super.signIn(email, password);
    // Emit successful sign-in after a brief delay to simulate server call
    await Future.delayed(Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }

  @override
  Future<void> signUp(String email, String password) async {
    super.signUp(email, password);
    await Future.delayed(Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }
}

// BUSINESS LOGIC:
// Failed login mock (always fails with invalid credentials)
// TECHNICAL: Throws exception without emitting state
class FailedAuthService extends MockAuthService {
  @override
  Future<void> signIn(String email, String password) async {
    super.signIn(email, password);
    throw Exception('Invalid email or password');
  }

  @override
  Future<void> signUp(String email, String password) async {
    super.signUp(email, password);
    throw Exception('Email already registered');
  }
}

// BUSINESS LOGIC:
// Rate-limited auth mock (blocks repeated attempts)
// TECHNICAL: Throws after N attempts
class RateLimitedAuthService extends MockAuthService {
  int _maxAttempts = 3;
  int _attemptCount = 0;

  @override
  Future<void> signIn(String email, String password) async {
    super.signIn(email, password);
    _attemptCount++;
    if (_attemptCount > _maxAttempts) {
      throw Exception('Too many login attempts. Try again later.');
    }
    await Future.delayed(Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }

  void resetAttempts() {
    _attemptCount = 0;
  }
}
