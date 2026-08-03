import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'generic_book_cover.dart';

/// Draws one book in the shelf grid: the cover picture with a soft shadow
/// (so it appears to sit on a shelf), the title underneath, and a green
/// checkmark badge when the book has been read. Tapping the cover opens the
/// book's details panel — the ink splash from that tap is standard Material
/// feedback provided by the ancestor `InkWell` in [BookshelfGrid], not drawn
/// here.
///
/// If the cover picture is missing or fails to download, a plain green
/// [GenericBookCover] is shown in its place. Downloaded covers are cached on
/// the device so they appear instantly (and offline) on later visits.
class BookOnShelf extends StatelessWidget {
  const BookOnShelf({
    super.key,
    required this.imageUrl,
    required this.title,
    this.isRead = false,
  });

  final String? imageUrl;
  final String title;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The cover keeps a real book's proportions (2 wide : 3 tall).
        AspectRatio(
          aspectRatio: 0.67,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha((0.34 * 255).round()),
                      blurRadius: 16,
                      spreadRadius: 0.4,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) =>
                              const GenericBookCover(),
                        ),
                      )
                    : const GenericBookCover(),
              ),
              // The small round checkmark badge in the top-left corner,
              // shown only on books marked as read.
              if (isRead)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.onPrimary,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // The title below the cover: at most two lines, with "…" when longer.
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
