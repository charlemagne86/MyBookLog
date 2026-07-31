import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/app.dart' show MyApp;
import 'package:mybooklog/src/core/config/app_config.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/real_book_fixtures.dart';

// ============================================================================
// Mock Repositories for Integration Testing
// ============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBookshelfRepository extends Mock implements BookshelfRepository {}

// ============================================================================
// Test Initialization
// ============================================================================

/// Initialize Supabase for integration tests.
/// Call this in setUpAll() before running any tests.
Future<void> initializeSupabaseForTests() async {
  // Ensure Flutter bindings are initialized
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with credentials from AppConfig
  // These are publishable (anon) keys - safe to use in tests
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  } catch (e) {
    // Supabase already initialized, which is fine
    if (!e.toString().contains('already initialized')) {
      rethrow;
    }
  }
}

// ============================================================================
// Integration Test Helper
// ============================================================================

/// Helper class for integration testing MyBookLog app.
///
/// BUSINESS LOGIC:
/// Integration tests need to launch the full app with proper routing,
/// but use mocked repositories to avoid real network calls to Supabase.
/// This helper provides setup/teardown and common operations.
///
/// TECHNICAL:
/// - Initializes the app with mocked providers
/// - Provides helpers for common test patterns (wait for text, tap, etc.)
/// - Handles auth state setup (login/logout for test scenarios)
class IntegrationTestHelper {
  MockAuthRepository? _mockAuth;
  MockBookshelfRepository? _mockBookshelf;
  StreamController<AuthState>? _authStateController;

  /// Creates or gets the mock repositories used in tests
  /// Sets up with REAL books from Google Books API for realistic testing
  Future<(MockAuthRepository, MockBookshelfRepository)> setupMocks() async {
    if (_mockAuth != null && _mockBookshelf != null) {
      return (_mockAuth!, _mockBookshelf!);
    }

    _mockAuth = MockAuthRepository();
    _mockBookshelf = MockBookshelfRepository();

    // Create a StreamController for auth state that can emit to existing listeners
    _authStateController = StreamController<AuthState>.broadcast();

    // NOTE: Auth stream setup is done in specific methods (setLoggedInState, etc.)
    // This allows tests to manually configure mocks without stream interference

    // Default setup: user logged out, empty shelf
    when(() => _mockAuth!.currentSession).thenReturn(null);
    when(
      () => _mockAuth!.onAuthStateChange,
    ).thenAnswer((_) => _authStateController!.stream);
    when(() => _mockBookshelf!.fetchShelf()).thenAnswer((_) async => []);

    // Emit initial logged-out state
    _authStateController!.add(AuthState(AuthChangeEvent.signedOut, null));

    return (_mockAuth!, _mockBookshelf!);
  }

  /// Initializes the app (alias for setupMocks)
  Future<void> initializeApp() async {
    // Clear any cached test books to ensure fresh load for each test
    RealBookFixtures.clearCache();
    await setupMocks();
  }

  /// Sets up logged-in state with a mock session and REAL test books
  /// Fetches real books from Google Books API to simulate new-user experience
  Future<void> setLoggedInState() async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(MockSession());

    // Emit "signed in" event through the stream controller
    // This triggers the router to redirect to the bookshelf screen
    _authStateController!.add(
      AuthState(AuthChangeEvent.signedIn, MockSession()),
    );

    // Fetch REAL books from Google Books API (or fallback if unavailable)
    final testBooks = await RealBookFixtures.getTestBooks();

