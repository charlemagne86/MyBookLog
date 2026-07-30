import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/core/router/app_router.dart';
import 'package:mybooklog/src/core/theme/app_theme.dart';

/// BUSINESS LOGIC:
/// Widget tests need complete app context: routing, theme, dependency injection,
/// and proper initialization. This builder encapsulates that setup so tests
/// can focus on testing user interactions instead of wrestling with framework setup.
///
/// TECHNICAL:
/// Creates MaterialApp with GoRouter, MultiProvider for dependencies, and theme.
/// Includes special handling for auth state stream mocking so GoRouter can detect
/// login/logout transitions and update routes accordingly.
class TestAppBuilder {
  final BookshelfRepository bookshelfRepository;
  final AuthRepository authRepository;
  final GoRouter? router;
  final StreamController<AuthState>? authStateController;

  TestAppBuilder({
    required this.bookshelfRepository,
    required this.authRepository,
    this.router,
    this.authStateController,
  });

  /// BUSINESS LOGIC:
  /// Build the test app widget tree. This includes routing, theme, and all
  /// dependencies the app needs. Tests interact with this as if it's the real app.
  ///
  /// TECHNICAL:
  /// 1. Creates GoRouter if not provided (uses default routes)
  /// 2. Sets up MultiProvider with mocked repositories
  /// 3. Mocks the auth state stream so router can respond to auth changes
  /// 4. Applies app theme
  /// 5. Disables text scaling for consistent widget sizing
  Widget build() {
    final finalRouter = router ?? _createDefaultRouter();

    return MultiProvider(
      providers: [
        Provider<BookshelfRepository>.value(value: bookshelfRepository),
        Provider<AuthRepository>.value(value: authRepository),
      ],
      child: MaterialApp.router(
        routerConfig: finalRouter,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          );
        },
      ),
    );
  }

  /// BUSINESS LOGIC:
  /// Create a default router with navigation rules. This is used when a test
  /// doesn't need to override the routing logic. Tests can provide custom
  /// routers if they need to test routing behavior specifically.
  ///
  /// TECHNICAL:
  /// Uses buildRouter from app_router.dart. The router's redirect logic
  /// enforces auth boundaries (logged-in users can't see login screen, etc).
  GoRouter _createDefaultRouter() {
    return buildRouter(authRepository);
  }
}

/// BUSINESS LOGIC:
/// Setup helpers provide common test scenarios (logged in, logged out,
/// network error, etc) in a reusable way. Tests use these to quickly
/// configure the state they need to test.
///
/// TECHNICAL:
/// Uses mocktail's when/thenAnswer to stub repository methods.
/// Handles auth state stream mocking so GoRouter can respond to auth changes.
/// Each helper corresponds to a user scenario (successful login, network error, etc).
class TestSetupHelpers {
  /// BUSINESS LOGIC:
  /// User is logged in and has books on their shelf.
  /// This is the "normal path" that most tests need to verify UI works correctly.
  ///
  /// TECHNICAL:
  /// Mocks bookshelfRepository.fetchShelf to return test books.
  /// Mocks authRepository to return a non-null currentSession.
  /// Configures auth state stream to emit authenticated event.
  static void setupLoggedInUserWithBooks(
    AuthRepository mockAuth,
    BookshelfRepository mockBookshelf,
    List<dynamic> testBooks,
    StreamController<AuthState> authStateController,
  ) {
    when(
      () => mockBookshelf.fetchShelf(),
    ).thenAnswer((_) async => List.from(testBooks));

    // Mock auth state stream - this is critical for GoRouter to work
    // GoRouterRefreshStream watches this stream and triggers router updates
    when(
      () => mockAuth.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);

    // Create a test session
    final now = DateTime.now().toIso8601String();
    final testSession = Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      expiresIn: 3600,
      refreshToken: 'refresh-token',
      user: User(
        id: 'test-user-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        confirmationSentAt: null,
        recoverySentAt: null,
        emailConfirmedAt: now,
        invitedAt: null,
        actionLink: '',
        email: 'test@example.com',
        phone: '',
        createdAt: now,
        identities: [],
        lastSignInAt: now,
        role: 'authenticated',
        updatedAt: now,
      ),
    );

    // Mock currentSession - router checks this to decide which screen to show
    when(() => mockAuth.currentSession).thenReturn(testSession);

    // Emit auth event to trigger router update
    authStateController.add(AuthState(AuthChangeEvent.signedIn, testSession));
  }

  /// BUSINESS LOGIC:
  /// User is not logged in (logged out or new install).
  /// Tests use this to verify auth screens show and routing protects shelf.
  ///
  /// TECHNICAL:
  /// Sets currentSession to null (no auth token).
  /// Emits signedOut event to trigger router redirect to /login.
  static void setupLoggedOutUser(
    AuthRepository mockAuth,
    StreamController<AuthState> authStateController,
  ) {
    when(() => mockAuth.currentSession).thenReturn(null);

    when(
      () => mockAuth.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);

    // Emit signedOut event to trigger redirect
    authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  /// BUSINESS LOGIC:
  /// Shelf load fails (network error, database down, etc).
  /// Tests verify error UI and recovery (retry button, error message, etc).
  ///
  /// TECHNICAL:
  /// Makes fetchShelf throw an exception.
  /// The screen should catch this, show error banner, and offer retry.
  static void setupShelfLoadError(BookshelfRepository mockBookshelf) {
    when(
      () => mockBookshelf.fetchShelf(),
    ).thenThrow(Exception('Network error: Failed to fetch bookshelf'));
  }

  /// BUSINESS LOGIC:
  /// Empty shelf (user hasn't added books yet).
  /// Tests verify empty state UI (message, add button enabled, etc).
  ///
  /// TECHNICAL:
  /// fetchShelf returns empty list successfully (no error).
  /// Screen should show "no books" message and add button.
  static void setupEmptyShelf(BookshelfRepository mockBookshelf) {
    when(() => mockBookshelf.fetchShelf()).thenAnswer((_) async => []);
  }

  /// BUSINESS LOGIC:
  /// User just signed up or logged in successfully.
  /// Tests verify successful auth flow and navigation to shelf.
  ///
  /// TECHNICAL:
  /// signUp/signIn complete without error.
  static void setupSuccessfulAuth(
    AuthRepository mockAuth, {
    required bool isSignUp,
  }) {
    if (isSignUp) {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async {});
    } else {
      when(
        () => mockAuth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
    }
  }

  /// BUSINESS LOGIC:
  /// User tries to log in with wrong password (invalid credentials).
  /// Tests verify error message and retry allowed.
  ///
  /// TECHNICAL:
  /// signIn throws "Invalid credentials" exception.
  /// UI should show error and let user try again.
  static void setupInvalidCredentials(AuthRepository mockAuth) {
    when(
      () => mockAuth.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Invalid email or password'));
  }

  /// BUSINESS LOGIC:
  /// User tries to sign up with email that already exists.
  /// Tests verify error message and recovery (redirect to login, etc).
  ///
  /// TECHNICAL:
  /// signUp throws "Email exists" exception.
  /// UI should show error and offer login option.
  static void setupEmailAlreadyExists(AuthRepository mockAuth) {
    when(
      () => mockAuth.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenThrow(Exception('Email already registered'));
  }
}
