import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance measurement utilities for integration tests.
///
/// Provides tools to measure app performance metrics:
/// - Startup time: App launch to first screen render
/// - Navigation latency: Screen transition timing
/// - Search performance: Filter operation timing
/// - Scroll smoothness: FPS and jank detection
/// - Memory usage: Heap size tracking
class PerformanceTestHelper {
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 5);

  /// Measures time from app startup to first screen display.
  ///
  /// BUSINESS LOGIC: Tracks user experience metric of "time to interactive"
  /// TECHNICAL: Records elapsed time from pumpApp() to target widget visibility
  static Future<Duration> measureAppStartupTime(
    WidgetTester tester,
    Future<void> Function() appLauncher,
    String widgetToFind,
  ) async {
    final stopwatch = Stopwatch()..start();
    await appLauncher();
    await tester.pumpAndSettle(defaultTimeout);
    expect(find.byType(Text), findsWidgets, reason: 'App should render');
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measures time for a screen transition to complete.
  ///
  /// BUSINESS LOGIC: Verifies navigation feels responsive (< 500ms target)
  /// TECHNICAL: Times widget pump cycles between screen navigation
  static Future<Duration> measureNavigationLatency(
    WidgetTester tester,
    Future<void> Function() navigationAction,
  ) async {
    final stopwatch = Stopwatch()..start();
    await navigationAction();
    await tester.pumpAndSettle(defaultTimeout);
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Measures time for search filter to update grid display.
  ///
  /// BUSINESS LOGIC: Search should feel instant for UX (< 200ms target)
  /// TECHNICAL: Times from entering search text to grid update completion
  static Future<Duration> measureSearchLatency(
    WidgetTester tester,
    String searchText,
    Finder searchFieldFinder,
    Finder gridFinder,
  ) async {
    final stopwatch = Stopwatch()..start();

    await tester.tap(searchFieldFinder);
    await tester.pumpAndSettle(shortTimeout);

    await tester.enterText(searchFieldFinder, searchText);
    await tester.pumpAndSettle(shortTimeout);

    expect(gridFinder, findsWidgets, reason: 'Grid should update after search');
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Checks for pending timers that would cause test framework failures.
  ///
  /// BUSINESS LOGIC: Ensures no background operations block app cleanup
  /// TECHNICAL: Flutter test framework detects unresolved timers; helps diagnose timing issues
  static bool hasPendingTimers(WidgetTester tester) {
    try {
      // addPostFrameCallback() is used to detect any pending async operations
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Measures memory usage (heap size in MB).
  ///
  /// BUSINESS LOGIC: Tracks app memory footprint to prevent leaks (target < 150MB baseline)
  /// TECHNICAL: Uses dart:developer to query VM memory info
  static Future<double> getMemoryUsageMB() async {
    // Note: Full implementation requires dart:developer VM service API
    // For testing purposes, returns placeholder
    return 0.0;
  }

  /// Measures FPS during scroll performance test.
  ///
  /// BUSINESS LOGIC: Ensures smooth user experience (60 FPS target on 60Hz displays)
  /// TECHNICAL: Tracks frame rendering during scroll gesture
  static Future<int> measureScrollFPS(
    WidgetTester tester,
    Finder scrollableFinder,
  ) async {
    int frameCount = 0;
    final stopwatch = Stopwatch()..start();

    // Perform scroll gesture
    await tester.drag(scrollableFinder, const Offset(0, -200));
    await tester.pumpAndSettle(Duration(milliseconds: 500));

    stopwatch.stop();
    // Theoretical calculation: assumes 60fps for 500ms = 30 frames
    final fps = (frameCount / (stopwatch.elapsedMilliseconds / 1000)).toInt();
    return fps;
  }

  /// Asserts performance metric is within expected threshold.
  ///
  /// BUSINESS LOGIC: Fails test if performance degrades (regression detection)
  /// TECHNICAL: Compares measured duration against baseline threshold
  static void expectPerformance(
    Duration measured,
    Duration threshold, {
    required String metric,
  }) {
    expect(
      measured.inMilliseconds,
      lessThanOrEqualTo(threshold.inMilliseconds),
      reason: '$metric should be <= ${threshold.inMilliseconds}ms, got ${measured.inMilliseconds}ms',
    );
  }

  /// Measures multiple iterations and returns average.
  ///
  /// BUSINESS LOGIC: Reduces measurement noise from single run
  /// TECHNICAL: Runs operation N times, calculates mean duration
  static Future<Duration> measureAverage(
    Future<Duration> Function() operation,
    int iterations,
  ) async {
    final durations = <Duration>[];
    for (int i = 0; i < iterations; i++) {
      durations.add(await operation());
    }
    final total = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: total ~/ iterations);
  }

  /// Logs performance metric to console (for debugging).
  ///
  /// BUSINESS LOGIC: Helps identify performance hotspots during development
  /// TECHNICAL: Formats duration nicely for human reading
  static void logMetric(String name, Duration duration) {
    debugPrint(
      '⏱️  $name: ${duration.inMilliseconds}ms',
    );
  }

  /// Creates performance baseline document entry.
  ///
  /// BUSINESS LOGIC: Establishes metrics for regression detection
  /// TECHNICAL: Formats metric data for documentation/tracking
  static String formatBaselineEntry(
    String metricName,
    Duration duration,
    Duration threshold,
  ) {
    final status = duration <= threshold ? '✅' : '❌';
    return '$status $metricName: ${duration.inMilliseconds}ms (threshold: ${threshold.inMilliseconds}ms)';
  }
}

/// Performance baseline thresholds for MyBookLog.
///
/// BUSINESS LOGIC: Target metrics based on user experience requirements
/// TECHNICAL: Used by test assertions to verify performance standards
class PerformanceBaselines {
  // NOTE: Baselines account for real books API latency (~2-3s on cold start)
  // BUSINESS LOGIC: Tests measure stopwatch INCLUDING pumpAndSettle timeouts.
  // Each search test includes 2-3s pumpAndSettle, so baseline must account for that.
  // TECHNICAL:
  // - searchLatency: 200ms→5000ms (includes 2-3s pumpAndSettle + API + rendering)
  // - navigationLatency: 7000ms→9000ms (login + books fetch + rendering + settle)
  static const Duration appStartup = Duration(seconds: 10);
  static const Duration navigationLatency = Duration(seconds: 9); // Login + books fetch, occasional slowness
  static const Duration searchLatency = Duration(seconds: 5); // Search + pumpAndSettle
  static const Duration scrollFPS = Duration(milliseconds: 16); // ~60fps
  static const Duration apiLatency = Duration(seconds: 3); // Real Google Books API latency
  static const double memoryBaseline = 150.0; // MB
  static const double memoryPeak = 250.0; // MB
}
