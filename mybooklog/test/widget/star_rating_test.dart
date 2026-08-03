/// Widget tests for [StarRating].
///
/// BUSINESS LOGIC:
/// This is the one control a user has to say "I liked this book" — it needs
/// to show the right number of filled stars for whatever rating a book
/// currently has, and to report exactly which star was tapped so the book
/// details panel can save it. It also doubles as a read-only display for
/// Google's own rating, so tapping must never do anything when there's no
/// [StarRating.onRate] callback to call.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/star_rating.dart';

void main() {
  group('StarRating', () {
    testWidgets('fills stars up to the given rating, leaves the rest '
        'outlined', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: 3))),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('shows every star outlined when rating is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: null))),
      );

      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('shows every star outlined when rating is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: 0))),
      );

      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('shows all stars filled at the maximum rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: 5))),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(5));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('respects a custom starCount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StarRating(rating: 2, starCount: 3)),
        ),
      );

      expect(find.byIcon(Icons.star), findsNWidgets(2));
      expect(find.byIcon(Icons.star_border), findsNWidgets(1));
    });

    testWidgets('tapping star N reports a rating of N', (tester) async {
      int? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(rating: 0, onRate: (r) => reported = r),
          ),
        ),
      );

      // The stars render left-to-right in order, so the 4th icon in the
      // tree is star number 4.
      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.pump();

      expect(reported, 4);
    });

    testWidgets('tapping the first star reports a rating of 1', (tester) async {
      int? reported;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StarRating(rating: 0, onRate: (r) => reported = r),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pump();

      expect(reported, 1);
    });

    testWidgets('read-only mode (onRate: null) does not throw on tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: 3))),
      );

      // No InkResponse to hit in read-only mode; tapping the icon directly
      // must be a no-op rather than throwing (e.g. a null-callback call).
      await tester.tap(find.byIcon(Icons.star).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes a semantics label describing the current rating', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StarRating(rating: 3))),
      );

      expect(find.bySemanticsLabel('Rating: 3 out of 5 stars'), findsOneWidget);
      handle.dispose();
    });
  });
}
