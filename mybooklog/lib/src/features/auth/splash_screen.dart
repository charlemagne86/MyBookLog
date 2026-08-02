import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/auth_repository.dart';

/// The welcome screen shown for the first moment after the app opens.
///
/// BUSINESS LOGIC:
/// Before Flutter can draw anything, the OS briefly shows its own default
/// launch screen — just the app icon, centered. This widget deliberately
/// leads with that exact same icon so the handoff from OS to Flutter reads
/// as one continuous screen instead of a jarring content swap (icon, then
/// suddenly text). The app name and tagline appear below it here, and a
/// spinner shows while we check whether the user was still logged in from
/// last time. If so, they go straight to their bookshelf — no need to type
/// their password again. If not, they are taken to the login screen. (BUG-4)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    // BUSINESS LOGIC:
    // Optimize splash screen UX by running initialization in parallel with
    // minimum visibility time. This ensures:
    // - Splash is visible long enough for branding (minimum 1.2 seconds)
    // - Users on slow devices aren't blocked by a fixed 2-second wait
    // - Fast devices show splash for only as long as needed (no artificial delay)
    // - UX is adaptive to actual device performance and network speed
    //
    // TECHNICAL:
    // We use Future.wait to ensure both conditions are met:
    // 1. Minimum visibility time elapsed (splash looks intentional, not instant)
    // 2. Auth check completed (we know if user is logged in)
    // The user routes when BOTH complete, providing optimal UX regardless of device.
    _authCheckFuture = _initializeAuth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeAfterSplash();
    });
  }

  Future<bool> _initializeAuth() async {
    // Perform authentication check (in parallel with minimum visibility time).
    // Returns true if user has active session, false otherwise.
    // This check is fast (just reading cached session), typically < 100ms.
    try {
      final session = context.read<AuthRepository>().currentSession;
      return session != null;
    } catch (e) {
      // If auth check fails, treat as logged out (go to login screen)
      return false;
    }
  }

  Future<void> _routeAfterSplash() async {
    // BUSINESS LOGIC:
    // Wait for BOTH conditions:
    // 1. Minimum visibility time (ensures splash is seen, not instant)
    // 2. Auth check completion (know where to route user)
    // This provides optimal UX: fast devices skip artificial delay,
    // slow devices have time to see the branding.
    //
    // TECHNICAL:
    // Future.wait runs both futures in parallel and waits for both to complete.
    // The timeout acts as a safety net (prevents indefinite splash screen).
    try {
      final results =
          await Future.wait([
            Future.delayed(
              const Duration(milliseconds: 1200),
            ), // Minimum visibility
            _authCheckFuture, // Auth check (usually completes much faster)
          ]).timeout(
            const Duration(
              seconds: 5,
            ), // Safety timeout (prevents stuck splash)
            onTimeout: () => [null, false], // Default to logged-out if timeout
          );

      final hasSession = results[1] as bool? ?? false;

      // Safety check: do nothing if screen unmounted during initialization
      if (!mounted) return;

      // Route based on auth status
      context.go(hasSession ? '/shelf' : '/login');
    } catch (e) {
      // If anything fails, default to login screen for safety
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same artwork as the OS's own launch icon (see class doc) —
            // carrying it over here is what makes the two screens read as
            // one continuous splash instead of two different ones.
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset(
                'assets/icon/app_icon_512.png',
                width: 128,
                height: 128,
              ),
            ),
            const SizedBox(height: 28),
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
