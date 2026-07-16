import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../data/services/google_books_service.dart';
import 'search_results_page.dart';

/// Lets the user search Google Books by title and/or author.
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

  Future<void> _searchBooks() async {
    if (!AppConfig.hasGoogleBooksApiKey) {
      setState(() {
        _errorText =
            'Book search is unavailable: no Google Books API key was configured '
            'for this build.';
      });
      return;
    }
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Book')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Search for a book...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 32),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchBooks,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      _isSearching ? 'Searching...' : 'Search Books',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
