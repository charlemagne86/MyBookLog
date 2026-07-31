import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Show loading spinner at bottom of results list when fetching more pages.
/// Indicates to user that more results are being loaded.
///
/// TECHNICAL:
/// Positioned widget overlaid at bottom of list.
/// Only shown when isLoading=true.
class SearchLoadingIndicator extends StatelessWidget {
  const SearchLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
