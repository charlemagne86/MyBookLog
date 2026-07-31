import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Show helpful message when shelf is empty or search has no results.
/// Different messages for different scenarios.
/// Encourages user action (add book or refine search).
///
/// TECHNICAL:
/// Simple stateless widget that displays centered text.
/// Takes message parameter to support multiple scenarios.
/// Uses theme primary color for visibility.
class BookshelfEmptyState extends StatelessWidget {
  const BookshelfEmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.primary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