    // Mock bookshelf repository to return real books
    when(() => _mockBookshelf!.fetchShelf()).thenAnswer((_) async => testBooks);
  }

  /// Sets up logged-out state (no session, empty bookshelf)
  Future<void> setLoggedOutState() async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(null);

    // Emit "signed out" event through the stream controller
    // This triggers the router to redirect to the login screen
    _authStateController!.add(AuthState(AuthChangeEvent.signedOut, null));

    // Empty bookshelf for logged-out state
    when(() => _mockBookshelf!.fetchShelf()).thenAnswer((_) async => []);
  }

  /// Mocks a successful login
  Future<void> mockSuccessfulLogin({
    String? email,
    String? password,
    String? userId,
  }) async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(MockSession());

    // Emit "signed in" event through the stream controller
    // This triggers router redirect to bookshelf for existing listeners
    _authStateController!.add(
      AuthState(AuthChangeEvent.signedIn, MockSession()),
    );

    // Provide real books for the bookshelf
    final testBooks = await RealBookFixtures.getTestBooks();
    when(() => _mockBookshelf!.fetchShelf()).thenAnswer((_) async => testBooks);
  }

  /// Mocks a failed login (no session)
  Future<void> mockFailedLogin({String? email, String? password}) async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(null);

    // Emit "signed out" event through the stream controller
    _authStateController!.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  /// Emits an auth state change through the stream controller
  /// Used by tests that manually mock signIn/signOut
  void emitAuthStateChange(AuthState state) {
    if (_authStateController == null) {
      throw StateError(
        'StreamController not initialized. Call setupMocks() first.',
      );
    }
    _authStateController!.add(state);
  }

  /// Cleanup after tests
  Future<void> cleanup() async {
    _mockAuth = null;
    _mockBookshelf = null;
    if (_authStateController != null && !_authStateController!.isClosed) {
      await _authStateController!.close();
    }
    _authStateController = null;
  }

  /// Launches the app with mocked repositories
  Future<void> launchApp(
    WidgetTester tester, {
    MockAuthRepository? mockAuth,
    MockBookshelfRepository? mockBookshelf,
  }) async {
    final auth = mockAuth ?? _mockAuth ?? MockAuthRepository();
    final shelf = mockBookshelf ?? _mockBookshelf ?? MockBookshelfRepository();

    // Store for later use
    _mockAuth = auth;
    _mockBookshelf = shelf;

    // Set up stream controller if not already done (for direct launchApp calls)
    if (_authStateController == null) {
      _authStateController = StreamController<AuthState>.broadcast();
      when(
        () => auth.onAuthStateChange,
      ).thenAnswer((_) => _authStateController!.stream);

      // Emit initial state based on current session
      final isLoggedIn = auth.currentSession != null;
      _authStateController!.add(
        isLoggedIn
            ? AuthState(AuthChangeEvent.signedIn, auth.currentSession)
            : AuthState(AuthChangeEvent.signedOut, null),
      );
    } else {
      // Stream controller already exists, ensure auth mock uses it
      when(
        () => auth.onAuthStateChange,
      ).thenAnswer((_) => _authStateController!.stream);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<BookshelfRepository>.value(value: shelf),
        ],
        // Pass repositories directly to MyApp constructor for testing
        child: MyApp(authRepository: auth, bookshelfRepository: shelf),
      ),
    );

    // Wait for initial frame and navigation
    await tester.pumpAndSettle();
  }

  /// Pumps the app widget (used in test sequences)
  Future<void> pumpApp(WidgetTester tester) async {
    await launchApp(tester, mockAuth: _mockAuth, mockBookshelf: _mockBookshelf);
  }

  /// Waits for text to appear on screen
  Future<void> waitForText(WidgetTester tester, String text) async {
    await tester.pumpAndSettle();
    expect(find.text(text), findsOneWidget);
  }

  /// Finds and taps a widget
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enters text in a TextField and waits for processing
  Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Scrolls to a widget in a scrollable area
  Future<void> scrollToWidget(WidgetTester tester, Finder finder) async {
    try {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    } catch (e) {
      // Widget already visible, no scroll needed
    }
  }

  /// Performs a long press on a widget
  Future<void> longPressWidget(WidgetTester tester, Finder finder) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }
}

// ============================================================================
// Mock Session for Testing
// ============================================================================

/// Mock [Session] using mocktail's Mock (handles SDK interface changes automatically)
class MockSession extends Mock implements Session {}
