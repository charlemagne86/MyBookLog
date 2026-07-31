import 'package:flutter/material.dart';

/// BUSINESS LOGIC:
/// User taps to initiate book search.
/// Button shows "Search Books" normally.
/// Button shows "Searching..." and spinner during search.
/// Button is disabled while search is in progress.
///
/// TECHNICAL:
/// Stateless widget with callback.
/// Takes isLoading flag to show/hide loading state.
/// Icon changes based on loading state.
class SearchButton extends StatelessWidget {
  const SearchButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search_rounded),
          label: Text(
            isLoading ? 'Searching...' : 'Search Books',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
