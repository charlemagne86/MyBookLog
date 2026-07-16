import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/shelf_book.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/bookshelf_repository.dart';
import 'widgets/book_on_shelf.dart';

class BookshelfScreen extends StatefulWidget {
  const BookshelfScreen({super.key});

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen> {
  List<ShelfBook> _books = [];
  bool _loading = true;
  bool _showSearchBar = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
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

  List<ShelfBook> get _visibleBooks {
    final query = _searchQuery.trim();
    if (query.length < 3) return _books;
    return _books.where((b) => b.matchesQuery(query)).toList();
  }

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
      if (mounted) setState(() => _contextMenuBookSelectionKey = null);
    }

    if (selectedAction == _menuActionRemove) {
      await _removeBook(book);
    } else if (selectedAction == _menuActionToggleRead) {
      await _toggleReadStatus(book);
    }
  }

  Future<void> _removeBook(ShelfBook book) async {
    try {
      await _repo.removeBook(book.bookId);
      if (!mounted) return;
      setState(() {
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

  Future<void> _toggleReadStatus(ShelfBook book) async {
    final newValue = !book.isRead;
    try {
      await _repo.setReadStatus(book.bookId, isRead: newValue);
      if (!mounted) return;
      setState(() {
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

  Future<void> _onAddBook() async {
    await context.push('/shelf/add');
    if (!mounted) return;
    await _fetchBooks();
  }

  void _onSearchBook() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

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
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        childAspectRatio: 0.48,
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
