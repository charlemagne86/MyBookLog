import 'package:flutter/material.dart';

import '../../../data/models/shelf_book.dart';
import 'book_on_shelf.dart';

/// BUSINESS LOGIC:
/// Display user's books in a 3-column grid.
/// Each book opens its details panel on tap.
///
/// TECHNICAL:
/// Takes list of visible books (already filtered).
/// Uses GridView.builder for efficient rendering. Each cell wraps its
/// BookOnShelf in an InkWell so a tap gets standard Material ink feedback
/// before onBookTap opens the details panel.
class BookshelfGrid extends StatelessWidget {
  const BookshelfGrid({
    super.key,
    required this.books,
    required this.onBookTap,
  });

  final List<ShelfBook> books;
  final ValueChanged<ShelfBook> onBookTap;

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

        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => onBookTap(book),
          child: BookOnShelf(
            imageUrl: book.thumbnailUri,
            title: book.title,
            isRead: book.isRead,
          ),
        );
      },
    );
  }
}
