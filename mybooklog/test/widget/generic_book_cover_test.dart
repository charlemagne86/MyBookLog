/// Widget tests for [GenericBookCover].
///
/// BUSINESS LOGIC:
/// When a book has no working cover image, the shelf must still show
/// *something* that reads as a book — the app's own generic cover artwork —
/// rather than a broken-image icon or an empty space.
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
