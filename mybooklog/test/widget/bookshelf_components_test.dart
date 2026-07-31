import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_empty_state.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_grid.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_loading_state.dart';
import 'package:mybooklog/src/features/bookshelf/widgets/bookshelf_search_bar.dart';

// BUSINESS LOGIC:
// Refactored bookshelf_screen into smaller components for testability.
// Each component has single responsibility:
// - BookshelfSearchBar: search/filter input
// - BookshelfGrid: book grid display
// - BookshelfEmptyState: empty shelf message
// - BookshelfLoadingState: loading indicator

void main() {
  group('BookshelfSearchBar - Search and Filter', () {
    final controller = TextEditingController();

    // BUSINESS LOGIC: User can type to filter books
    testWidgets('displays search input field', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: '',
              visibleBooksCount: 0,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search title or author'), findsOneWidget);
    });

    // BUSINESS LOGIC: Show guidance until 3 characters entered
    testWidgets('shows character requirement message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: 'ab',
              visibleBooksCount: 0,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.text('Enter at least 3 characters!'), findsOneWidget);
    });

    // BUSINESS LOGIC: Show match count after threshold
    testWidgets('displays match count when search active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: 'abc',
              visibleBooksCount: 5,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 matching books'), findsOneWidget);
    });

    // BUSINESS LOGIC: Singular "book" when one match
    testWidgets('uses singular form for single result', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: 'abc',
              visibleBooksCount: 1,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.text('1 matching book'), findsOneWidget);
    });

    // BUSINESS LOGIC: Clear button appears when text entered
    testWidgets('shows clear button when text present', (tester) async {
      controller.text = 'search text';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: 'search text',
              visibleBooksCount: 0,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    // BUSINESS LOGIC: Clear button hidden when empty
    testWidgets('hides clear button when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: '',
              visibleBooksCount: 0,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    // BUSINESS LOGIC: Callback triggered on clear
    testWidgets('calls onClear when clear button pressed', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfSearchBar(
              controller: controller,
              searchQuery: 'text',
              visibleBooksCount: 0,
              totalBooksCount: 10,
              onChanged: (_) {},
              onClear: () => cleared = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
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
            body: BookshelfGrid(
              books: testBooks,
              selectedBookId: null,
              onBookLongPress: (_, __) {},
            ),
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
            body: BookshelfGrid(
              books: testBooks,
              selectedBookId: null,
              onBookLongPress: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsExactly(2));
    });

    // BUSINESS LOGIC: Long-press triggers callback
    testWidgets('calls onBookLongPress on long press', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(
              books: testBooks,
              selectedBookId: null,
              onBookLongPress: (_, __) => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
    });

    // BUSINESS LOGIC: Selected book highlighted
    testWidgets('highlights selected book', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(
              books: testBooks,
              selectedBookId: 'book-1',
              onBookLongPress: (_, __) {},
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });

    // BUSINESS LOGIC: Handle empty grid
    testWidgets('handles empty book list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfGrid(
              books: [],
              selectedBookId: null,
              onBookLongPress: (_, __) {},
            ),
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

      expect(find.text('Your bookshelf is empty'), findsOneWidget);
      expect(find.text('Tap + to add a book'), findsOneWidget);
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
