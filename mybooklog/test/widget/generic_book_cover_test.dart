/// Widget tests for [GenericBookCover].
///
/// BUSINESS LOGIC:
/// When a book has no working cover image, the shelf must still show
/// *something* that reads as a book — a plain green cover in the app's own
/// accent color — rather than a broken-image icon or a jarring mismatched
/// color. The exact shade matters: it must be the app's real accent green,
/// not an approximation, so the fallback looks intentional.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/core/theme/app_colors.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/generic_book_cover.dart';

void main() {
  group('GenericBookCover', () {
    testWidgets('fills its background with the app\'s accent green', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 150, child: GenericBookCover()),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, AppColors.accentSage);
    });

    testWidgets('shows a centered book icon in white for contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 100, height: 150, child: GenericBookCover()),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.menu_book);
      expect(icon.color, AppColors.white);
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
