import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../data/services/google_books_service.dart';
import 'search_results_page.dart';
import 'widgets/book_search_form.dart';
import 'widgets/search_button.dart';
import 'widgets/search_error_message.dart';

/// BUSINESS LOGIC:
/// Add book screen lets users search Google Books by title and/or author.
/// User fills in fields, taps Search, and navigates to results screen.
/// Validates that search is available and query is not empty.
///
/// TECHNICAL:
/// Refactored into testable components:
/// - BookSearchForm: text input fields
/// - SearchButton: search action button
/// - SearchErrorMessage: error display
/// - AddBookPage: orchestrates components and handles search logic
class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  bool _isSearching = false;
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  /// BUSINESS LOGIC: Validate and execute book search
  /// TECHNICAL: Check API key, validate query, call Google Books API
  Future<void> _searchBooks() async {
    // BUSINESS LOGIC: Search unavailable without API key
    // TECHNICAL: AppConfig.hasGoogleBooksApiKey indicates availability
    if (!AppConfig.hasGoogleBooksApiKey) {
      setState(() {
        _errorText =
            'Book search is unavailable: no Google Books API key was configured '
            'for this build.';
      });
      return;
    }

    // BUSINESS LOGIC: Both fields optional, but at least one required
    // TECHNICAL: buildQuery returns empty string if both fields empty
    final query = GoogleBooksService.buildQuery(
      title: _titleController.text,
      author: _authorController.text,
    );
    if (query.isEmpty) {
      setState(() {
        _errorText = 'Enter a title, an author, or both before searching.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _isSearching = true;
    });
    try {
      // BUSINESS LOGIC: Search Google Books API and navigate to results
      // TECHNICAL: Get first page of results; user can load more on results screen
      final page = await context.read<GoogleBooksService>().search(query);
      if (!mounted) return;
      unawaited(
        context.push(
          '/shelf/results',
          extra: SearchResultsArgs(
            results: page.results,
            searchQuery: query,
            totalItems: page.totalItems,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _errorText = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input form (title and author fields)
              BookSearchForm(
                titleController: _titleController,
                authorController: _authorController,
              ),
              const SizedBox(height: 32),

              // Error message (if any)
              SearchErrorMessage(message: _errorText),

              // Search button
              SearchButton(
                isLoading: _isSearching,
                onPressed: _searchBooks,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
