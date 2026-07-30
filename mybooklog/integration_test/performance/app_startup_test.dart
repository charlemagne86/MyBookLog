import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mybooklog/src/app.dart';
import '../helpers/integration_test_helper.dart';
import '../helpers/performance_test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  group('Performance: App Startup', () {
    final testHelper = IntegrationTestHelper();

    setUp(() async {
      await testHelper.initializeApp();
    });

    tearDown(() async {
      await testHelper.cleanup();
    });

    testWidgets('app_startup_time_cold_launch', (WidgetTester tester) async {
      /// Measures time from app launch to first screen render.
      ///
      /// BUSINESS LOGIC: Cold start affects user perception; target < 2 seconds
      /// for acceptable UX. Critical for app store ratings.
      /// TECHNICAL: Measures elapsed time from pumpApp() to identifying
      /// rendered content (Text widgets indicating screen is ready).
      /// Expected: SplashScreen or LoginScreen should be visible.

      final startTime = DateTime.now();
      await testHelper.pumpApp(tester);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Verify app rendered
      expect(
        find.byType(Text),
        findsWidgets,
        reason: 'App should render splash or login screen',
      );

      // Assert within baseline
      PerformanceTestHelper.expectPerformance(
        duration,
        PerformanceBaselines.appStartup,
        metric: 'App startup time',
      );

      PerformanceTestHelper.logMetric('Cold startup', duration);
    });

    testWidgets('app_startup_logged_in_state', (WidgetTester tester) async {
      /// Measures startup time when user is already logged in.
      ///
      /// BUSINESS LOGIC: Returning user should reach bookshelf quickly
      /// (warm start) for good user experience.
      /// TECHNICAL: Pre-sets logged-in auth state, then measures time
      /// to first real screen (BookshelfScreen).

      await testHelper.setLoggedInState();
      final stopwatch = Stopwatch()..start();

      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 2));

      stopwatch.stop();

      // Should see bookshelf indicators (grid, search bar, etc)
      expect(
        find.byIcon(Icons.search),
        findsWidgets,
        reason: 'Bookshelf should show search bar',
      );

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.appStartup,
        metric: 'Logged-in startup',
      );

      PerformanceTestHelper.logMetric(
        'Warm startup (logged in)',
        stopwatch.elapsed,
      );
    });

    testWidgets('app_startup_logged_out_state', (WidgetTester tester) async {
      /// Measures startup time when user is not logged in.
      ///
      /// BUSINESS LOGIC: New user should reach login screen immediately.
      /// TECHNICAL: Ensures no auth state, measures to LoginScreen render.

      await testHelper.setLoggedOutState();
      final stopwatch = Stopwatch()..start();

      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 2));

      stopwatch.stop();

      // Should show login form
      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Login screen should render with input fields',
      );

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.appStartup,
        metric: 'Logout startup',
      );

      PerformanceTestHelper.logMetric(
        'Logout state startup',
        stopwatch.elapsed,
      );
    });

    testWidgets('multiple_cold_starts', (WidgetTester tester) async {
      /// Verifies startup performance is consistent across multiple launches.
      ///
      /// BUSINESS LOGIC: Startup time should not degrade with repeated use
      /// (indicates memory leaks or accumulating overhead).
      /// TECHNICAL: Launches app 3 times, measures each, calculates average
      /// and checks for regressions.

      const iterations = 3;
      final durations = <Duration>[];

      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        await testHelper.pumpApp(tester);
        await tester.pumpAndSettle(Duration(seconds: 2));
        stopwatch.stop();

        durations.add(stopwatch.elapsed);

        // Clean up for next iteration
        await testHelper.cleanup();
        await testHelper.initializeApp();
      }

      // Calculate average
      final totalMs = durations.fold<int>(
        0,
        (sum, d) => sum + d.inMilliseconds,
      );
      final averageMs = totalMs ~/ iterations;
      final averageDuration = Duration(milliseconds: averageMs);

      // Check for consistency (no iteration should be > 2x average)
      for (final duration in durations) {
        expect(
          duration.inMilliseconds,
          lessThanOrEqualTo(averageDuration.inMilliseconds * 2),
          reason: 'Startup time should not vary drastically',
        );
      }

      PerformanceTestHelper.logMetric(
        'Average startup (3 runs)',
        averageDuration,
      );
    });
  });
}
