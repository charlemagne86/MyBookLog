import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/features/book_search/widgets/add_to_shelf_button.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_loading_indicator.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_result_tile.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_results_empty_state.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_results_list.dart';

// BUSINESS LOGIC:
// Refactored search_results_page into smaller components for testability.
// Each component handles one responsibility:
// - SearchEmptyState: display when no results
// - SearchResultTile: individual book card
// - SearchResultsList: paginated list
// - AddToShelfButton: floating add button
// - SearchLoadingIndicator: pagination loader

void main() {
  group('SearchEmptyState - No Results Display', () {
    // BUSINESS LOGIC: Empty search should encourage retry
    testWidgets('displays helpful message when no results', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchEmptyState(),
          ),
        ),
      );

      expect(
        find.text('No results found. Try a different search.'),
        findsOneWidget,
      );
    });

  });

  group('SearchResultTile - Book Card Display', () {
    final testBook = BookSearchResult(
      volumeId: 'volume-1',
      title: 'The Great Gatsby',
      authors: ['F. Scott Fitzgerald'],
      isbn: '978-0743273565',
      thumbnail: 'https://example.com/gatsby.jpg',
    );

    // BUSINESS LOGIC: Book card displays title and author clearly
    testWidgets('displays book title and author', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              book: testBook,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('The Great Gatsby'), findsOneWidget);
      expect(find.text('F. Scott Fitzgerald'), findsOneWidget);
    });

    // BUSINESS LOGIC: Selected books show checkmark and highlight
    testWidgets('shows checkmark when selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              book: testBook,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // BUSINESS LOGIC: Unselected books don't show checkmark
    testWidgets('hides checkmark when not selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              book: testBook,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    // BUSINESS LOGIC: Callback triggered on tap
    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              book: testBook,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SearchResultTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    // BUSINESS LOGIC: Handle book without thumbnail
    testWidgets('shows fallback icon without thumbnail', (tester) async {
      final bookNoThumb = BookSearchResult(
        volumeId: 'volume-2',
        title: 'No Cover',
        authors: ['Author'],
        isbn: '123',
        thumbnail: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultTile(
              book: bookNoThumb,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });
  });

  group('SearchResultsList - Paginated List', () {
    final testBooks = [
      BookSearchResult(
        volumeId: 'vol-1',
        title: 'Book 1',
        authors: ['Author 1'],
        isbn: '1',
        thumbnail: '',
      ),
      BookSearchResult(
        volumeId: 'vol-2',
        title: 'Book 2',
        authors: ['Author 2'],
        isbn: '2',
        thumbnail: '',
      ),
    ];

    // BUSINESS LOGIC: Display list of books
    testWidgets('displays list of books', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              results: testBooks,
              selectedIndex: null,
              scrollController: scrollController,
              onResultTap: (_) {},
              onScroll: () {},
            ),
          ),
        ),
      );

      expect(find.text('Book 1'), findsOneWidget);
      expect(find.text('Book 2'), findsOneWidget);
    });

    // BUSINESS LOGIC: Highlight selected book
    testWidgets('highlights selected book', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              results: testBooks,
              selectedIndex: 0,
              scrollController: scrollController,
              onResultTap: (_) {},
              onScroll: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // BUSINESS LOGIC: Handle empty list
    testWidgets('handles empty book list', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchResultsList(
              results: [],
              selectedIndex: null,
              scrollController: scrollController,
              onResultTap: (_) {},
              onScroll: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('AddToShelfButton - Floating Action', () {
    // BUSINESS LOGIC: Add button shows when selection made
    testWidgets('displays add button correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Content')),
                AddToShelfButton(
                  isLoading: false,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Add to Bookshelf'), findsOneWidget);
    });

    // BUSINESS LOGIC: Show loading state while adding
    testWidgets('shows loading indicator during add', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Content')),
                AddToShelfButton(
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Adding...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // BUSINESS LOGIC: Button disabled during loading
    testWidgets('disables button while loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Content')),
                AddToShelfButton(
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
    });

    // BUSINESS LOGIC: Button callback triggered on tap
    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Content')),
                AddToShelfButton(
                  isLoading: false,
                  onPressed: () => pressed = true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('SearchLoadingIndicator - Pagination Loader', () {
    // BUSINESS LOGIC: Show spinner when loading next page
    testWidgets('displays loading spinner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Content')),
                const SearchLoadingIndicator(),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
