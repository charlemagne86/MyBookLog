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

/// Bridges a [Stream] (auth state changes) to a [Listenable] so GoRouter
/// re-evaluates `redirect` whenever the user signs in or out.
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

/// Builds the app router. Auth gating lives in a single `redirect`; the branded
/// splash owns its own initial transition.
GoRouter buildRouter(AuthRepository auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null; // splash transitions itself
      final onAuthScreen = loc == '/login' || loc == '/signup';
      if (!loggedIn && !onAuthScreen) return '/login';
      if (loggedIn && onAuthScreen) return '/shelf';
      return null;
    },
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
