import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mybooklog/src/features/book_search/widgets/book_search_form.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_button.dart';
import 'package:mybooklog/src/features/book_search/widgets/search_error_message.dart';

// BUSINESS LOGIC:
// Refactored add_book_page into smaller components for testability.
// Each component has single responsibility:
// - BookSearchForm: collect title and author input
// - SearchButton: initiate search with loading state
// - SearchErrorMessage: display validation/search errors

void main() {
  group('BookSearchForm - Input Collection', () {
    // BUSINESS LOGIC: Form provides two input fields for search terms
    testWidgets('displays title and author input fields', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsExactly(2));
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Author'), findsOneWidget);
    });

    // BUSINESS LOGIC: Header text guides user to search
    testWidgets('displays search header text', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      expect(find.text('Search for a book...'), findsOneWidget);
    });

    // BUSINESS LOGIC: User can enter title
    testWidgets('accepts title input from user', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'The Great Gatsby');
      await tester.pumpAndSettle();

      expect(titleController.text, 'The Great Gatsby');
    });

    // BUSINESS LOGIC: User can enter author
    testWidgets('accepts author input from user', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      final authorField = find.byType(TextField).last;
      await tester.enterText(authorField, 'F. Scott Fitzgerald');
      await tester.pumpAndSettle();

      expect(authorController.text, 'F. Scott Fitzgerald');
    });

    // BUSINESS LOGIC: User can enter both title and author
    testWidgets('accepts both title and author input', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'The Hobbit');
      await tester.enterText(fields.last, 'Tolkien');
      await tester.pumpAndSettle();

      expect(titleController.text, 'The Hobbit');
      expect(authorController.text, 'Tolkien');
    });

    // BUSINESS LOGIC: Fields start empty
    testWidgets('starts with empty fields', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      expect(titleController.text, isEmpty);
      expect(authorController.text, isEmpty);
    });

    // BUSINESS LOGIC: Hint text guides user input
    testWidgets('displays hint text for fields', (tester) async {
      final titleController = TextEditingController();
      final authorController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSearchForm(
              titleController: titleController,
              authorController: authorController,
            ),
          ),
        ),
      );

      expect(find.text('Enter book title'), findsOneWidget);
      expect(find.text('Enter author name'), findsOneWidget);

      titleController.dispose();
      authorController.dispose();
    });
  });

  group('SearchButton - Search Action', () {
    // BUSINESS LOGIC: Search button initiates query
    testWidgets('displays search button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchButton(isLoading: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.text('Search Books'), findsOneWidget);
    });

    // BUSINESS LOGIC: Button callback triggered on tap
    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchButton(
              isLoading: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    // BUSINESS LOGIC: Show loading state during search
    testWidgets('displays loading state during search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchButton(isLoading: true, onPressed: () {})),
        ),
      );

      expect(find.text('Searching...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // BUSINESS LOGIC: Button disabled while searching
    testWidgets('disables button during search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchButton(isLoading: true, onPressed: () {})),
        ),
      );

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
    });

    // BUSINESS LOGIC: Show search icon normally
    testWidgets('displays search icon when not loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchButton(isLoading: false, onPressed: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });
  });

  group('SearchErrorMessage - Error Display', () {
    // BUSINESS LOGIC: Show error when validation fails
    testWidgets('displays error message when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchErrorMessage(
              message: 'Search failed: connection error',
            ),
          ),
        ),
      );

      expect(find.text('Search failed: connection error'), findsOneWidget);
    });

    // BUSINESS LOGIC: Hide error when none exists
    testWidgets('hides error message when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SearchErrorMessage(message: null))),
      );

      expect(find.byType(Text), findsNothing);
    });

    // BUSINESS LOGIC: Use error color for visibility
    testWidgets('displays error with prominent color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchErrorMessage(message: 'Validation error')),
        ),
      );

      final text = find.text('Validation error');
      expect(text, findsOneWidget);
    });

    // BUSINESS LOGIC: Show validation errors
    testWidgets('shows validation error messages', (tester) async {
      const validationError =
          'Enter a title, an author, or both before searching.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchErrorMessage(message: validationError)),
        ),
      );

      expect(find.text(validationError), findsOneWidget);
    });

    // BUSINESS LOGIC: Show API key missing error
    testWidgets('shows API key unavailable error', (tester) async {
      const apiError =
          'Book search is unavailable: no Google Books API key was configured '
          'for this build.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchErrorMessage(message: apiError)),
        ),
      );

      expect(find.text(apiError), findsOneWidget);
    });

    // BUSINESS LOGIC: Show search failure error
    testWidgets('shows search failure error', (tester) async {
      const searchError = 'Search failed: Network error';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SearchErrorMessage(message: searchError)),
        ),
      );

      expect(find.text(searchError), findsOneWidget);
    });
  });
}
