import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';

/// The welcome screen shown for the first two seconds after the app opens.
///
/// While the app name and a small spinner are displayed, we check whether the
/// user was still logged in from last time. If so, they go straight to their
/// bookshelf — no need to type their password again. If not, they are taken
/// to the login screen. (BUG-4)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeAfterSplash();
  }

  Future<void> _routeAfterSplash() async {
    // Pause briefly so the welcome branding is actually visible.
    await Future.delayed(const Duration(seconds: 2));
    // Safety check: do nothing if the screen was closed during the pause.
    if (!mounted) return;
    // Still logged in from a previous visit? Skip the login screen.
    final hasSession = context.read<AuthRepository>().currentSession != null;
    context.go(hasSession ? '/shelf' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'My Book Log',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'crafted with love',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
