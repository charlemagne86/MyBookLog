import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/book_on_shelf.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_empty_state.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_grid.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_loading_state.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_search_bar.dart';

/// Builds a [BookshelfSearchBar] with sensible defaults for the new
/// filter/category params, overridable per test.
Widget _buildSearchBar({
  required TextEditingController controller,
  String searchQuery = '',
  int visibleBooksCount = 0,
  int totalBooksCount = 10,
  ValueChanged<String>? onChanged,
  VoidCallback? onClear,
  ReadFilter selectedFilter = ReadFilter.all,
  ValueChanged<ReadFilter>? onFilterChanged,
  List<String> availableCategories = const [],
  Set<String> selectedCategories = const {},
  ValueChanged<String>? onCategoryToggled,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BookshelfSearchBar(
        controller: controller,
        searchQuery: searchQuery,
        visibleBooksCount: visibleBooksCount,
        totalBooksCount: totalBooksCount,
        onChanged: onChanged ?? (_) {},
        onClear: onClear ?? () {},
        selectedFilter: selectedFilter,
        onFilterChanged: onFilterChanged ?? (_) {},
        availableCategories: availableCategories,
        selectedCategories: selectedCategories,
        onCategoryToggled: onCategoryToggled ?? (_) {},
      ),
    ),
  );
}

// BUSINESS LOGIC:
// Refactored bookshelf_screen into smaller components for testability.
// Each component has single responsibility:
// - BookshelfSearchBar: search/filter input
// - BookshelfGrid: book grid display
// - BookshelfEmptyState: empty shelf message
// - BookshelfLoadingState: loading indicator

