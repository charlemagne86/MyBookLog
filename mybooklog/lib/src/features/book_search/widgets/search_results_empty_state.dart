import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// When a search returns no results, show helpful message to user.
/// This encourages them to refine their search rather than give up.
///
/// TECHNICAL:
/// Simple widget displaying centered message with primary color.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'No results found. Try a different search.',
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
