import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A single book cover on the shelf grid, with an optional "read" badge and a
/// long-press lift animation.
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
        AspectRatio(
          aspectRatio: 0.67,
          child: Stack(
            children: [
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
