/// Widget tests for [BookOnShelf].
///
/// BUSINESS LOGIC:
/// A book with no cover image must still show the plain-green
/// GenericBookCover, not a blank space or a mismatched fallback — this is
/// the shelf-display half of the "cover validation" feature; the other half
/// (choosing which cover to save) is tested in search_results_page_test.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/book_on_shelf.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/generic_book_cover.dart';

void main() {
  group('BookOnShelf', () {
    testWidgets('shows GenericBookCover when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: BookOnShelf(imageUrl: null, title: 'Untitled Book'),
            ),
          ),
        ),
      );

      expect(find.byType(GenericBookCover), findsOneWidget);
    });

    testWidgets('shows GenericBookCover when imageUrl is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: BookOnShelf(imageUrl: '', title: 'No Cover'),
            ),
          ),
        ),
      );

      expect(find.byType(GenericBookCover), findsOneWidget);
    });

    testWidgets('still shows the title beneath a missing cover', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: BookOnShelf(imageUrl: null, title: 'Dune'),
            ),
          ),
        ),
      );

      expect(find.text('Dune'), findsOneWidget);
    });
  });
}
