import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Users can narrow their bookshelf by title/author text. This bar only
/// appears when the user taps the AppBar's search icon, and covers the
/// filter-chip row beneath it while open (full width, same compact height)
/// so switching between text search and the read/unread + category chips
/// never costs extra vertical space.
///
/// TECHNICAL:
/// Text search requires 3+ characters to actually filter (avoids flicker
/// while typing), but no guidance text is shown for that — the field is
/// self-explanatory once opened deliberately, and skipping the helper line
/// keeps the field visually crisp/compact.
class BookshelfSearchBar extends StatelessWidget {
  const BookshelfSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.visibleBooksCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchQuery;
  final int visibleBooksCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final queryLength = searchQuery.trim().length;
    final hasText = searchQuery.trim().isNotEmpty;

    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintText: 'Search title or author',
        helperText: queryLength < 3
            ? null
            : '$visibleBooksCount matching '
                  '${visibleBooksCount == 1 ? 'book' : 'books'}',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: !hasText
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: onClear,
              ),
      ),
    );
  }
}
