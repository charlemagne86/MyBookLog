import 'package:flutter/material.dart';

/// Which books to show based on their read/unread status.
enum ReadFilter { all, unread, read }

/// BUSINESS LOGIC:
/// Users can narrow their bookshelf by title/author text, by read/unread
/// status, and by category (Fiction, Juvenile Fiction, etc. — whatever
/// Google Books tagged the books with). This bar is always visible above
/// the grid, so every filter is one tap away rather than hidden behind a
/// toggle.
///
/// TECHNICAL:
/// Purely presentational — [controller]/[selectedFilter]/[selectedCategories]
/// are owned by the parent screen, which also computes [availableCategories]
/// (the distinct categories present across the user's current shelf) since
/// that depends on the book list, not this widget. Text search still
/// requires 3+ characters to avoid flickering while typing; the read/unread
/// and category filters apply immediately since chip taps are discrete
/// choices, not free-form typing.
class BookshelfSearchBar extends StatelessWidget {
  const BookshelfSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.visibleBooksCount,
    required this.totalBooksCount,
    required this.onChanged,
    required this.onClear,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onCategoryToggled,
    this.availableCategories = const <String>[],
    this.selectedCategories = const <String>{},
  });

  final TextEditingController controller;
  final String searchQuery;
  final int visibleBooksCount;
  final int totalBooksCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  final ReadFilter selectedFilter;
  final ValueChanged<ReadFilter> onFilterChanged;

  /// Distinct categories across the user's shelf, in the order to display
  /// them. Empty when no book on the shelf has a category at all.
  final List<String> availableCategories;
  final Set<String> selectedCategories;

  /// Called with the category the user tapped; the parent toggles its
  /// membership in [selectedCategories].
  final ValueChanged<String> onCategoryToggled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final queryLength = searchQuery.trim().length;
    final hasText = searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: TextField(
                controller: controller,
                // A permanently-visible field must not pop the keyboard on
                // every screen load — autofocus only made sense when this
                // bar appeared solely in response to an explicit tap.
                autofocus: false,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ReadFilter.values.map((filter) {
              final selected = selectedFilter == filter;
              return ChoiceChip(
                label: Text(_readFilterLabel(filter)),
                // The app's shared chipTheme.labelStyle carries no color of
                // its own (nothing used a Chip before this feature, so the
                // gap was invisible) — set one explicitly per state so
                // labels are never white-on-white/green-on-green.
                labelStyle: TextStyle(
                  color: selected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                selected: selected,
                onSelected: (_) => onFilterChanged(filter),
              );
            }).toList(),
          ),
          if (availableCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = availableCategories[index];
                  final selected = selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    selected: selected,
                    onSelected: (_) => onCategoryToggled(category),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _readFilterLabel(ReadFilter filter) => switch (filter) {
    ReadFilter.all => 'All',
    ReadFilter.unread => 'Unread',
    ReadFilter.read => 'Read',
  };
}
