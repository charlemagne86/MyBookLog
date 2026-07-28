import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/shelf_book.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bookshelf_repository.dart';
import 'widgets/book_on_shelf.dart';

/// The app's home screen: the user's bookshelf.
///
/// Books are shown as a grid of covers, three per row. From here the user can:
///   * tap + to search for and add a new book,
///   * tap the magnifying glass to filter the shelf by title or author,
///   * press and hold a book to remove it or mark it read/unread,
///   * tap the door icon to log out.
class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  // The full list of the user's books, as last loaded from the database.
  List<ShelfBook> _books = [];
  // True while the first load is in flight (shows the spinner).
  bool _loading = true;
  // Whether the filter box is currently open, and what's typed into it.
  bool _showSearchBar = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  // Which book (if any) is currently "lifted" because its press-and-hold
  // menu is open — used purely for the visual highlight effect.
  String? _contextMenuBookSelectionKey;

  static const String _menuActionRemove = 'remove';
  static const String _menuActionToggleRead = 'toggle_read';

  BookshelfRepository get _repo => context.read<BookshelfRepository>();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// The books to actually show on screen. If the filter box has fewer than
  /// three characters typed, we show everything (filtering on one or two
  /// letters would flicker uselessly while the user is still typing).
  List<ShelfBook> get _visibleBooks {
    final query = _searchQuery.trim();
    if (query.length < 3) return _books;
    return _books.where((b) => b.matchesQuery(query)).toList();
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

  /// Runs when the user presses and holds a book.
  ///
  /// The sequence: visually "lift" the pressed book, give a small vibration
  /// so the user feels the press registered, then open a little menu right
  /// where their finger is with two choices — Remove Book, or Mark as
  /// Read/Unread. Whatever they pick (or dismiss) is handled at the end.
  Future<void> _onBookLongPress(ShelfBook book, Offset globalPosition) async {
    setState(() => _contextMenuBookSelectionKey = book.bookId);
    await HapticFeedback.selectionClick();
    await HapticFeedback.lightImpact();
    if (!mounted) return;

    String? selectedAction;
    try {
      selectedAction = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          globalPosition.dx,
          globalPosition.dy,
          globalPosition.dx,
          globalPosition.dy,
        ),
        items: [
          const PopupMenuItem<String>(
            value: _menuActionRemove,
            child: Text(
              'Remove Book',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          PopupMenuItem<String>(
            value: _menuActionToggleRead,
            child: Text(
              book.isRead ? 'Mark as Unread' : 'Mark as Read',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );
    } finally {
      // The menu has closed (chosen or dismissed) — un-lift the book.
      if (mounted) setState(() => _contextMenuBookSelectionKey = null);
    }

    if (selectedAction == _menuActionRemove) {
      await _removeBook(book);
    } else if (selectedAction == _menuActionToggleRead) {
      await _toggleReadStatus(book);
    }
  }

  /// Deletes a book from the shelf: first in the database, and only if that
  /// succeeds, from the grid on screen. A brief confirmation (or error)
  /// message appears at the bottom either way.
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
    }
  }

  /// Flips a book between read and unread: saves the change to the database
  /// first, then updates the checkmark badge on screen to match.
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
    }
  }

  /// Opens the "Add Book" flow, and when the user comes back, reloads the
  /// shelf so any newly added book appears immediately.
  Future<void> _onAddBook() async {
    await context.push('/shelf/add');
    if (!mounted) return;
    await _fetchBooks();
  }

  /// Opens or closes the shelf's filter box. Closing it also erases the
  /// typed text so the full shelf is visible again.
  void _onSearchBook() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
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
    final colorScheme = Theme.of(context).colorScheme;
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
            const SizedBox(height: 12),
            if (_showSearchBar) _buildSearchBar(colorScheme),
            Expanded(child: _buildGrid(colorScheme)),
          ],
        ),
      ),
    );
  }

  /// The filter box that slides in under the title bar. Its helper line
  /// coaches the user ("Enter at least 3 characters!") and then reports how
  /// many books match. The small × button clears the text in one tap.
  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search title or author',
              helperText: _searchQuery.trim().length < 3
                  ? 'Enter at least 3 characters!'
                  : '${_visibleBooks.length} matching '
                        '${_visibleBooks.length == 1 ? 'book' : 'books'}',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () => setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      }),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// The main body of the screen. It shows one of three things:
  ///   1. a spinner while the shelf is still loading,
  ///   2. a helpful message when there is nothing to show (shelf empty, or
  ///      no books match the filter),
  ///   3. otherwise, the grid of book covers itself.
  Widget _buildGrid(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_visibleBooks.isEmpty) {
      return Center(
        child: Text(
          _books.isEmpty
              ? 'Your bookshelf is empty. Tap + to add a book.'
              : 'No books match your search.',
          style: TextStyle(fontSize: 16, color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
      );
    }
    // Three covers per row; each cell is taller than wide, like a real book.
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 0.44,
      ),
      itemCount: _visibleBooks.length,
      itemBuilder: (context, index) {
        final book = _visibleBooks[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (details) =>
              _onBookLongPress(book, details.globalPosition),
          child: BookOnShelf(
            imageUrl: book.thumbnailUri,
            title: book.title,
            isRead: book.isRead,
            isContextMenuTarget: _contextMenuBookSelectionKey == book.bookId,
          ),
        );
      },
    );
  }
}
