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

/// Root widget: wires repositories/services and theme into the tree via
/// Provider, and drives navigation with an auth-aware GoRouter.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    final client = Supabase.instance.client;
    _authRepository = AuthRepository(client);
    _bookshelfRepository = BookshelfRepository(client);
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
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<BookshelfRepository>.value(value: _bookshelfRepository),
        Provider<GoogleBooksService>.value(value: _googleBooksService),
        ChangeNotifierProvider<ThemeProvider>.value(value: _themeProvider),
      ],
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
