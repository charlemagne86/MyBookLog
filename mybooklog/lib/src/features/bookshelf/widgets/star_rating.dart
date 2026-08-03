import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Lets a user say "this book was worth it" at a glance, and lets them set
/// that rating with a single tap on a star. Also reused, in read-only mode,
/// to show Google's own aggregate rating for a book — so the same visual
/// language means "a rating" everywhere in the app, whether it's the user's
/// own or Google's.
///
/// TECHNICAL:
/// A row of [starCount] star icons (filled up to [rating], outlined beyond
/// it). When [onRate] is null the row is display-only (used for Google's
/// rating, which nobody can edit by tapping); when it's provided, tapping
/// star N reports a rating of N (1-indexed, so the first star reports 1).
/// Each star uses [InkResponse] rather than [IconButton]: the app's themed
/// icon-button minimum touch target (48x48) would force five stars wider
/// than the space available next to a book cover.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.size = 24,
    this.spacing = 2,
    this.onRate,
    this.filledColor,
    this.outlineColor,
  });

  /// Stars filled from the left, 0 (or null) through [starCount]. Null and 0
  /// both render as "no stars filled" — null additionally means "the user
  /// has never rated this book" to callers that care about the distinction.
  final int? rating;
  final int starCount;
  final double size;
  final double spacing;

  /// Called with the 1-indexed star tapped. Null makes this read-only.
  final ValueChanged<int>? onRate;
  final Color? filledColor;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filled = filledColor ?? colorScheme.primary;
    final outline = outlineColor ?? colorScheme.outline;
    final currentRating = rating ?? 0;

    return Semantics(
      label: 'Rating: $currentRating out of $starCount stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(starCount, (index) {
          final starNumber = index + 1;
          final icon = Icon(
            starNumber <= currentRating ? Icons.star : Icons.star_border,
            size: size,
            color: starNumber <= currentRating ? filled : outline,
          );
          if (onRate == null) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing / 2),
              child: icon,
            );
          }
          return Semantics(
            button: true,
            label: 'Rate $starNumber out of $starCount stars',
            child: InkResponse(
              onTap: () => onRate!(starNumber),
              radius: size,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: icon,
              ),
            ),
          );
        }),
      ),
    );
  }
}
