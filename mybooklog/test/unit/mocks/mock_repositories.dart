import 'package:mocktail/mocktail.dart';
import 'package:mybooklog/src/data/models/shelf_book.dart';
import 'package:mybooklog/src/data/models/book_search_result.dart';
import 'package:mybooklog/src/data/repositories/bookshelf_repository.dart';
import 'package:mybooklog/src/data/repositories/auth_repository.dart';

// BUSINESS LOGIC:
// Repositories abstract database/network operations. When testing business logic,
// we need to mock these operations to control what data they return.
// This lets us test error scenarios (network down, malformed data, etc.)
// that would be hard to reproduce against real backends.
//
// TECHNICAL:
// These mocks use mocktail to stub method returns and track call history.

class MockBookshelfRepository extends Mock implements BookshelfRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

// Setup helpers for common scenarios
class RepositorySetupHelpers {
  // BUSINESS LOGIC:
  // Successful shelf fetch returns books user has saved
  // TECHNICAL: Returns a non-empty list with realistic test data
  static void setupSuccessfulFetch(
    MockBookshelfRepository repo, {
    required List<ShelfBook> books,
  }) {
    when(() => repo.fetchShelf()).thenAnswer((_) async => books);
  }

  // BUSINESS LOGIC:
  // Network error when fetching shelf (user has no internet)
  // TECHNICAL: Throws exception with descriptive message
  static void setupNetworkErrorFetch(MockBookshelfRepository repo) {
    when(
      () => repo.fetchShelf(),
    ).thenThrow(Exception('Network error: Failed to fetch bookshelf'));
  }

  // BUSINESS LOGIC:
  // Empty shelf (no books added yet)
  // TECHNICAL: Returns empty list successfully
  static void setupEmptyShelf(MockBookshelfRepository repo) {
    when(() => repo.fetchShelf()).thenAnswer((_) async => []);
  }

  // BUSINESS LOGIC:
  // Successful book addition to shelf
  // TECHNICAL: Completes without throwing
  static void setupSuccessfulAddBook(MockBookshelfRepository repo) {
    when(
      () => repo.addBook(
        isbn: any(named: 'isbn'),
        title: any(named: 'title'),
        author: any(named: 'author'),
        thumbnail: any(named: 'thumbnail'),
      ),
    ).thenAnswer((_) async => false);
  }

  // BUSINESS LOGIC:
  // Duplicate book error (already on shelf)
  // TECHNICAL: Throws with specific error message
  static void setupDuplicateBookError(MockBookshelfRepository repo) {
    when(
      () => repo.addBook(
        isbn: any(named: 'isbn'),
        title: any(named: 'title'),
        author: any(named: 'author'),
        thumbnail: any(named: 'thumbnail'),
      ),
    ).thenReturn(Future.value(true));
  }

  // BUSINESS LOGIC:
  // Successful book removal from shelf
  // TECHNICAL: Completes without throwing
  static void setupSuccessfulRemoveBook(MockBookshelfRepository repo) {
    when(() => repo.removeBook(any())).thenAnswer((_) async {});
  }

  // BUSINESS LOGIC:
  // Successful read status update
  // TECHNICAL: Completes without throwing
  static void setupSuccessfulSetReadStatus(MockBookshelfRepository repo) {
    when(
      () => repo.setReadStatus(any(), isRead: any(named: 'isRead')),
    ).thenAnswer((_) async {});
  }

  // BUSINESS LOGIC:
  // Auth: Successful login with valid credentials
  // TECHNICAL: Returns session token
  static void setupSuccessfulLogin(MockAuthRepository repo) {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => 'session-token-123');
  }

  // BUSINESS LOGIC:
  // Auth: Login failure (invalid credentials)
  // TECHNICAL: Throws with "Invalid credentials" message
  static void setupInvalidCredentialsError(MockAuthRepository repo) {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Invalid email or password'));
  }

  // BUSINESS LOGIC:
  // Auth: Account not found
  // TECHNICAL: Throws with "No account" message
  static void setupAccountNotFoundError(MockAuthRepository repo) {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('No account found with this email'));
  }

  // BUSINESS LOGIC:
  // Auth: Successful signup (new account created)
  // TECHNICAL: Completes without throwing
  static void setupSuccessfulSignup(MockAuthRepository repo) {
    when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenAnswer((_) async {});
  }

  // BUSINESS LOGIC:
  // Auth: Email already exists
  // TECHNICAL: Throws with "Email exists" message
  static void setupEmailAlreadyExistsError(MockAuthRepository repo) {
    when(
      () => repo.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenThrow(Exception('Email already registered'));
  }

  // BUSINESS LOGIC:
  // Auth: Successful logout
  // TECHNICAL: Clears session, completes without throwing
  static void setupSuccessfulLogout(MockAuthRepository repo) {
    when(() => repo.signOut()).thenAnswer((_) async {});
  }

  // BUSINESS LOGIC:
  // Auth: Session expired (token no longer valid)
  // TECHNICAL: Throws with "Session expired" message
  static void setupSessionExpiredError(MockAuthRepository repo) {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Session expired'));
  }

  // BUSINESS LOGIC:
  // Auth: Rate limiting (too many login attempts)
  // TECHNICAL: Throws with "Rate limited" message
  static void setupRateLimitedError(MockAuthRepository repo) {
    when(
      () => repo.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('Too many login attempts. Try again later.'));
  }
}

// Test data factories for common book objects
class TestBookFactory {
  // BUSINESS LOGIC:
  // Create a realistic book for testing shelf operations
  // TECHNICAL: Returns a complete ShelfBook with all required fields
  static ShelfBook createTestBook({
    String? bookId,
    String title = 'Test Book',
    String? author = 'Test Author',
    String? thumbnailUri,
    bool isRead = false,
  }) {
    return ShelfBook(
      bookId: bookId ?? 'book-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      thumbnailUri:
          thumbnailUri ?? 'https://books.google.com/books/content?id=test',
      isRead: isRead,
    );
  }

  // BUSINESS LOGIC:
  // Create multiple test books for batch testing
  // TECHNICAL: Returns a list of N different books
  static List<ShelfBook> createTestBooks(int count) {
    return List.generate(
      count,
      (i) => createTestBook(
        bookId: 'book-$i',
        title: 'Test Book $i',
        author: 'Author $i',
      ),
    );
  }

  // BUSINESS LOGIC:
  // Create a book already marked as read
  // TECHNICAL: Sets isRead=true
  static ShelfBook createReadBook({
    String title = 'Read Book',
    String author = 'Test Author',
  }) {
    return createTestBook(title: title, author: author, isRead: true);
  }

  // BUSINESS LOGIC:
  // Create a book with very long title (edge case testing)
  // TECHNICAL: Returns book with 300+ character title
  static ShelfBook createBookWithLongTitle() {
    final longTitle = 'A' * 300 + ' Very Long Title For Edge Case Testing';
    return createTestBook(title: longTitle);
  }

  // BUSINESS LOGIC:
  // Create a book with special characters (Unicode testing)
  // TECHNICAL: Returns book with various character sets
  static ShelfBook createBookWithSpecialCharacters() {
    return createTestBook(
      title: 'Test™ 中文 العربية 🎉',
      author: 'Author™ 中文 العربية',
    );
  }
}
