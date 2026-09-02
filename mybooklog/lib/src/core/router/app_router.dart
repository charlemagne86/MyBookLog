import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/book_search/add_book_page.dart';
import '../../features/book_search/search_results_page.dart';
import '../../features/bookshelf/bookshelf_screen.dart';
import '../../features/profile/profile_screen.dart';

/// BUSINESS LOGIC:
/// The add-book flow (BookshelfScreen -> AddBookPage -> SearchResultsPage)
/// returns to the shelf via `context.go('/shelf')` rather than popping back
/// through each pushed screen — go_router treats that as "navigate to this
/// location", and since a BookshelfScreen page is already sitting at the
/// bottom of the stack, it reuses that existing instance instead of
/// creating a fresh one. That means the shelf's one-time `initState` fetch
/// never runs again, so a newly added book wouldn't appear until the user
/// force-restarted the app.
///
/// TECHNICAL:
/// A [RouteObserver] notifies a screen's [RouteAware.didPopNext] whenever a
/// route that was covering it is removed — including removals caused by a
/// declarative `go()` call, not just an imperative `pop()`. BookshelfScreen
/// subscribes to this and refetches on that callback, so it reloads however
/// the user gets back to it.
final RouteObserver<PageRoute<void>> shelfRouteObserver =
    RouteObserver<PageRoute<void>>();

/// A small adapter that watches the "signed in / signed out" event feed and
/// pokes the router each time it changes, so the router can immediately
/// re-check which screen the user is allowed to see. Without this, signing
/// out would leave the user stranded on the bookshelf screen.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Builds the app's "map of screens" and the traffic rules between them.
///
/// The `redirect` function below is the app's security guard: it runs before
/// every screen change and enforces two simple rules —
///   * If you are NOT logged in, you may only see the login/signup screens.
///   * If you ARE logged in, the login/signup screens bounce you to your shelf.
/// The splash (welcome) screen is exempt because it decides its own next stop.
GoRouter buildRouter(AuthRepository auth) {
  return GoRouter(
    initialLocation: '/splash', // the first screen shown at startup
    observers: [shelfRouteObserver],
    // Re-run the rules whenever someone signs in or out.
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // splash transitions itself
      // Two DIFFERENT lists, deliberately not one:
      //  * publicScreens — screens a logged-OUT user may see. Includes the
      //    forgot-password flow, which by definition serves people who
      //    cannot log in.
      //  * bounceWhenLoggedIn — screens that make no sense once signed in.
      //    Forgot-password is NOT here: verifying the emailed reset code
      //    signs the user in MIDWAY through that flow, and bouncing them to
      //    the shelf at that instant would strand them with their old
      //    password never replaced. The screen itself navigates to the
      //    shelf once the new password is saved.
      final publicScreens =
          loc == '/login' || loc == '/signup' || loc == '/forgot-password';
      final bounceWhenLoggedIn = loc == '/login' || loc == '/signup';
      // Not logged in and trying to go anywhere non-public? Send to login.
      if (!loggedIn && !publicScreens) return '/login';
      // Already logged in but on the login/signup screen? Send to the shelf.
      if (loggedIn && bounceWhenLoggedIn) return '/shelf';
      return null; // otherwise, let the navigation proceed as requested
    },
    // The list of every screen in the app and the web-style address it
    // answers to. "add" and "results" are sub-pages of the shelf.
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: '/forgot-password',
        // The login screen passes along whatever email the user had already
        // typed (as the route's "extra" data) so it arrives pre-filled.
        builder: (_, state) =>
            ForgotPasswordScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: '/shelf',
        builder: (_, _) => const BookshelfScreen(),
        routes: [
          GoRoute(path: 'add', builder: (_, _) => const AddBookPage()),
          GoRoute(
            path: 'results',
            builder: (context, state) =>
                SearchResultsPage(args: state.extra as SearchResultsArgs),
          ),
        ],
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );
}
