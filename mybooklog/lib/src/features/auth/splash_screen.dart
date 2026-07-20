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
    // Schedule the routing after the first frame renders.
    // TECHNICAL:
    // We use addPostFrameCallback to ensure the splash screen is fully rendered
    // before starting the 2-second delay timer. This provides a cleaner visual
    // experience and allows widget tests to complete without pending timers.
    // The user-perceived delay remains ~2 seconds (imperceptible <50ms difference).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _routeAfterSplash();
    });
  }

  Future<void> _routeAfterSplash() async {
    // BUSINESS LOGIC:
    // Pause briefly so the welcome branding is actually visible to users.
    // This 2-second delay gives users time to see the app name and branding
    // before routing to the next screen (either bookshelf or login).
    //
    // TECHNICAL:
    // The Future.delayed is scheduled after the first frame render, allowing
    // the splash screen to display cleanly before the timer begins.
    await Future.delayed(const Duration(seconds: 2));

    // Safety check: do nothing if the screen was closed during the pause.
    // This prevents navigation attempts on unmounted widgets.
    if (!mounted) return;

    // BUSINESS LOGIC:
    // Check if the user is still logged in from their previous visit.
    // This provides a seamless experience for returning users (they skip login).
    // New or logged-out users are taken to the login screen for authentication.
    //
    // TECHNICAL:
    // currentSession is null if no valid auth token exists.
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
