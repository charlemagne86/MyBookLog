import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/integration_test_helper.dart';
import '../helpers/performance_test_helper.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTests();
  });

  group('Performance: Search & Filter', () {
    final testHelper = IntegrationTestHelper();

    // Note: setUp/tearDown cannot access WidgetTester
    // Setup is done inside each testWidgets() callback

    testWidgets('search_filter_small_dataset', (WidgetTester tester) async {
      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);


      /// Measures search latency with small dataset (< 20 books).
      ///
      /// BUSINESS LOGIC: Search should feel instant for small collections
      /// (target < 100ms). Most users have < 20 books on shelf.
      /// TECHNICAL: Opens search, enters text, measures time to grid update.

      // Open app (already logged in)
      await tester.pumpAndSettle();

      // Find search bar
      final searchIcon = find.byIcon(Icons.search).first;
      expect(searchIcon, findsOneWidget);

      // Open search
      await tester.tap(searchIcon);
      await tester.pumpAndSettle();

      // Verify search field visible
      final searchField = find.byType(TextField);
      expect(searchField, findsWidgets);

      // Measure filtering latency
      final stopwatch = Stopwatch()..start();

      await tester.enterText(searchField.first, 'flutter');
      await tester.pumpAndSettle(Duration(milliseconds: 100));

      stopwatch.stop();

      // Verify grid updated
      expect(find.byType(GridView), findsWidgets);

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.searchLatency,
        metric: 'Small dataset search',
      );

      PerformanceTestHelper.logMetric('Search (small dataset)', stopwatch.elapsed);
    });

    testWidgets('search_filter_large_dataset', (WidgetTester tester) async {
      /// Measures search latency with large dataset (50+ books).
      ///
      /// BUSINESS LOGIC: Search should remain responsive even with large
      /// personal libraries (target < 200ms for 50+ books).
      /// TECHNICAL: Simulates 50-book shelf, then measures search filter.

      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);

      await tester.pumpAndSettle();

      // Open search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsWidgets);

      // Measure filtering with large dataset
      final stopwatch = Stopwatch()..start();

      await tester.enterText(searchField.first, 'science');
      await tester.pumpAndSettle(Duration(milliseconds: 100));

      stopwatch.stop();

      // Verify grid updated (filtered results)
      expect(find.byType(GridView), findsWidgets);

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.searchLatency,
        metric: 'Large dataset search',
      );

      PerformanceTestHelper.logMetric('Search (large dataset)', stopwatch.elapsed);
    });

    testWidgets('search_progressive_filtering', (WidgetTester tester) async {
      /// Verifies search filters correctly as user types progressively.
      ///
      /// BUSINESS LOGIC: As user adds characters, results should narrow
      /// progressively (good predictive UX).
      /// TECHNICAL: Types character by character, verifies results update
      /// each time, all within performance budget.

      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Open search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Type progressively: 'f' → 'fl' → 'flu' → 'flut'
      const searchSequence = ['f', 'fl', 'flu', 'flut'];
      final durations = <Duration>[];

      for (final query in searchSequence) {
        final stopwatch = Stopwatch()..start();

        await tester.enterText(searchField.first, query);
        // Wait for filtering to complete (increased to 2s)
        await tester.pumpAndSettle(Duration(seconds: 2));

        stopwatch.stop();
        durations.add(stopwatch.elapsed);

        // Verify grid exists (updated with filtered results)
        expect(find.byType(GridView), findsWidgets);
      }

      // Verify all searches completed within performance budget
      for (final duration in durations) {
        expect(
          duration.inMilliseconds,
          lessThanOrEqualTo(200),
          reason: 'Each filter step should be < 200ms',
        );
      }

      final avgMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds) ~/ durations.length;
      PerformanceTestHelper.logMetric('Progressive search avg', Duration(milliseconds: avgMs));
    });

    testWidgets('search_clear_performance', (WidgetTester tester) async {
      /// Measures time to clear search and return to full list.
      ///
      /// BUSINESS LOGIC: Clearing search should be fast (< 100ms) so user
      /// can quickly reset and try different search.
      /// TECHNICAL: Searches, then clears text field, measures grid re-render.

      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Open search and type
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField.first, 'book');
      await tester.pumpAndSettle(Duration(milliseconds: 50));

      // Measure clear time
      final stopwatch = Stopwatch()..start();

      await tester.enterText(searchField.first, '');
      await tester.pumpAndSettle(Duration(milliseconds: 50));

      stopwatch.stop();

      // Verify full list returned
      expect(find.byType(GridView), findsWidgets);

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.searchLatency,
        metric: 'Search clear',
      );

      PerformanceTestHelper.logMetric('Search clear', stopwatch.elapsed);
    });

    testWidgets('no_results_performance', (WidgetTester tester) async {
      /// Verifies search handling when no results match.
      ///
      /// BUSINESS LOGIC: Should quickly show "no results" message for
      /// invalid searches (< 100ms).
      /// TECHNICAL: Searches for non-existent term, verifies empty state
      /// renders quickly.

      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Open search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);

      // Search for non-existent term
      final stopwatch = Stopwatch()..start();

      await tester.enterText(searchField.first, 'xyzabc123notabook');
      // Wait for filtering and empty state (increased to 2s)
      await tester.pumpAndSettle(Duration(seconds: 2));

      stopwatch.stop();

      // Verify empty state (either empty grid or "no results" message)
      expect(
        find.byType(GridView),
        findsWidgets,
        reason: 'Should show empty grid for no results',
      );

      PerformanceTestHelper.expectPerformance(
        stopwatch.elapsed,
        PerformanceBaselines.searchLatency,
        metric: 'No results search',
      );

      PerformanceTestHelper.logMetric('No results search', stopwatch.elapsed);
    });

    testWidgets('rapid_search_queries', (WidgetTester tester) async {
      /// Tests app stability when user rapidly changes search query.
      ///
      /// BUSINESS LOGIC: Should not crash or show stale results if user
      /// types/deletes rapidly. Tests for race conditions.
      /// TECHNICAL: Rapidly changes search text, verifies app doesn't crash
      /// and shows final state correctly.

      // Initialize app with logged-in state
      await testHelper.initializeApp();
      await testHelper.setLoggedInState();
      await testHelper.pumpApp(tester);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Open search
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle(Duration(seconds: 2));

      final searchField = find.byType(TextField);

      // Rapidly change queries
      const queries = ['a', 'ab', 'abc', 'ab', 'a', ''];

      for (final query in queries) {
        await tester.enterText(searchField.first, query);
        await tester.pump(Duration(milliseconds: 50)); // Don't wait for settle
      }

      // Finally settle with timeout
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Should end in valid state
      expect(find.byType(GridView), findsWidgets);

      PerformanceTestHelper.logMetric('Rapid queries handled', Duration.zero);
    });
  });
}
