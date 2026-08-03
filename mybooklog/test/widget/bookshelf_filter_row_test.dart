/// Widget tests for [BookshelfFilterRow].
///
/// BUSINESS LOGIC:
/// This is the compact, always-visible row above the shelf grid: a single
/// fixed-width chip for read/unread status (so it never resizes and shifts
/// the divider/category chips next to it as the selection changes), plus
/// one multi-select chip per category present anywhere on the shelf.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_filter_row.dart';

void main() {
  Widget buildRow({
    ReadFilter selectedFilter = ReadFilter.all,
    ValueChanged<ReadFilter>? onFilterChanged,
    List<String> availableCategories = const [],
    Set<String> selectedCategories = const {},
    ValueChanged<String>? onCategoryToggled,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BookshelfFilterRow(
          selectedFilter: selectedFilter,
          onFilterChanged: onFilterChanged ?? (_) {},
          availableCategories: availableCategories,
          selectedCategories: selectedCategories,
          onCategoryToggled: onCategoryToggled ?? (_) {},
        ),
      ),
    );
  }

  group('BookshelfFilterRow', () {
    group('read/unread chip', () {
      // The chip also renders an invisible "Unread" ghost label (to reserve
      // width for the longest option), so lookups target the real, visible
      // label by key rather than by text to avoid matching both.
      const labelKey = ValueKey('read_filter_chip_label');

      testWidgets('shows the current selection\'s label', (tester) async {
        await tester.pumpWidget(buildRow(selectedFilter: ReadFilter.unread));

        expect(tester.widget<Text>(find.byKey(labelKey)).data, 'Unread');
      });

      testWidgets('defaults to "All"', (tester) async {
        await tester.pumpWidget(buildRow());

        expect(tester.widget<Text>(find.byKey(labelKey)).data, 'All');
      });

      // REGRESSION: the chip must stay the same width across all three
      // selections (sized for the longest label) so the divider and
      // category chips next to it never shift.
      testWidgets('stays the same width for All, Unread, and Read', (
        tester,
      ) async {
        final widths = <double>[];
        for (final filter in ReadFilter.values) {
          await tester.pumpWidget(buildRow(selectedFilter: filter));
          widths.add(
            tester.getSize(find.byType(PopupMenuButton<ReadFilter>)).width,
          );
        }
        expect(widths.toSet(), hasLength(1));
      });

      testWidgets('opens a menu with All/Unread/Read and reports the pick', (
        tester,
      ) async {
        ReadFilter? picked;
        await tester.pumpWidget(buildRow(onFilterChanged: (f) => picked = f));

        await tester.tap(find.byType(PopupMenuButton<ReadFilter>));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(PopupMenuItem<ReadFilter>, 'All'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(PopupMenuItem<ReadFilter>, 'Unread'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(PopupMenuItem<ReadFilter>, 'Read'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(PopupMenuItem<ReadFilter>, 'Read'),
        );
        await tester.pumpAndSettle();

        expect(picked, ReadFilter.read);
      });
    });

    group('divider', () {
      testWidgets('hidden when the shelf has no categories', (tester) async {
        await tester.pumpWidget(buildRow());

        expect(find.byType(VerticalDivider), findsNothing);
      });

      testWidgets('shown once at least one category exists', (tester) async {
        await tester.pumpWidget(
          buildRow(availableCategories: const ['Fiction']),
        );

        expect(find.byType(VerticalDivider), findsOneWidget);
      });
    });

    group('category chips', () {
      testWidgets('one chip per available category', (tester) async {
        await tester.pumpWidget(
          buildRow(availableCategories: const ['Fiction', 'Biography']),
        );

        expect(find.widgetWithText(FilterChip, 'Fiction'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Biography'), findsOneWidget);
      });

      testWidgets('marks selected categories, allows more than one', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildRow(
            availableCategories: const ['Fiction', 'Biography'],
            selectedCategories: const {'Fiction', 'Biography'},
          ),
        );

        final fiction = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Fiction'),
        );
        final biography = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'Biography'),
        );
        expect(fiction.selected, isTrue);
        expect(biography.selected, isTrue);
      });

      testWidgets('tapping a chip reports which category was tapped', (
        tester,
      ) async {
        String? toggled;
        await tester.pumpWidget(
          buildRow(
            availableCategories: const ['Fiction'],
            onCategoryToggled: (c) => toggled = c,
          ),
        );

        await tester.tap(find.widgetWithText(FilterChip, 'Fiction'));
        await tester.pump();

        expect(toggled, 'Fiction');
      });

      // REGRESSION: the app's shared chipTheme.labelStyle carries no color
      // of its own — each chip must set one explicitly so labels are never
      // white-on-white/green-on-green.
      testWidgets('labels always have an explicit, visible color', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildRow(
            availableCategories: const ['Fiction', 'Biography'],
            selectedCategories: const {'Fiction'},
          ),
        );

        for (final label in ['Fiction', 'Biography']) {
          final chip = tester.widget<FilterChip>(
            find.widgetWithText(FilterChip, label),
          );
          expect(
            chip.labelStyle?.color,
            isNotNull,
            reason: '$label chip must set an explicit label color',
          );
        }
      });

      testWidgets('does not push the read/unread chip out when there are many '
          'categories', (tester) async {
        await tester.pumpWidget(
          buildRow(
            availableCategories: List.generate(20, (i) => 'Category $i'),
          ),
        );

        // The row must still fit on screen without a horizontal overflow
        // error — the category list scrolls internally instead.
        expect(tester.takeException(), isNull);
        expect(find.byType(PopupMenuButton<ReadFilter>), findsOneWidget);
      });
    });
  });
}
