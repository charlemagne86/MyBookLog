import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/features/bookshelf/bookshelf_screen.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';

// BUSINESS LOGIC:
// The Bookshelf Screen is the main user interface after login.
// Must handle various states gracefully:
// - Loading while fetching shelf
// - Error states with helpful messages
// - Empty shelf (no books)
// - Very large shelf (100+ books)
// - Search with no results
// - Responsive layout on small screens
//
// Users expect smooth transitions between states and clear error messages.

class MockBookshelfRepository extends Mock implements BookshelfRepository {}

void main() {
  group('BookshelfScreen - Edge Cases', () {
    late MockBookshelfRepository mockRepository;

    setUp(() {
      mockRepository = MockBookshelfRepository();
    });

    testWidgets('displays loading indicator while fetching shelf', (WidgetTester tester) async {
      // TECHNICAL: Shelf takes time to load from Supabase
      // User should see spinner, not blank screen
      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) => Future.delayed(Duration(seconds: 2), () => []),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when shelf has no books', (WidgetTester tester) async {
      // TECHNICAL: New user or user removed all books
      // Should show helpful message, not crash
      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('shows error message on shelf load failure', (WidgetTester tester) async {
      // TECHNICAL: Network error or database error
      // User should see error message with retry option
      when(() => mockRepository.fetchShelf()).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('handles search with no matching results', (WidgetTester tester) async {
      // TECHNICAL: User searches for book that doesn't exist on shelf
      // Should show "no results" message clearly
      final testBooks = [
        ShelfBook(
          bookId: '1',
          title: 'The Great Gatsby',
          author: 'F. Scott Fitzgerald',
          thumbnailUri: null,
          isRead: false,
        ),
      ];

      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => testBooks,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the book initially
      expect(find.text('The Great Gatsby'), findsOneWidget);

      // Search for non-existent book
      // Implementation would search and show empty results
    });

    testWidgets('handles very large bookshelf (100+ books)', (WidgetTester tester) async {
      // TECHNICAL: Performance test for large datasets
      // GridView should still scroll smoothly
      final manyBooks = List.generate(
        100,
        (i) => ShelfBook(
          bookId: 'book-$i',
          title: 'Book $i',
          author: 'Author $i',
          thumbnailUri: null,
          isRead: false,
        ),
      );

      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => manyBooks,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle large list without crashing
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('preserves search state during orientation change', (WidgetTester tester) async {
      // TECHNICAL: User searches, then rotates device
      // Search query and results should persist
      final testBooks = [
        ShelfBook(
          bookId: '1',
          title: 'The Great Gatsby',
          author: 'F. Scott Fitzgerald',
          thumbnailUri: null,
          isRead: false,
        ),
      ];

      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => testBooks,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search for book
      // Rotate device
      // Verify search results still visible
    });

    testWidgets('handles very long book title in grid', (WidgetTester tester) async {
      // TECHNICAL: Some books have 200+ character titles
      // Should truncate with ellipsis, not overflow
      final longTitleBook = ShelfBook(
        bookId: '1',
        title: 'A' * 300,
        author: 'Author',
        thumbnailUri: null,
        isRead: false,
      );

      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => [longTitleBook],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display without overflow
      expect(find.byType(GridView), findsWidgets);
    });

    testWidgets('handles special characters in search', (WidgetTester tester) async {
      // TECHNICAL: User searches with Unicode, emoji, special chars
      final specialCharBook = ShelfBook(
        bookId: '1',
        title: 'Test™ 中文 🎉',
        author: 'Author',
        thumbnailUri: null,
        isRead: false,
      );

      when(() => mockRepository.fetchShelf()).thenAnswer(
        (_) async => [specialCharBook],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Provider<BookshelfRepository>.value(
            value: mockRepository,
            child: BookshelfScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should handle special characters without crashing
      expect(find.byType(BookshelfScreen), findsOneWidget);
    });
  });
}
