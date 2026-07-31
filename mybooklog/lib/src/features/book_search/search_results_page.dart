import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/book_search_result.dart';
import '../../data/repositories/bookshelf_repository.dart';
import '../../data/services/google_books_service.dart';
import 'widgets/add_to_shelf_button.dart';
import 'widgets/search_loading_indicator.dart';
import 'widgets/search_results_empty_state.dart';
import 'widgets/search_results_list.dart';

/// BUSINESS LOGIC:
/// Bundle of information passed from Add Book screen to Results screen:
/// first page of results, search phrase (for pagination), total match count.
class SearchResultsArgs {
  const SearchResultsArgs({
    required this.results,
    required this.searchQuery,
    required this.totalItems,
  });
  final List<BookSearchResult> results;
  final String searchQuery;
  final int? totalItems;
}

/// BUSINESS LOGIC:
/// Search results screen shows scrollable list of found books.
/// User taps to select, then "Add to Bookshelf" button to save.
/// Pagination: automatically loads more results as user scrolls near end.
///
/// TECHNICAL:
/// Refactored into smaller components for testability:
/// - SearchResultsList: paginated list display
/// - SearchResultTile: individual book card
/// - AddToShelfButton: floating add button
/// - SearchLoadingIndicator: pagination loading state
/// - SearchEmptyState: no results message
class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key, required this.args});
  final SearchResultsArgs args;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  int? _selectedIndex;
  bool _isAdding = false;
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  late List<BookSearchResult> _results;
  final _scrollController = ScrollController();

  GoogleBooksService get _service => context.read<GoogleBooksService>();

  @override
  void initState() {
    super.initState();
    _results = List<BookSearchResult>.from(widget.args.results);
    _hasMoreResults = _hasExpectedMoreResults;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// BUSINESS LOGIC: Determine if more pages likely exist
  /// TECHNICAL: Use Google's total if available; otherwise check if page full
  bool get _hasExpectedMoreResults {
    final total = widget.args.totalItems;
    if (total != null) return _results.length < total;
    return _results.length >= GoogleBooksService.pageSize;
  }

  /// BUSINESS LOGIC: Detect when user scrolls to bottom
  /// TECHNICAL: Trigger load when within 500px of end
  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreResults) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadMoreResults();
    }
  }

  /// BUSINESS LOGIC: Fetch next page of results
  /// TECHNICAL: Deduplicate across pages; update pagination state
  Future<void> _loadMoreResults() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.search(
        widget.args.searchQuery,
        startIndex: _results.length,
      );
      if (!mounted) return;
      setState(() {
        final existingKeys = _results.map((r) => r.identityKey()).toSet();
        for (final result in page.results) {
          if (existingKeys.add(result.identityKey())) _results.add(result);
        }
        final reachedKnownEnd =
            page.totalItems != null && _results.length >= page.totalItems!;
        _hasMoreResults =
            !(reachedKnownEnd ||
                page.results.isEmpty ||
                page.results.length < GoogleBooksService.pageSize);
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load more results: $e')),
      );
    }
  }

  /// BUSINESS LOGIC: Find best ISBN for selected book
  /// TECHNICAL: Search other editions for ISBN if selected lacks one
  BookSearchResult _resolveBestRecord(BookSearchResult selected) {
    if (selected.hasIsbn) return selected;
    final targetKey = selected.volumeKey();
    BookSearchResult? best;
    for (final candidate in _results) {
      if (candidate.volumeKey() != targetKey || !candidate.hasIsbn) continue;
      if (best == null) {
        best = candidate;
        if (BookSearchResult.isLikelyIsbn13(candidate.isbn!)) break;
        continue;
      }
      if (!BookSearchResult.isLikelyIsbn13(best.isbn!) &&
          BookSearchResult.isLikelyIsbn13(candidate.isbn!)) {
        best = candidate;
        break;
      }
    }
    return best ?? selected;
  }

  /// BUSINESS LOGIC: Save selected book to shelf
  /// TECHNICAL: Resolve ISBN; validate title/author/ISBN present; call repository
  Future<void> _addSelectedBook() async {
    if (_selectedIndex == null) return;
    final selected = _results[_selectedIndex!];
    final book = _resolveBestRecord(selected);
    final bookshelfRepo = context.read<BookshelfRepository>();

    setState(() => _isAdding = true);
    try {
      var isbn = book.isbn;
      final volumeId = book.volumeId ?? selected.volumeId;
      if ((isbn == null || isbn.isEmpty) &&
          volumeId != null &&
          volumeId.isNotEmpty) {
        isbn = await _service.fetchPreferredIsbnForVolume(volumeId);
      }

      if (book.title.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing Title');
      }
      if (book.authors.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing Author');
      }
      if (isbn == null || isbn.isEmpty) {
        throw Exception('Failed to add to bookshelf due to missing ISBN');
      }

      final alreadyOnShelf = await bookshelfRepo.addBook(
        isbn: isbn,
        title: book.title,
        author: book.authors.join(', '),
        thumbnail: book.thumbnail.isEmpty ? null : book.thumbnail,
      );
      if (!mounted) return;

      if (alreadyOnShelf) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This book already exists on your bookshelf.'),
          ),
        );
        setState(() => _isAdding = false);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book added to your bookshelf!')),
      );
      context.go('/shelf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add book: $e')));
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: Stack(
        children: [
          SafeArea(
            child: _results.isEmpty
                ? const SearchEmptyState()
                : SearchResultsList(
                    results: _results,
                    selectedIndex: _selectedIndex,
                    scrollController: _scrollController,
                    onResultTap: (index) {
                      setState(
                        () => _selectedIndex = _selectedIndex == index
                            ? null
                            : index,
                      );
                    },
                    onScroll: _onScroll,
                  ),
          ),
          if (_isLoadingMore) const SearchLoadingIndicator(),
          if (_selectedIndex != null)
            AddToShelfButton(isLoading: _isAdding, onPressed: _addSelectedBook),
        ],
      ),
    );
  }
}
