import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/shelf_book.dart';
import 'generic_book_cover.dart';
import 'star_rating.dart';

/// BUSINESS LOGIC:
/// The one place to see everything about a book on the shelf and act on it:
/// a summary and the details Google Books supplied when it was added, plus
/// controls to mark it read/unread, rate it, and remove it (with a
/// confirmation, since removal can't be undone). Opened by tapping a book on
/// the shelf, replacing the old long-press menu.
///
/// TECHNICAL:
/// Shown via `showModalBottomSheet`. Every detail field below the header is
/// optional — Google supplies them inconsistently — so each is only rendered
/// when present. Read/unread and rating changes are shown immediately
/// (before the save finishes) so the panel feels responsive; if the save
/// then fails, the change is rolled back locally. The parent screen owns the
/// actual repository calls and any error messaging (it already has a
/// Scaffold/ScaffoldMessenger to show failures in), so this widget stays
/// focused on presentation and doesn't talk to the network directly.
class BookDetailsPanel extends StatefulWidget {
  const BookDetailsPanel({
    super.key,
    required this.book,
    required this.onToggleRead,
    required this.onRate,
    required this.onRemove,
  });

  final ShelfBook book;
  final Future<void> Function() onToggleRead;
  final Future<void> Function(int rating) onRate;
  final Future<void> Function() onRemove;

  /// Roughly where a description stops being a quick blurb and starts being
  /// worth collapsing behind "Read more" — chosen empirically, not measured
  /// against actual text layout (that would need a LayoutBuilder/TextPainter
  /// pass this widget doesn't otherwise need).
  static const int descriptionCollapseThreshold = 220;

  @override
  State<BookDetailsPanel> createState() => _BookDetailsPanelState();
}

class _BookDetailsPanelState extends State<BookDetailsPanel> {
  late bool _isRead;
  late int? _rating;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _isRead = widget.book.isRead;
    _rating = widget.book.rating;
  }

  Future<void> _handleToggleRead() async {
    final previous = _isRead;
    setState(() => _isRead = !_isRead);
    try {
      await widget.onToggleRead();
    } catch (_) {
      // The parent already surfaces the error (e.g. a SnackBar); this just
      // undoes the optimistic flip so the panel doesn't lie about the save.
      if (mounted) setState(() => _isRead = previous);
    }
  }

  Future<void> _handleRate(int rating) async {
    final previous = _rating;
    setState(() => _rating = rating);
    try {
      await widget.onRate(rating);
    } catch (_) {
      if (mounted) setState(() => _rating = previous);
    }
  }

  Future<void> _handleRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove "${widget.book.title}"?'),
        content: const Text(
          'This removes the book from your bookshelf. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onRemove();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    height: 108,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: book.thumbnailUri.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: book.thumbnailUri,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  const GenericBookCover(),
                            )
                          : const GenericBookCover(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: theme.textTheme.headlineSmall),
                        if ((book.author ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            book.author!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleToggleRead,
                icon: Icon(
                  _isRead ? Icons.check_circle : Icons.check_circle_outline,
                ),
                label: Text(_isRead ? 'Mark as Unread' : 'Mark as Read'),
              ),
              const SizedBox(height: 16),
              Text('Your rating', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              StarRating(rating: _rating, onRate: _handleRate),
              if (book.googleAverageRating != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.star, size: 18, color: colorScheme.outline),
                    const SizedBox(width: 6),
                    Text(
                      'Google rating: '
                      '${book.googleAverageRating!.toStringAsFixed(1)}'
                      '${book.googleRatingsCount != null ? ' · ${book.googleRatingsCount} ratings' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              if ((book.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                _Description(
                  text: book.description!,
                  expanded: _descriptionExpanded,
                  onToggle: () => setState(
                    () => _descriptionExpanded = !_descriptionExpanded,
                  ),
                ),
              ],
              if (_metadataLine(book) != null) ...[
                const SizedBox(height: 16),
                Text(
                  _metadataLine(book)!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (book.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.categories
                      .map(
                        (category) => Chip(
                          label: Text(category),
                          // The app's shared chipTheme.labelStyle carries no
                          // color of its own (nothing used a Chip before this
                          // feature, so the gap was invisible) — set one
                          // explicitly so labels are never white-on-white.
                          labelStyle: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleRemove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  foregroundColor: AppColors.white,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove from Shelf'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "312 pages · 2016 · Penguin" — only the pieces the book actually has,
  /// joined together; null when none of them are present.
  static String? _metadataLine(ShelfBook book) {
    final parts = <String>[
      if (book.pageCount != null) '${book.pageCount} pages',
      if ((book.publishedDate ?? '').isNotEmpty)
        book.publishedDate!.length >= 4
            ? book.publishedDate!.substring(0, 4)
            : book.publishedDate!,
      if ((book.publisher ?? '').isNotEmpty) book.publisher!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// A description that collapses behind "Read more" once it's long enough to
/// be worth collapsing, so the panel doesn't open dominated by marketing
/// copy for a book with a long synopsis.
class _Description extends StatelessWidget {
  const _Description({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  /// Google descriptions occasionally carry simple HTML (e.g. `<p>` tags or
  /// `&amp;`-style entities); this is a light, dependency-free cleanup, not
  /// a full HTML parser.
  static String _clean(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final cleaned = _clean(text);
    final isLong =
        cleaned.length > BookDetailsPanel.descriptionCollapseThreshold;
    final style = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cleaned,
          style: style,
          maxLines: !isLong || expanded ? null : 4,
          overflow: !isLong || expanded ? null : TextOverflow.ellipsis,
        ),
        if (isLong)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onToggle,
              child: Text(expanded ? 'Show less' : 'Read more'),
            ),
          ),
      ],
    );
  }
}
