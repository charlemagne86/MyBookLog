import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/app.dart' show MyApp;
import 'package:mybooklog/src/core/config/app_config.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Creates or gets the mock repositories used in tests
  Future<(MockAuthRepository, MockBookshelfRepository)> setupMocks() async {
    _mockAuth = MockAuthRepository();
    _mockBookshelf = MockBookshelfRepository();

    // Default setup: user not logged in
    when(() => _mockAuth!.currentSession).thenReturn(null);

    // Default shelf: empty
    when(() => _mockBookshelf!.fetchShelf()).thenAnswer((_) async => []);

    return (_mockAuth!, _mockBookshelf!);
  }

  /// Initializes the app (alias for setupMocks)
  Future<void> initializeApp() async {
    await setupMocks();
  }

  /// Sets up logged-in state with a mock session
  Future<void> setLoggedInState() async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(MockSession());
  }

  /// Sets up logged-out state (no session)
  Future<void> setLoggedOutState() async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(null);
  }

  /// Mocks a successful login
  Future<void> mockSuccessfulLogin({
    String? email,
    String? password,
    String? userId,
  }) async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(MockSession());
  }

  /// Mocks a failed login (no session)
  Future<void> mockFailedLogin({
    String? email,
    String? password,
  }) async {
    if (_mockAuth == null) await setupMocks();
    when(() => _mockAuth!.currentSession).thenReturn(null);
  }

  /// Cleanup after tests
  Future<void> cleanup() async {
    _mockAuth = null;
    _mockBookshelf = null;
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

    // Default mocks if not provided
    when(() => auth.currentSession).thenReturn(null);
    when(() => shelf.fetchShelf()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<BookshelfRepository>.value(value: shelf),
        ],
        child: MyApp(),
      ),
    );

    // Wait for initial frame and navigation
    await tester.pumpAndSettle();
  }

  /// Pumps the app widget (used in test sequences)
  Future<void> pumpApp(WidgetTester tester) async {
    await launchApp(
      tester,
      mockAuth: _mockAuth,
      mockBookshelf: _mockBookshelf,
    );
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
  Future<void> scrollToWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    try {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
    } catch (e) {
      // Widget already visible, no scroll needed
    }
  }

  /// Performs a long press on a widget
  Future<void> longPressWidget(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }
}

// ============================================================================
// Mock Session for Testing
// ============================================================================

/// Mock [Session] using mocktail's Mock (handles SDK interface changes automatically)
class MockSession extends Mock implements Session {}
