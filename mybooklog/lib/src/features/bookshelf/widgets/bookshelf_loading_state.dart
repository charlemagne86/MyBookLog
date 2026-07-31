import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Show loading indicator while fetching bookshelf from database.
/// Provides visual feedback that data is being loaded.
///
/// TECHNICAL:
/// Simple stateless widget with centered spinner.
/// Minimal, pure presentation component.
class BookshelfLoadingState extends StatelessWidget {
  const BookshelfLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
