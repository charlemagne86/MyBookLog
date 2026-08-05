/// Widget tests for [BookDetailsPanel].
///
/// BUSINESS LOGIC:
/// This panel is now the one place to see a book's details and act on it
/// (mark read/unread, rate, remove). Google supplies its detail fields
/// inconsistently — verified live against real API responses, where e.g.
/// "The Hobbit" had no averageRating, ratingsCount, or subtitle at all — so
/// every optional field must render when present and disappear cleanly when
/// not, never crash or show a blank gap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/book_details_panel.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/star_rating.dart';

void main() {
  const fullBook = ShelfBook(
    bookId: 'book-1',
    title: 'Dune',
    author: 'Frank Herbert',
    thumbnailUri: '',
    isRead: false,
    rating: 3,
    description: 'A long synopsis about politics, spice, and sandworms.',
    pageCount: 412,
    publishedDate: '1965-08-01',
    publisher: 'Chilton Books',
    categories: ['Fiction', 'Science Fiction'],
    googleAverageRating: 4.5,
    googleRatingsCount: 3000,
  );

  const bareBook = ShelfBook(
    bookId: 'book-2',
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    thumbnailUri: '',
    isRead: false,
    // Every optional field left at its default (null/empty) — mirrors a
    // real Google response that omitted them.
  );

  /// Opens the panel the same way the real shelf does: via
  /// showModalBottomSheet from a Scaffold, so Navigator.pop() inside the
  /// panel (on a successful remove) has a real sheet to close.
  Future<void> pumpPanel(
    WidgetTester tester, {
    required ShelfBook book,
    Future<void> Function()? onToggleRead,
    Future<void> Function(int?)? onRate,
    Future<void> Function()? onRemove,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => BookDetailsPanel(
                  book: book,
                  onToggleRead: onToggleRead ?? () async {},
                  onRate: onRate ?? (_) async {},
                  onRemove: onRemove ?? () async {},
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('BookDetailsPanel', () {
    testWidgets('shows the title and author', (tester) async {
      await pumpPanel(tester, book: fullBook);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Frank Herbert'), findsOneWidget);
    });

    group('read/unread', () {
      testWidgets('shows "Mark as Read" for an unread book', (tester) async {
        await pumpPanel(tester, book: fullBook);

        expect(find.text('Mark as Read'), findsOneWidget);
      });

      testWidgets('shows "Mark as Unread" for a read book', (tester) async {
        await pumpPanel(tester, book: fullBook.copyWith(isRead: true));

        expect(find.text('Mark as Unread'), findsOneWidget);
      });

      testWidgets('tapping the button flips the label immediately and calls '
          'onToggleRead', (tester) async {
        var called = false;
        await pumpPanel(
          tester,
          book: fullBook,
          onToggleRead: () async {
            called = true;
          },
        );

        await tester.tap(find.text('Mark as Read'));
        await tester.pumpAndSettle();

        expect(called, isTrue);
        expect(find.text('Mark as Unread'), findsOneWidget);
      });

      testWidgets('rolls back the flip if onToggleRead fails', (tester) async {
        await pumpPanel(
          tester,
          book: fullBook,
          onToggleRead: () async => throw Exception('network error'),
        );

        await tester.tap(find.text('Mark as Read'));
        await tester.pumpAndSettle();

        // Back to the original, unread label — the optimistic flip was
        // undone rather than left showing a save that didn't happen.
        expect(find.text('Mark as Read'), findsOneWidget);
      });
    });

    group('rating', () {
      testWidgets('shows the book\'s current rating', (tester) async {
        await pumpPanel(tester, book: fullBook);

        final stars = tester.widget<StarRating>(find.byType(StarRating));
        expect(stars.rating, 3);
      });

      testWidgets('tapping a star calls onRate with that star\'s number', (
        tester,
      ) async {
        int? reported;
        await pumpPanel(
          tester,
          book: fullBook,
          onRate: (r) async => reported = r,
        );

        // fullBook starts at 3 stars filled, 2 outlined; tap the first
        // outlined star (the 4th star overall).
        await tester.tap(find.byIcon(Icons.star_border).first);
        await tester.pumpAndSettle();

        expect(reported, 4);
      });

      testWidgets('rolls back the rating if onRate fails', (tester) async {
        await pumpPanel(
          tester,
          book: fullBook,
          onRate: (_) async => throw Exception('network error'),
        );

        await tester.tap(find.byIcon(Icons.star_border).first);
        await tester.pumpAndSettle();

        final stars = tester.widget<StarRating>(find.byType(StarRating));
        expect(stars.rating, 3); // back to the original
      });

      testWidgets('tapping the star matching the current rating clears it and '
          'calls onRate with null', (tester) async {
        int? reported = -1; // sentinel so "still -1" means "never called"
        await pumpPanel(
          tester,
          book: fullBook,
          onRate: (r) async => reported = r,
        );

        // fullBook starts at 3 stars filled; tapping the 3rd filled star
        // again should clear the rating rather than re-set it to 3.
        await tester.tap(find.byIcon(Icons.star).at(2));
        await tester.pumpAndSettle();

        expect(reported, isNull);
        final stars = tester.widget<StarRating>(find.byType(StarRating));
        expect(stars.rating, isNull);
      });
    });

    group('Google\'s rating', () {
      testWidgets('shown, distinctly labeled, when present', (tester) async {
        await pumpPanel(tester, book: fullBook);

        expect(find.textContaining('Google rating: 4.5'), findsOneWidget);
        expect(find.textContaining('3000 ratings'), findsOneWidget);
      });

      testWidgets('hidden entirely when Google never supplied one', (
        tester,
      ) async {
        await pumpPanel(tester, book: bareBook);

        expect(find.textContaining('Google rating'), findsNothing);
      });
    });

    group('description', () {
      testWidgets('shown when present', (tester) async {
        await pumpPanel(tester, book: fullBook);

        expect(
          find.textContaining('politics, spice, and sandworms'),
          findsOneWidget,
        );
      });

      testWidgets('hidden entirely when absent', (tester) async {
        await pumpPanel(tester, book: bareBook);

        expect(find.text('Read more'), findsNothing);
      });

      testWidgets('a long description collapses behind "Read more", which '
          'expands it', (tester) async {
        final longDescription = 'Word ' * 100; // well over the threshold
        await pumpPanel(
          tester,
          book: ShelfBook(
            bookId: 'book-3',
            title: 'Long Description Book',
            author: 'Author',
            thumbnailUri: '',
            isRead: false,
            description: longDescription,
          ),
        );

        expect(find.text('Read more'), findsOneWidget);

        await tester.ensureVisible(find.text('Read more'));
        await tester.tap(find.text('Read more'));
        await tester.pumpAndSettle();

        expect(find.text('Show less'), findsOneWidget);
      });

      testWidgets('a short description shows in full with no toggle', (
        tester,
      ) async {
        await pumpPanel(
          tester,
          book: const ShelfBook(
            bookId: 'book-4',
            title: 'Short Description Book',
            author: 'Author',
            thumbnailUri: '',
            isRead: false,
            description: 'Short blurb.',
          ),
        );

        expect(find.text('Read more'), findsNothing);
        expect(find.textContaining('Short blurb.'), findsOneWidget);
      });

      testWidgets('strips simple HTML and decodes entities', (tester) async {
        await pumpPanel(
          tester,
          book: const ShelfBook(
            bookId: 'book-5',
            title: 'HTML Description Book',
            author: 'Author',
            thumbnailUri: '',
            isRead: false,
            description: '<p>Tom &amp; Jerry&#39;s <b>big</b> adventure</p>',
          ),
        );

        expect(find.text('Tom & Jerry\'s big adventure'), findsOneWidget);
      });
    });

    group('page count / published date / publisher', () {
      testWidgets('shown together when all are present', (tester) async {
        await pumpPanel(tester, book: fullBook);

        expect(find.text('412 pages · 1965 · Chilton Books'), findsOneWidget);
      });

      testWidgets('hidden entirely when none are present', (tester) async {
        await pumpPanel(tester, book: bareBook);

        expect(find.textContaining('pages'), findsNothing);
      });
    });

    group('categories', () {
      testWidgets('shows a chip per category', (tester) async {
        await pumpPanel(tester, book: fullBook);

        expect(find.widgetWithText(Chip, 'Fiction'), findsOneWidget);
        expect(find.widgetWithText(Chip, 'Science Fiction'), findsOneWidget);
      });

      testWidgets('shows no chips when there are no categories', (
        tester,
      ) async {
        await pumpPanel(tester, book: bareBook);

        expect(find.byType(Chip), findsNothing);
      });

      // REGRESSION: the app's shared chipTheme.labelStyle carries no color
      // of its own (nothing used a Chip anywhere in the app before this
      // feature, so the gap was invisible until a real device render showed
      // white labels on a white background). Must set an explicit color.
      testWidgets('category chip labels always have an explicit, visible '
          'color', (tester) async {
        await pumpPanel(tester, book: fullBook);

        for (final label in ['Fiction', 'Science Fiction']) {
          final chip = tester.widget<Chip>(find.widgetWithText(Chip, label));
          expect(
            chip.labelStyle?.color,
            isNotNull,
            reason: '$label chip must set an explicit label color',
          );
        }
      });
    });

    group('remove', () {
      testWidgets('tapping Remove shows a confirmation naming the book', (
        tester,
      ) async {
        await pumpPanel(tester, book: fullBook);

        await tester.ensureVisible(find.text('Remove from Shelf'));
        await tester.tap(find.text('Remove from Shelf'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.textContaining('Dune'), findsWidgets);
      });

      testWidgets('Cancel never calls onRemove and keeps the panel open', (
        tester,
      ) async {
        var called = false;
        await pumpPanel(
          tester,
          book: fullBook,
          onRemove: () async => called = true,
        );

        await tester.ensureVisible(find.text('Remove from Shelf'));
        await tester.tap(find.text('Remove from Shelf'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(called, isFalse);
        expect(find.byType(BookDetailsPanel), findsOneWidget);
      });

      testWidgets('confirming Remove calls onRemove and closes the panel', (
        tester,
      ) async {
        var called = false;
        await pumpPanel(
          tester,
          book: fullBook,
          onRemove: () async => called = true,
        );

        await tester.ensureVisible(find.text('Remove from Shelf'));
        await tester.tap(find.text('Remove from Shelf'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        expect(called, isTrue);
        expect(find.byType(BookDetailsPanel), findsNothing);
      });
    });
  });
}
