import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Users can filter their bookshelf by title or author.
/// Filter requires 3+ characters to avoid flickering while typing.
/// Shows count of matching books after search threshold.
///
/// TECHNICAL:
/// Takes controller for external state management.
/// Calls onChanged callback when user types.
/// Calls onClear callback when user taps clear button.
class BookshelfSearchBar extends StatelessWidget {
  const BookshelfSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.visibleBooksCount,
    required this.totalBooksCount,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String searchQuery;
  final int visibleBooksCount;
  final int totalBooksCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final queryLength = searchQuery.trim().length;
    final isSearching = queryLength >= 3;
    final hasText = searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(
            controller: controller,
            autofocus: true,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search title or author',
              helperText: queryLength < 3
                  ? 'Enter at least 3 characters!'
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
          ),
        ),
      ),
    );
  }
}
