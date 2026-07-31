import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/book_search_result.dart';

/// BUSINESS LOGIC:
/// Display one search result as a selectable card with book cover, title, author.
/// Selected books get visual highlight (green tint, border, checkmark).
/// User taps to select/deselect books before adding to shelf.
///
/// TECHNICAL:
/// Takes book data and selected state; calls onTap callback when tapped.
/// Displays cover image (or fallback icon), title, and author.
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.book,
    required this.isSelected,
    required this.onTap,
  });

  final BookSearchResult book;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Book cover image or fallback icon
              SizedBox(
                width: 120,
                height: 180,
                child: book.thumbnail.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: book.thumbnail,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 90,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              // Title and author text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.authorsLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Selection checkmark
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
