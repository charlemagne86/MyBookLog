import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../data/models/shelf_book.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bookshelf_repository.dart';
import 'widgets/book_details_panel.dart';
import 'widgets/bookshelf_empty_state.dart';
import 'widgets/bookshelf_filter_row.dart';
import 'widgets/bookshelf_grid.dart';
import 'widgets/bookshelf_loading_state.dart';
import 'widgets/bookshelf_search_bar.dart';

/// The app's home screen: the user's bookshelf.
///
/// Books are shown as a grid of covers, three per row. From here the user can:
///   * tap + to search for and add a new book,
///   * tap the magnifying glass to search by title or author,
///   * use the read/unread + category chips (visible whenever search isn't
///     open) to narrow the shelf,
///   * tap a book to open its details panel — summary, rating, mark
///     read/unread, and remove all live there,
///   * tap the door icon to log out.
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> with RouteAware {
  // The full list of the user's books, as last loaded from the database.
  List<ShelfBook> _books = [];
  // True while the first load is in flight (shows the spinner).
  bool _loading = true;
  // Whether the search field is open, and what's typed into it. Closing it
  // clears the text so the shelf reverts to just the chip filters below.
  bool _showSearchBar = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  // Read/unread and category narrowing, applied together with the search
  // text below in _visibleBooks.
  ReadFilter _readFilter = ReadFilter.all;
  final Set<String> _selectedCategories = {};

  BookshelfRepository get _repo => context.read<BookshelfRepository>();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribes (or re-subscribes, if the route changed) to this screen's
    // own route so didPopNext fires once the add-book flow returns here.
    shelfRouteObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    shelfRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  /// BUSINESS LOGIC: Fires when a route that was covering this screen (the
  /// add-book flow) is removed and the shelf becomes visible again — however
  /// that happened, whether the covering screens were popped one at a time
  /// or the whole stack collapsed via a single `go('/shelf')`. This is what
  /// makes a newly added book show up immediately, with no manual reload.
  @override
  void didPopNext() => _fetchBooks();

  /// The books to actually show on screen: search text, read/unread status,
  /// and category selection all narrow the shelf together. If the search
  /// box has fewer than three characters typed, text search is skipped
  /// entirely (filtering on one or two letters would flicker uselessly
  /// while the user is still typing) but the other two filters still apply.
  List<ShelfBook> get _visibleBooks {
    final query = _searchQuery.trim();
    return _books.where((b) {
      if (query.length >= 3 && !b.matchesQuery(query)) return false;
      if (_readFilter == ReadFilter.unread && b.isRead) return false;
      if (_readFilter == ReadFilter.read && !b.isRead) return false;
      if (_selectedCategories.isNotEmpty &&
          !b.categories.any(_selectedCategories.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Distinct categories across the whole shelf (not just the currently
  /// visible books), sorted for a stable chip order. Empty when nothing on
  /// the shelf has a category.
  List<String> get _availableCategories {
    final categories = <String>{};
    for (final book in _books) {
      categories.addAll(book.categories);
    }
    final sorted = categories.toList()..sort();
    return sorted;
  }

  /// Loads (or reloads) the user's books from the database. Shows a spinner
  /// while waiting; on failure, shows an error banner and an empty shelf.
  Future<void> _fetchBooks() async {
    setState(() => _loading = true);
    try {
      final books = await _repo.fetchShelf();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _books = [];
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load bookshelf: $e')));
    }
  }

  /// Opens the tapped book's details panel: summary, rating, mark
  /// read/unread, and remove all live there. `book` is a snapshot taken at
  /// tap time — the panel tracks its own optimistic UI state for
  /// read/unread and rating rather than watching this screen's list live.
  void _onBookTap(ShelfBook book) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookDetailsPanel(
        book: book,
        onToggleRead: () => _toggleReadStatus(book),
        onRate: (rating) => _onSetRating(book, rating),
        onRemove: () => _removeBook(book),
      ),
    );
  }

  /// Deletes a book from the shelf: first in the database, and only if that
  /// succeeds, from the grid on screen. A brief confirmation (or error)
  /// message appears at the bottom either way. Rethrows on failure so the
  /// details panel knows to undo its own optimistic UI.
  Future<void> _removeBook(ShelfBook book) async {
    try {
      await _repo.removeBook(book.bookId);
      if (!mounted) return;
      setState(() {
        // Rebuild the on-screen list without the removed book.
        _books = _books
            .where((b) => b.bookId != book.bookId)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book removed from your bookshelf.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove book: $e')));
      rethrow;
    }
  }

  /// Flips a book between read and unread: saves the change to the database
  /// first, then updates the checkmark badge on screen to match. Rethrows
  /// on failure so the details panel knows to undo its own optimistic UI.
  Future<void> _toggleReadStatus(ShelfBook book) async {
    final newValue = !book.isRead;
    try {
      await _repo.setReadStatus(book.bookId, isRead: newValue);
      if (!mounted) return;
      setState(() {
        // Swap the one changed book for an updated copy; leave the rest as-is.
        _books = _books
            .map(
              (b) => b.bookId == book.bookId ? b.copyWith(isRead: newValue) : b,
            )
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? 'Book marked as read.' : 'Book marked as unread.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update read status: $e')),
      );
      rethrow;
    }
  }

  /// Saves the user's 1-5 star rating for a book. Rethrows on failure so
  /// the details panel knows to undo its own optimistic UI.
  Future<void> _onSetRating(ShelfBook book, int rating) async {
    try {
      await _repo.setRating(book.bookId, rating: rating);
      if (!mounted) return;
      setState(() {
        _books = _books
            .map(
              (b) => b.bookId == book.bookId ? b.copyWith(rating: rating) : b,
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save rating: $e')));
      rethrow;
    }
  }

  /// Opens the "Add Book" flow, and when the user comes back, reloads the
  /// shelf so any newly added book appears immediately.
  Future<void> _onAddBook() async {
    await context.push('/shelf/add');
    if (!mounted) return;
    await _fetchBooks();
  }

  /// Opens or closes the search field. Closing it also erases the typed
  /// text, so the shelf reverts to whatever the chip filters below select.
  void _onSearchBook() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  /// Adds or removes one category from the active category filter.
  void _onCategoryToggled(String category) {
    setState(() {
      if (!_selectedCategories.remove(category)) {
        _selectedCategories.add(category);
      }
    });
  }

  /// Signs the user out. The router notices and returns them to the login
  /// screen automatically.
  Future<void> _onLogout() async {
    try {
      await context.read<AuthRepository>().signOut();
      // Router redirect returns to /login on the sign-out event.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookshelf'),
        leading: IconButton(
          icon: const Icon(Icons.logout, size: 32),
          tooltip: 'Logout',
          onPressed: _onLogout,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 32),
            tooltip: 'Search Books',
            onPressed: _onSearchBook,
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 32),
            tooltip: 'Add Book',
            onPressed: _onAddBook,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Equal top and bottom gaps around the chip row: this one and
            // the matching SizedBox below (the grid's own top padding is
            // zeroed out so it doesn't add extra, uneven space on that side).
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _showSearchBar
                  ? BookshelfSearchBar(
                      controller: _searchController,
                      searchQuery: _searchQuery,
                      visibleBooksCount: _visibleBooks.length,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      onClear: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    )
                  : BookshelfFilterRow(
                      selectedFilter: _readFilter,
                      onFilterChanged: (filter) =>
                          setState(() => _readFilter = filter),
                      availableCategories: _availableCategories,
                      selectedCategories: _selectedCategories,
                      onCategoryToggled: _onCategoryToggled,
                    ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  /// BUSINESS LOGIC: Show appropriate content based on state
  /// TECHNICAL: Loading → Empty → Grid (in priority order)
  Widget _buildMainContent() {
    if (_loading) {
      return const BookshelfLoadingState();
    }
    if (_visibleBooks.isEmpty) {
      return BookshelfEmptyState(
        message: _books.isEmpty
            ? 'Your bookshelf is empty. Tap + to add a book.'
            : 'No books match your search.',
      );
    }
    return BookshelfGrid(books: _visibleBooks, onBookTap: _onBookTap);
  }
}
