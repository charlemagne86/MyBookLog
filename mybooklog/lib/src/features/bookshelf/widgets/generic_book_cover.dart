import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// The stand-in cover shown when a book has no working cover image: a
/// plain green leather-look book cover graphic, so a missing photo still
/// reads as "a book" on the shelf rather than as a broken image icon.
///
/// Used both when no valid thumbnail was found for a book at add-time
/// (see GoogleBooksService.isThumbnailValid) and when a previously-saved
/// thumbnail URL later fails to load.
///
/// TECHNICAL:
/// A bundled asset image (assets/images/generic_book_cover.png), clipped
/// to the same rounded-corner radius the real cover art uses. Unlike real
/// cover thumbnails — which use [BoxFit.contain] to preserve their own,
/// externally-sourced proportions even if that means letterboxing — this
/// placeholder has no "true" aspect ratio to preserve, so it uses
/// [BoxFit.cover] instead: it always scales to completely fill whatever
/// box BookOnShelf's `AspectRatio` gives it, with the same width and
/// height a real cover occupies in that same cell. Because Flutter
/// recomputes that fit against the actual box size on every layout pass,
/// this holds automatically for any grid layout (2, 3, 4+ books per row)
/// without this widget needing to know the current column count or
/// aspect ratio.
///
/// The [SizedBox.expand] is load-bearing, not decorative: BookOnShelf's
/// Stack loosens the constraints it hands down to this widget (Stack
/// always loosens constraints for its non-positioned child), and
/// Image/ClipRRect don't grow to fill loose constraints on their own —
/// left alone, the image renders at whatever size its own pixels + fit
/// computation imply, which can be shorter than the box. SizedBox.expand
/// forces this cover to claim the box's full biggest size before the
/// image and fit are applied, matching a real cover's effective
/// footprint exactly.
class GenericBookCover extends StatelessWidget {
  const GenericBookCover({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  static const String assetPath = 'assets/images/generic_book_cover.png';

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }
}
