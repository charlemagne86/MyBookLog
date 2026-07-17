import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/book_search_result.dart';
import '../../data/repositories/bookshelf_repository.dart';
import '../../data/services/google_books_service.dart';

/// The bundle of information the Add Book screen hands to the results screen:
/// the first page of found books, the search phrase (needed to fetch further
/// pages), and how many matches exist in total.
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

/// The search results screen: a scrolling list of found books, each showing
/// its cover, title, and author.
///
/// The user taps a book to select it (tap again to un-select), then taps the
/// big "Add to Bookshelf" button that appears at the bottom. Scrolling near
/// the end of the list quietly fetches the next page of results, so the list
/// feels endless.
class SearchResultsPage extends StatefulWidget {
  const SearchResultsPage({super.key, required this.args});
  final SearchResultsArgs args;

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  // Which list entry is currently selected (highlighted), if any.
  int? _selectedIndex;
  // True while the chosen book is being saved to the shelf.
  bool _isAdding = false;
  // True while the next page of results is being fetched.
  bool _isLoadingMore = false;
  // False once we know we've seen everything the search can offer.
  bool _hasMoreResults = true;
  // Every result gathered so far (first page plus any extra pages).
  late List<BookSearchResult> _results;
  // Watches the list's scroll position to know when to fetch more.
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

  /// A first guess at whether more results exist beyond the first page:
  /// trust Google's reported total when we have it; otherwise assume "yes"
  /// whenever the first page came back full.
  bool get _hasExpectedMoreResults {
    final total = widget.args.totalItems;
    if (total != null) return _results.length < total;
    return _results.length >= GoogleBooksService.pageSize;
  }

  /// Runs on every scroll movement. When the user is within about one
  /// screen-height of the bottom, start fetching the next page — unless a
  /// fetch is already running or there is nothing more to fetch.
  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMoreResults) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 500) {
      _loadMoreResults();
    }
  }

  /// Fetches the next page of results and stitches it onto the list.
  Future<void> _loadMoreResults() async {
    setState(() => _isLoadingMore = true);
    try {
      final page = await _service.search(
        widget.args.searchQuery,
        startIndex: _results.length,
      );
      if (!mounted) return;
      setState(() {
        // Google sometimes repeats books across pages; compare fingerprints
        // and keep only the ones we haven't already got.
        final existingKeys = _results.map((r) => r.identityKey()).toSet();
        for (final result in page.results) {
          if (existingKeys.add(result.identityKey())) _results.add(result);
        }
        // Decide whether it is worth fetching again later: stop once we've
        // reached the reported total, or once a page comes back empty/short.
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

  /// Quietly improves the user's pick when it lacks an ISBN (the product
  /// number the app uses to tell books apart — see BookSearchResult).
  ///
  /// The same book often appears in the results several times as different
  /// editions. If the tapped edition has no ISBN, this looks through the
  /// other editions of the same title/author for one that does (preferring
  /// the modern 13-digit kind) and uses that instead. If none is found, the
  /// original pick is kept and a later fallback lookup will try the internet.
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

  /// Runs when "Add to Bookshelf" is tapped: saves the selected book.
  ///
  /// Step by step: pick the best edition of the selection; if it still has
  /// no ISBN, ask the internet for one; refuse to save a book missing its
  /// title, author, or ISBN (a record that incomplete could not be reliably
  /// recognized later); then save it. If it turns out the book was already
  /// on the shelf, tell the user so and stay on this screen; otherwise
  /// confirm and return to the shelf.
  Future<void> _addSelectedBook() async {
    if (_selectedIndex == null) return;
    final selected = _results[_selectedIndex!];
    final book = _resolveBestRecord(selected);
    // Capture the repository before any await to avoid using context across gaps.
    final bookshelfRepo = context.read<BookshelfRepository>();

    setState(() => _isAdding = true);
    try {
      // Last-resort ISBN lookup: fetch the book's full record by its
      // Google ID, which usually includes the ISBN the search result lacked.
      var isbn = book.isbn;
      final volumeId = book.volumeId ?? selected.volumeId;
      if ((isbn == null || isbn.isEmpty) &&
          volumeId != null &&
          volumeId.isNotEmpty) {
        isbn = await _service.fetchPreferredIsbnForVolume(volumeId);
      }

      // A book we can't identify later is worse than no book: refuse to
      // save anything missing these three essentials.
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Search Results')),
      body: Stack(
        children: [
          SafeArea(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      'No results found. Try a different search.',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: _selectedIndex != null ? 96.0 : 28.0,
                    ),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 18),
                    itemBuilder: (context, index) =>
                        _buildResultTile(index, colorScheme),
                  ),
          ),
          if (_isLoadingMore)
            const Positioned(
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
            ),
          if (_selectedIndex != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addSelectedBook,
                  icon: _isAdding
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    _isAdding ? 'Adding...' : 'Add to Bookshelf',
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
    );
  }

  /// Draws one book in the results list: cover on the left, title and author
  /// on the right. When selected, the card turns green-tinted, gains a border,
  /// and shows a checkmark on its right edge.
  Widget _buildResultTile(int index, ColorScheme colorScheme) {
    final item = _results[index];
    final isSelected = _selectedIndex == index;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      // Tapping selects this book; tapping it again deselects it.
      onTap: () => setState(() => _selectedIndex = isSelected ? null : index),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 180,
                child: item.thumbnail.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.thumbnail,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 90,
                          color: colorScheme.primary,
                        ),
                      ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.authorsLabel,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
