import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/app.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:provider/provider.dart';

// ============================================================================
// Mock Repositories for Integration Testing
// ============================================================================

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBookshelfRepository extends Mock implements BookshelfRepository {}

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
  /// Creates or gets the mock repositories used in tests
  Future<(MockAuthRepository, MockBookshelfRepository)> setupMocks() async {
    final mockAuth = MockAuthRepository();
    final mockBookshelf = MockBookshelfRepository();

    // Default setup: user not logged in
    when(() => mockAuth.currentSession).thenReturn(null);

    // Default shelf: empty
    when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => []);

    return (mockAuth, mockBookshelf);
  }

  /// Launches the app with mocked repositories
  Future<void> launchApp(
    WidgetTester tester, {
    MockAuthRepository? mockAuth,
    MockBookshelfRepository? mockBookshelf,
  }) async {
    final auth = mockAuth ?? MockAuthRepository();
    final shelf = mockBookshelf ?? MockBookshelfRepository();

    // Default mocks if not provided
    when(() => auth.currentSession).thenReturn(null);
    when(() => shelf.fetchShelf()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: auth),
          Provider<BookshelfRepository>.value(value: shelf),
        ],
        child: const MyBookLogApp(),
      ),
    );

    // Wait for initial frame and navigation
    await tester.pumpAndSettle();
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
