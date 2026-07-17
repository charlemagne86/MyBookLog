import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/book_search/add_book_page.dart';
import '../../features/book_search/search_results_page.dart';
import '../../features/bookshelf/bookshelf_screen.dart';

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
    // Re-run the rules whenever someone signs in or out.
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // splash transitions itself
      final onAuthScreen = loc == '/login' || loc == '/signup';
      // Not logged in and trying to go anywhere else? Send to login.
      if (!loggedIn && !onAuthScreen) return '/login';
      // Already logged in but on a login/signup screen? Send to the shelf.
      if (loggedIn && onAuthScreen) return '/shelf';
      return null; // otherwise, let the navigation proceed as requested
    },
    // The list of every screen in the app and the web-style address it
    // answers to. "add" and "results" are sub-pages of the shelf.
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignUpScreen()),
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
    ],
  );
}
