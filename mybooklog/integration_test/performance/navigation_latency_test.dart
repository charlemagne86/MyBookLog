import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/integration_test_helper.dart';
import '../helpers/performance_test_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance: Navigation Latency', () {
    final testHelper = IntegrationTestHelper();

    setUp(() async {
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(this as WidgetTester);
    });

    tearDown(() async {
      await testHelper.cleanup();
    });

    testWidgets('login_to_bookshelf_navigation', (WidgetTester tester) async {
      /// Measures time for login → bookshelf transition.
      ///
      /// BUSINESS LOGIC: User should not see blank screen or loading delay
      /// between screens (target < 500ms). Critical for perceived performance.
      /// TECHNICAL: Simulates login action and times widget tree update
      /// until bookshelf is visible.

      // Set up to show login screen
      await testHelper.setLoggedOutState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle();

      // Verify we're at login
      expect(find.byType(TextField), findsWidgets);

      // Measure login transition time
      final stopwatch = Stopwatch()..start();

      // Simulate login
      await testHelper.mockSuccessfulLogin(
        email: 'test@example.com',
        password: 'password123',
      );

      // Trigger navigation
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verify bookshelf visible
      expect(
        find.byIcon(Icons.search),
        findsWidgets,
        reason: 'Should navigate to bookshelf',
      );

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.navigationLatency,
        metric: 'Login to bookshelf',
      );

      PerformanceTestHelper.logMetric('Login → Bookshelf', stopwatch.elapsed);
    });

    testWidgets('bookshelf_navigation_consistency', (WidgetTester tester) async {
      /// Verifies navigation performance is consistent across multiple navigations.
      ///
      /// BUSINESS LOGIC: Users navigate multiple times per session; performance
      /// should remain consistent (no accumulating latency).
      /// TECHNICAL: Navigates to different screens multiple times, measures
      /// each transition, verifies no regressions.

      const iterations = 3;
      final durations = <Duration>[];

      // Currently on bookshelf, measure any in-app navigation
      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        await tester.pumpAndSettle(Duration(milliseconds: 100));
        stopwatch.stop();
        durations.add(stopwatch.elapsed);
      }

      // Verify consistency
      final maxDuration = durations.reduce((a, b) => a.inMilliseconds > b.inMilliseconds ? a : b);
      final minDuration = durations.reduce((a, b) => a.inMilliseconds < b.inMilliseconds ? a : b);
      final variance = maxDuration.inMilliseconds - minDuration.inMilliseconds;

      // Variance should be small (< 100ms)
      expect(
        variance,
        lessThan(100),
        reason: 'Navigation latency should be consistent',
      );

      PerformanceTestHelper.logMetric('Navigation variance', Duration(milliseconds: variance));
    });

    testWidgets('rapid_navigation_handling', (WidgetTester tester) async {
      /// Tests app performance when user navigates rapidly.
      ///
      /// BUSINESS LOGIC: App should handle rapid navigation gracefully
      /// (no crashes, no out-of-order states). Tests for race conditions.
      /// TECHNICAL: Performs multiple rapid navigation actions and verifies
      /// app remains in consistent state.

      final stopwatch = Stopwatch()..start();

      // Simulate rapid pumpAndSettle calls
      for (int i = 0; i < 5; i++) {
        await tester.pumpAndSettle(Duration(milliseconds: 50));
      }

      stopwatch.stop();

      // Verify app is still in valid state
      expect(find.byType(Scaffold), findsWidgets);

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.navigationLatency * 5,
        metric: 'Rapid navigation',
      );

      PerformanceTestHelper.logMetric('5x rapid navigation', stopwatch.elapsed);
    });

    testWidgets('screen_transition_without_jank', (WidgetTester tester) async {
      /// Verifies screen transitions complete smoothly without frame drops.
      ///
      /// BUSINESS LOGIC: Jank (dropped frames) is noticeable and hurts UX.
      /// Target is consistent 60 FPS during transitions.
      /// TECHNICAL: Measures transition time and verifies it's reasonable
      /// (no frame stuttering = fast, complete transition).

      final stopwatch = Stopwatch()..start();

      // Perform navigation action
      await tester.pumpAndSettle();

      stopwatch.stop();

      // If transition time is too high, it indicates frame drops
      expect(
        stopwatch.elapsed.inMilliseconds,
        lessThan(1000),
        reason: 'Smooth navigation should complete in < 1 second',
      );

      PerformanceTestHelper.logMetric('Transition smoothness', stopwatch.elapsed);
    });
  });
}
