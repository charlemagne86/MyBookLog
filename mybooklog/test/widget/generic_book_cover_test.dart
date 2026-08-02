/// Widget tests for [GenericBookCover].
///
/// BUSINESS LOGIC:
/// When a book has no working cover image, the shelf must still show
/// *something* that reads as a book — the app's own generic cover artwork —
/// filling exactly the same space a real cover would occupy in that same
/// grid cell, whatever size or aspect ratio that cell happens to be (e.g.
/// if the shelf is ever shown at a different number of books per row).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/generic_book_cover.dart';

void main() {
  group('GenericBookCover', () {
    testWidgets('renders the bundled generic cover artwork', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 150, child: GenericBookCover()),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      expect((image.image as AssetImage).assetName, GenericBookCover.assetPath);
    });

    testWidgets('scales with BoxFit.cover so it never letterboxes', (
      tester,
    ) async {
      // BUSINESS LOGIC: unlike a real cover photo, this placeholder has no
      // "true" aspect ratio to preserve, so it always fills its box
      // completely (BoxFit.cover) rather than risking gaps around the
      // edges the way BoxFit.contain would for a mismatched image.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 150, child: GenericBookCover()),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
    });

    testWidgets(
      'fills its box exactly at the shelf\'s current 3-per-row proportions',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                height: 179,
                child: GenericBookCover(),
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(ClipRRect));
        expect(size, const Size(120, 179));
      },
    );

    testWidgets('fills its box exactly even at a very different aspect ratio '
        '(e.g. a different number of books per row)', (tester) async {
      // A wide, short box — the opposite shape from a normal book cover
      // cell — stands in for "the grid layout changed". No code in
      // GenericBookCover needs to know about that change: BoxFit.cover
      // recomputes against whatever box it's given on every layout pass.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 300, height: 90, child: GenericBookCover()),
          ),
        ),
      );

      final size = tester.getSize(find.byType(ClipRRect));
      expect(size, const Size(300, 90));
    });

    testWidgets(
      'fills its box exactly when placed as a non-positioned Stack child, '
      'like BookOnShelf actually places it',
      (tester) async {
        // BUSINESS LOGIC / REGRESSION: BookOnShelf nests this cover inside a
        // Stack (for the read-badge overlay and press-and-hold lift
        // animation). Stack LOOSENS the constraints it hands its
        // non-positioned child, and an Image doesn't grow to fill loose
        // constraints on its own — a bare SizedBox parent (as in the tests
        // above) doesn't reproduce that and would pass even when the real
        // shelf renders a too-short cover. This test wraps GenericBookCover
        // in a Stack the same way BookOnShelf does, to catch that class of
        // regression directly.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 120,
                height: 179,
                child: Stack(children: [GenericBookCover()]),
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byType(ClipRRect));
        expect(size, const Size(120, 179));
      },
    );

    testWidgets('clips to the given border radius', (tester) async {
      const radius = BorderRadius.all(Radius.circular(12));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 150,
              child: GenericBookCover(borderRadius: radius),
            ),
          ),
        ),
      );

      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, radius);
    });
  });
}
