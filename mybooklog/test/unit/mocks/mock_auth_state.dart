import 'dart:async';
import 'package:mocktail/mocktail.dart';

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

class MockAuthEvent {
  final String type;
  final MockAuthState? state;

  MockAuthEvent({required this.type, this.state});

  static MockAuthEvent signedIn(MockAuthState state) =>
      MockAuthEvent(type: 'signedIn', state: state);

  static MockAuthEvent signedOut() =>
      MockAuthEvent(type: 'signedOut', state: null);

  @override
  String toString() => 'MockAuthEvent($type, ${state?.isAuthenticated})';
}

class MockAuthStateProvider {
  late StreamController<MockAuthState> _controller;

  MockAuthStateProvider() {
    _controller = StreamController<MockAuthState>.broadcast();
  }

  Stream<MockAuthState> get stream => _controller.stream;

  void emitAuthState(MockAuthState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  void emitSignedIn({
    String userId = 'user-123',
    String email = 'test@example.com',
  }) {
    emitAuthState(MockAuthState.signedIn(userId: userId, email: email));
  }

  void emitSignedOut() {
    emitAuthState(MockAuthState.signedOut());
  }

  Future<void> close() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

class MockAuthService extends Mock {
  late MockAuthStateProvider _stateProvider;
  List<String> _loginAttempts = [];
  List<String> _signupAttempts = [];
  List<String> _logoutAttempts = [];

  MockAuthService() {
    _stateProvider = MockAuthStateProvider();
  }

  Stream<MockAuthState> get onAuthStateChange => _stateProvider.stream;

  List<String> get loginAttempts => _loginAttempts;

  Future<void> signIn(String email, String password) async {
    _loginAttempts.add(email);
  }

  Future<void> signUp(String email, String password) async {
    _signupAttempts.add(email);
  }

  Future<void> signOut() async {
    _logoutAttempts.add(DateTime.now().toIso8601String());
    _stateProvider.emitSignedOut();
  }

  void emitAuthState(MockAuthState state) {
    _stateProvider.emitAuthState(state);
  }

  Future<void> dispose() async {
    await _stateProvider.close();
  }
}

class SuccessfulAuthService extends MockAuthService {
  @override
  Future<void> signIn(String email, String password) async {
    await super.signIn(email, password);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }

  @override
  Future<void> signUp(String email, String password) async {
    await super.signUp(email, password);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }
}

class FailedAuthService extends MockAuthService {
  @override
  Future<void> signIn(String email, String password) async {
    await super.signIn(email, password);
    throw Exception('Invalid email or password');
  }

  @override
  Future<void> signUp(String email, String password) async {
    await super.signUp(email, password);
    throw Exception('Email already registered');
  }
}

class RateLimitedAuthService extends MockAuthService {
  int _maxAttempts = 3;
  int _attemptCount = 0;

  @override
  Future<void> signIn(String email, String password) async {
    await super.signIn(email, password);
    _attemptCount++;
    if (_attemptCount > _maxAttempts) {
      throw Exception('Too many login attempts. Try again later.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    emitAuthState(MockAuthState.signedIn(email: email));
  }

  void resetAttempts() {
    _attemptCount = 0;
  }
}
