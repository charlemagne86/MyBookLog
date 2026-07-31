import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// Floating button to add selected book to shelf.
/// Only visible when a book is selected.
/// Shows loading indicator while saving; disabled during add operation.
///
/// TECHNICAL:
/// Positioned widget at bottom of screen.
/// Calls onPressed callback when user taps.
/// Displays different content based on isLoading state.
class AddToShelfButton extends StatelessWidget {
  const AddToShelfButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: Text(
            isLoading ? 'Adding...' : 'Add to Bookshelf',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
