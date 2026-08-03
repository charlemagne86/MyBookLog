import 'package:flutter/material.dart';

/// Which books to show based on their read/unread status.
enum ReadFilter { all, unread, read }

/// BUSINESS LOGIC:
/// The single, compact row above the shelf grid for narrowing it: one
/// fixed-width chip on the left picks the read/unread status (tap it to
/// choose All/Unread/Read), then — after a vertical divider — one chip per
/// category present anywhere on the user's shelf, multi-select. Kept to one
/// chip-row's height since it's permanently visible above the grid.
///
/// TECHNICAL:
/// Purely presentational — [selectedFilter]/[selectedCategories] are owned
/// by the parent screen, which also computes [availableCategories] (every
/// category across the whole shelf, not just the currently visible books)
/// since that depends on the book list, not this widget. The category list
/// lives in an [Expanded] + horizontally-scrolling [ListView] so overflow
/// scrolls within its own space without resizing the read-filter chip or
/// the divider next to it.
class BookshelfFilterRow extends StatelessWidget {
  const BookshelfFilterRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onCategoryToggled,
    this.availableCategories = const <String>[],
    this.selectedCategories = const <String>{},
  });

  final ReadFilter selectedFilter;
  final ValueChanged<ReadFilter> onFilterChanged;

  final List<String> availableCategories;
  final Set<String> selectedCategories;

  /// Called with the category the user tapped; the parent toggles its
  /// membership in [selectedCategories].
  final ValueChanged<String> onCategoryToggled;

  static const double chipRowHeight = 40;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: chipRowHeight,
      child: Row(
        children: [
          _ReadFilterChip(selected: selectedFilter, onChanged: onFilterChanged),
          if (availableCategories.isNotEmpty) ...[
            const SizedBox(width: 12),
            SizedBox(
              height: chipRowHeight,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = availableCategories[index];
                  final selected = selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    // The app's shared chipTheme.labelStyle carries no color
                    // of its own — set one explicitly so labels are never
                    // white-on-white/green-on-green.
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
}

/// The read/unread status picker: a single chip whose label reflects the
/// current selection, at a constant width regardless of which of
/// All/Unread/Read is showing so it never shifts the divider or category
/// chips next to it when tapped.
class _ReadFilterChip extends StatelessWidget {
  const _ReadFilterChip({required this.selected, required this.onChanged});

  final ReadFilter selected;
  final ValueChanged<ReadFilter> onChanged;

  static String _label(ReadFilter filter) => switch (filter) {
    ReadFilter.all => 'All',
    ReadFilter.unread => 'Unread',
    ReadFilter.read => 'Read',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );

    return PopupMenuButton<ReadFilter>(
      tooltip: 'Filter by read status',
      onSelected: onChanged,
      itemBuilder: (context) => ReadFilter.values
          .map(
            (filter) => PopupMenuItem<ReadFilter>(
              value: filter,
              child: Text(_label(filter)),
            ),
          )
          .toList(),
      child: Container(
        height: BookshelfFilterRow.chipRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            BookshelfFilterRow.chipRowHeight / 2,
          ),
        ),
        // IntrinsicWidth measures its child's actual natural width and
        // reports that as its own size — since the Stack below always
        // contains an invisible "Unread" (the longest label), the chip is
        // exactly as wide as that longest label needs, no wider, and never
        // narrower, without a hardcoded pixel guess that could either waste
        // space or (if too tight) overflow.
        child: IntrinsicWidth(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 0, child: Text('Unread', style: labelStyle)),
                  Text(
                    _label(selected),
                    key: const ValueKey('read_filter_chip_label'),
                    style: labelStyle,
                  ),
                ],
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
