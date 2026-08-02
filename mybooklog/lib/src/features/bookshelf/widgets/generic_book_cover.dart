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
/// to the same rounded-corner radius the real cover art uses so it sits
/// in a shelf cell without looking out of place.
class GenericBookCover extends StatelessWidget {
  const GenericBookCover({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  static const String assetPath = 'assets/images/generic_book_cover.png';

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}
