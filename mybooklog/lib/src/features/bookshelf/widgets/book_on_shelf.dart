import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Draws one book in the shelf grid: the cover picture with a soft shadow
/// (so it appears to sit on a shelf), the title underneath, a green
/// checkmark badge when the book has been read, and a subtle "lift" animation
/// while the user is holding their finger on it.
///
/// If the cover picture is missing or fails to download, a generic open-book
/// icon is shown in its place. Downloaded covers are cached on the device so
/// they appear instantly (and offline) on later visits.
class BookOnShelf extends StatelessWidget {
  const BookOnShelf({
    super.key,
    required this.imageUrl,
    required this.title,
    this.isRead = false,
    this.isContextMenuTarget = false,
  });

  final String? imageUrl;
  final String title;
  final bool isRead;
  final bool isContextMenuTarget;

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
              // The three "Animated..." layers below create the lift effect
              // during a press-and-hold: the cover slides up a touch, grows
              // slightly, and gains a green outline and glow.
              AnimatedSlide(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                offset: isContextMenuTarget
                    ? const Offset(0.012, -0.04)
                    : Offset.zero,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  scale: isContextMenuTarget ? 1.04 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: isContextMenuTarget
                          ? Border.all(
                              color: colorScheme.primary.withAlpha(
                                (0.92 * 255).round(),
                              ),
                              width: 2.6,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.34 * 255).round()),
                          blurRadius: 16,
                          spreadRadius: 0.4,
                          offset: const Offset(0, 7),
                        ),
                        BoxShadow(
                          color: isContextMenuTarget
                              ? colorScheme.primary.withAlpha(
                                  (0.44 * 255).round(),
                                )
                              : Colors.transparent,
                          blurRadius: isContextMenuTarget ? 24 : 8,
                          spreadRadius: isContextMenuTarget ? 1.9 : 0,
                          offset: isContextMenuTarget
                              ? const Offset(2, 12)
                              : const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Center(
                                child: Icon(
                                  Icons.menu_book,
                                  size: 48,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
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
