import 'package:flutter/material.dart';

import '../../../data/models/book_search_result.dart';
import 'search_result_tile.dart';

/// BUSINESS LOGIC:
/// Display paginated list of book search results in scrollable view.
/// Supports pagination: detects scroll near bottom and loads more results.
/// Automatically adjusts padding when button appears at bottom.
///
/// TECHNICAL:
/// ListView with onScroll callback for pagination trigger.
/// Passes selected index to parent; parent manages selection state.
/// Calls onScroll when user scrolls near end of list.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.results,
    required this.selectedIndex,
    required this.scrollController,
    required this.onResultTap,
    required this.onScroll,
  });

  final List<BookSearchResult> results;
  final int? selectedIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onResultTap;
  final VoidCallback onScroll;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: selectedIndex != null ? 96.0 : 28.0,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final book = results[index];
        final isSelected = selectedIndex == index;

        return SearchResultTile(
          book: book,
          isSelected: isSelected,
          onTap: () => onResultTap(index),
        );
      },
    );
  }
}
