import 'package:flutter/material.dart';

import '../../../data/models/shelf_book.dart';
import 'book_on_shelf.dart';

/// BUSINESS LOGIC:
/// Display user's books in a 3-column grid.
/// Each book is tappable for context menu (remove/read-status).
/// Highlighted book shows visual lift effect.
///
/// TECHNICAL:
/// Takes list of visible books (already filtered).
/// Takes callbacks for long-press and book selection state.
/// Uses GridView.builder for efficient rendering.
/// Shows tactile feedback via isContextMenuTarget property.
class BookshelfGrid extends StatelessWidget {
  const BookshelfGrid({
    super.key,
    required this.books,
    required this.selectedBookId,
    required this.onBookLongPress,
  });

  final List<ShelfBook> books;
  final String? selectedBookId;
  final Function(ShelfBook book, Offset globalPosition) onBookLongPress;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 0.44,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final isSelected = selectedBookId == book.bookId;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (details) =>
              onBookLongPress(book, details.globalPosition),
          child: BookOnShelf(
            imageUrl: book.thumbnailUri,
            title: book.title,
            isRead: book.isRead,
            isContextMenuTarget: isSelected,
          ),
        );
      },
    );
  }
}