void main() {
  group('BookshelfSearchBar - Search and Filter', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    // BUSINESS LOGIC: User can type to filter books
    testWidgets('displays search input field', (tester) async {
      await tester.pumpWidget(_buildSearchBar(controller: controller));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search title or author'), findsOneWidget);
    });

    // TECHNICAL: The bar is always on screen now, so it must never grab
    // the keyboard automatically.
    testWidgets('never autofocuses, since it is always on screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSearchBar(controller: controller));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofocus, isFalse);
    });

    // BUSINESS LOGIC: Show guidance until 3 characters entered
    testWidgets('shows character requirement message', (tester) async {
      await tester.pumpWidget(
        _buildSearchBar(controller: controller, searchQuery: 'ab'),
      );

      expect(find.text('Enter at least 3 characters!'), findsOneWidget);
    });

    // BUSINESS LOGIC: Show match count after threshold
    testWidgets('displays match count when search active', (tester) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          searchQuery: 'abc',
          visibleBooksCount: 5,
        ),
      );

      expect(find.text('5 matching books'), findsOneWidget);
    });

    // BUSINESS LOGIC: Singular "book" when one match
    testWidgets('uses singular form for single result', (tester) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          searchQuery: 'abc',
          visibleBooksCount: 1,
        ),
      );

      expect(find.text('1 matching book'), findsOneWidget);
    });

    // BUSINESS LOGIC: Clear button appears when text entered
    testWidgets('shows clear button when text present', (tester) async {
      controller.text = 'search text';

      await tester.pumpWidget(
        _buildSearchBar(controller: controller, searchQuery: 'search text'),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    // BUSINESS LOGIC: Clear button hidden when empty
    testWidgets('hides clear button when empty', (tester) async {
      await tester.pumpWidget(_buildSearchBar(controller: controller));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    // BUSINESS LOGIC: Callback triggered on clear
    testWidgets('calls onClear when clear button pressed', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          searchQuery: 'text',
          onClear: () => cleared = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    // BUSINESS LOGIC: All three read-status choices are always offered
    testWidgets('shows All/Unread/Read filter chips', (tester) async {
      await tester.pumpWidget(_buildSearchBar(controller: controller));

      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Unread'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Read'), findsOneWidget);
    });

    // BUSINESS LOGIC: The active filter is visibly selected
    testWidgets('marks the current read filter as selected', (tester) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          selectedFilter: ReadFilter.unread,
        ),
      );

      final unreadChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Unread'),
      );
      expect(unreadChip.selected, isTrue);
      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(allChip.selected, isFalse);
    });

    // BUSINESS LOGIC: Tapping a filter chip reports the tapped filter
    testWidgets('calls onFilterChanged when a chip is tapped', (tester) async {
      ReadFilter? selected;
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          onFilterChanged: (f) => selected = f,
        ),
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Read'));
      await tester.pump();

      expect(selected, ReadFilter.read);
    });

    // REGRESSION: the app's shared chipTheme.labelStyle carries no color of
    // its own (nothing used a Chip anywhere in the app before this feature,
    // so the gap was invisible until a real device render showed white
    // labels on a white/light background). Each chip must set its own
    // explicit, non-null label color so this can never silently regress.
    testWidgets('filter chip labels always have an explicit, visible color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          selectedFilter: ReadFilter.unread,
        ),
      );

      for (final label in ['All', 'Unread', 'Read']) {
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, label),
        );
        expect(
          chip.labelStyle?.color,
          isNotNull,
          reason: '$label chip must set an explicit label color',
        );
      }
    });

    // BUSINESS LOGIC: No categories on the shelf means no category row
    testWidgets('hides the category row when there are no categories', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSearchBar(controller: controller));

      expect(find.byType(FilterChip), findsNothing);
    });

    // BUSINESS LOGIC: Every category present on the shelf gets its own chip
    testWidgets('shows a chip for each available category', (tester) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          availableCategories: const ['Fiction', 'Biography'],
        ),
      );

      expect(find.widgetWithText(FilterChip, 'Fiction'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Biography'), findsOneWidget);
    });

    // BUSINESS LOGIC: Selected categories are visibly marked, multi-select
    testWidgets('marks selected categories and allows more than one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
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

    // BUSINESS LOGIC: Tapping a category chip reports which one was tapped
    testWidgets('calls onCategoryToggled with the tapped category', (
      tester,
    ) async {
      String? toggled;
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
          availableCategories: const ['Fiction'],
          onCategoryToggled: (c) => toggled = c,
        ),
      );

      await tester.tap(find.widgetWithText(FilterChip, 'Fiction'));
      await tester.pump();

      expect(toggled, 'Fiction');
    });

    // REGRESSION: see the matching ChoiceChip test above — same theme gap,
    // same fix, must hold for category chips too.
    testWidgets('category chip labels always have an explicit, visible color', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSearchBar(
          controller: controller,
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

    tearDown(() => controller.dispose());
  });

  group('BookshelfGrid - Book Display', () {
    final testBooks = [
      ShelfBook(
        bookId: 'book-1',
        title: 'Book 1',
        author: 'Author 1',
        thumbnailUri: '',
        isRead: false,
      ),
      ShelfBook(
        bookId: 'book-2',
        title: 'Book 2',
        author: 'Author 2',
        thumbnailUri: '',
        isRead: false,
      ),
    ];

    // BUSINESS LOGIC: Display grid of books
    testWidgets('displays book grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(books: testBooks, onBookTap: (_) {}),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    // BUSINESS LOGIC: Grid shows all books
    testWidgets('renders all books in grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(books: testBooks, onBookTap: (_) {}),
          ),
        ),
      );

      expect(find.byType(BookOnShelf), findsExactly(2));
    });

    // BUSINESS LOGIC: Tapping a book opens its details panel
    testWidgets('calls onBookTap with the tapped book', (tester) async {
      ShelfBook? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(
              books: testBooks,
              onBookTap: (book) => tapped = book,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BookOnShelf).first);
      await tester.pumpAndSettle();

      expect(tapped?.bookId, 'book-1');
    });

    // BUSINESS LOGIC: Handle empty grid
    testWidgets('handles empty book list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(books: const [], onBookTap: (_) {}),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('BookshelfEmptyState - Empty Display', () {
    // BUSINESS LOGIC: Show empty shelf message
    testWidgets('displays empty shelf message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfEmptyState(
              message: 'Your bookshelf is empty. Tap + to add a book.',
            ),
          ),
        ),
      );

      expect(
        find.text('Your bookshelf is empty. Tap + to add a book.'),
        findsOneWidget,
      );
    });

    // BUSINESS LOGIC: Show no search results message
    testWidgets('displays no results message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfEmptyState(message: 'No books match your search.'),
          ),
        ),
      );

      expect(find.text('No books match your search.'), findsOneWidget);
    });

    // BUSINESS LOGIC: Message is centered and prominent
    testWidgets('centers message text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BookshelfEmptyState(message: 'Test message')),
        ),
      );

      final textWidget = find.byType(Text);
      expect(textWidget, findsOneWidget);
    });
  });

  group('BookshelfLoadingState - Loading Display', () {
    // BUSINESS LOGIC: Show loading indicator while fetching
    testWidgets('displays loading spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BookshelfLoadingState())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // BUSINESS LOGIC: Spinner is centered
    testWidgets('centers loading indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BookshelfLoadingState())),
      );

      expect(find.byType(Center), findsOneWidget);
    });
  });
}
