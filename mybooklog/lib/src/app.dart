import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/bookshelf_repository.dart';
import 'data/services/google_books_service.dart';

/// Root widget: the top of the entire user interface.
///
/// Think of this as the app's "wiring closet". It creates the three helpers
/// the rest of the app relies on —
///   * AuthRepository        (logging in and out),
///   * BookshelfRepository   (reading and saving the user's books),
///   * GoogleBooksService    (searching the internet for books),
/// — and makes them available to every screen. It also sets up the color
/// theme (light/dark) and the "router", which decides which screen the user
/// sees and keeps logged-out users away from the bookshelf.
///
/// TESTING: For integration tests, pass mock repositories via constructor
/// parameters. If not provided, real instances are created.
class MyApp extends StatefulWidget {
  /// Optional mock repositories for testing. If provided, these are used
  /// instead of creating real instances from Supabase.
  final AuthRepository? authRepository;
  final BookshelfRepository? bookshelfRepository;

  const MyApp({
    super.key,
    this.authRepository,
    this.bookshelfRepository,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();
  late final AuthRepository _authRepository;
  late final BookshelfRepository _bookshelfRepository;
  late final GoogleBooksService _googleBooksService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Runs exactly once when the app starts: create each shared helper and
    // the navigation router. They live for the whole lifetime of the app.

    // TESTING: Use injected repositories if provided (for integration tests),
    // otherwise create real instances from Supabase.
    final client = Supabase.instance.client;
    _authRepository = widget.authRepository ?? AuthRepository(client);
    _bookshelfRepository = widget.bookshelfRepository ?? BookshelfRepository(client);
    _googleBooksService = GoogleBooksService();
    _router = buildRouter(_authRepository);
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MultiProvider "publishes" the shared helpers so any screen, no matter
    // how deep, can reach them without passing them along by hand.
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<BookshelfRepository>.value(value: _bookshelfRepository),
        Provider<GoogleBooksService>.value(value: _googleBooksService),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
      ],
      // Consumer re-draws the app whenever the theme changes (for example if
      // the user switches between light and dark mode).
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'My Book Log',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
