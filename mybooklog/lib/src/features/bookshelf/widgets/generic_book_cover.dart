import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// BUSINESS LOGIC:
/// The stand-in cover shown when a book has no working cover image: a
/// plain cover in the app's own accent green, so a missing photo still
/// reads as "a book" on the shelf rather than as a broken image icon.
///
/// Used both when no valid thumbnail was found for a book at add-time
/// (see GoogleBooksService.isThumbnailValid) and when a previously-saved
/// thumbnail URL later fails to load.
///
/// TECHNICAL:
/// A plain [AppColors.accentSage] fill with a centered book icon, clipped
/// to the same rounded-corner radius the real cover art uses so it sits
/// in a shelf cell without looking out of place.
class GenericBookCover extends StatelessWidget {
  const GenericBookCover({
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        color: AppColors.accentSage,
        child: const Center(
          child: Icon(Icons.menu_book, size: 48, color: AppColors.white),
        ),
      ),
    );
  }
}
