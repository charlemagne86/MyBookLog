import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Display error messages when search fails or validation fails.
/// Errors should be prominent but not intrusive.
/// Use error color to draw attention.
///
/// TECHNICAL:
/// Conditionally renders based on error message presence.
/// Only shown when error != null.
/// Uses error color from theme.
class SearchErrorMessage extends StatelessWidget {
  const SearchErrorMessage({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        message!,
        style: TextStyle(
          color: colorScheme.error,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
