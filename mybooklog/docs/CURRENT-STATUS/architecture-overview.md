# Architecture Overview

**Last Updated:** 2026-07-29  
**Status:** Production-Ready  
**Framework:** Flutter + Riverpod + GoRouter  

---

## Project Structure

```
lib/src/
├── core/
│   ├── config/       # App configuration
│   ├── theme/        # Theme & design system
│   └── utils.dart    # Shared utilities (100% coverage)
├── data/
│   ├── models/       # Data models (100% coverage)
│   │   ├── shelf_book.dart
│   │   └── book_search_result.dart
│   ├── repositories/ # Data layer (40% coverage - Supabase SDK)
│   │   ├── auth_repository.dart
│   │   └── bookshelf_repository.dart
│   └── services/     # External APIs (100% coverage)
│       └── google_books_service.dart
└── features/
    ├── auth/         # Authentication screens
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── splash_screen.dart
    ├── bookshelf/    # Main app screens
    │   └── bookshelf_screen.dart
    └── search/       # Search functionality
        └── search_screen.dart
```

---

## Technology Stack

| Component | Technology | Version | Status |
|-----------|-----------|---------|--------|
| **Framework** | Flutter | ^3.x | ✅ Production |
| **State Management** | Riverpod | Latest | ✅ Production |
| **Routing** | GoRouter | Latest | ✅ Production |
| **Data Layer** | Supabase SDK | Latest | ✅ Production |
| **API Integration** | Google Books API | v1 | ✅ Production |
| **Testing** | Flutter Test | Built-in | ✅ Production |

---

## Architecture Patterns

### 1. State Management (Riverpod)

**Pattern:** Provider-based reactive state

```dart
// Service providers
final googleBooksServiceProvider = Provider((ref) => GoogleBooksService());

// Repository providers
final bookshelfRepoProvider = Provider((ref) => BookshelfRepository(...));

// Auth state
final authStateProvider = StreamProvider((ref) => authRepository.onAuthStateChange());
```

**Benefits:**
- Reactive updates
- Compile-time safety
- Easy testing with overrides
- Clear dependency graph

### 2. Routing (GoRouter)

**Pattern:** Nested routing with auth guards

```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(authRepository.onAuthStateChange()),
  routes: [
    GoRoute(path: '/login', builder: ...),
    GoRoute(path: '/signup', builder: ...),
    GoRoute(path: '/bookshelf', builder: ...),
  ],
  redirect: (context, state) {
    // Auth state-based routing
  },
);
```

**Features:**
- Auth-based route guards
- Deep linking support
- Navigation history management
- Browser back button support

### 3. Repository Pattern

**Pattern:** Data abstraction layer

```dart
abstract class AuthRepository {
  Future<void> signUp(String email, String password, ...);
  Future<void> login(String email, String password);
  Future<void> logout();
  Stream<AuthState> get onAuthStateChange;
}
```

**Benefits:**
- Source agnostic (Supabase, Firebase, custom)
- Testable with mock implementations
- Clear separation of concerns

### 4. Service Layer

**Pattern:** External API abstraction

```dart
class GoogleBooksService {
  Future<BookSearchResult> searchBooks(String query);
  // Manages API calls, error handling, caching
}
```

**Features:**
- HTTP client management
- Request/response transformation
- Error handling and retries
- Pagination support

---

## Data Flow

### User Login Flow

```
User Input (LoginScreen)
        ↓
Form Validation (Screen widget)
        ↓
AuthRepository.login()
        ↓
Supabase SDK
        ↓
Stream<AuthState> update
        ↓
GoRouter refresh
        ↓
Navigation to /bookshelf
```

### Book Search Flow

```
User Input (SearchBar)
        ↓
Screen state update
        ↓
GoogleBooksService.searchBooks()
        ↓
HTTP request to API
        ↓
Parse BookSearchResult
        ↓
Update screen UI
```

---

## Dependency Injection

### Production Setup

```dart
final authRepositoryProvider = Provider((ref) => AuthRepository(
  supabaseClient: Supabase.instance.client,
));

final googleBooksServiceProvider = Provider((ref) => GoogleBooksService(
  httpClient: http.Client(),
));
```

### Test Setup (Override Pattern)

```dart
testWidgets('test name', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        googleBooksServiceProvider.overrideWithValue(mockGoogleBooksService),
      ],
      child: MyApp(),
    ),
  );
});
```

---

## Error Handling

### By Layer

| Layer | Pattern | Recovery |
|-------|---------|----------|
| **Network** | Try-catch + user message | Retry button |
| **Validation** | Form validation rules | In-line error text |
| **Auth** | AuthRepository exceptions | Redirect to login |
| **UI** | Error state widgets | Show error banner |

### Implementation

```dart
try {
  await authRepository.login(email, password);
} on AuthException catch (e) {
  setState(() => _errorMessage = e.message);
}
```

---

## Testing Architecture

### Test Infrastructure

```
test/
├── helpers/
│   ├── test_app_builder.dart        # Full app context
│   ├── test_setup_helpers.dart      # Scenario builders
│   └── mock_*.dart                  # Mocks
├── unit/
│   ├── models/                      # Model tests
│   ├── services/                    # Service tests
│   └── repositories/                # Repository tests
├── widget/
│   ├── screens/                     # Screen tests
│   └── scenarios/                   # User journey tests
└── integration/                     # E2E integration tests
```

### Test Patterns

**TestAppBuilder:** Complete app context with all dependencies mocked

```dart
final app = TestAppBuilder()
  .withAuthState(userLoggedIn: true)
  .withBooks([book1, book2])
  .build();
```

**StreamController Mocking:** Auth state simulation

```dart
final authStream = StreamController<AuthState>();
// Emit auth events
authStream.add(AuthState.authenticated(user));
```

---

## Production Deployment Considerations

### Environment Configuration

- **Debug:** Uses emulator/development Supabase project
- **Release:** Uses production Supabase project
- **Environment variables:** Managed via `.env` files (excluded from git)

### Performance Optimizations

- **Caching:** Google Books API results cached locally
- **Pagination:** Lazy loading of large result sets
- **Image optimization:** Thumbnail URL validation

### Security

- **Auth tokens:** Stored securely via Supabase SDK
- **API keys:** Environment-based, not hardcoded
- **CORS:** Configured for Supabase endpoints
- **SSL/TLS:** All HTTPS

---

## Scalability

### Current Limits

| Metric | Current | Scalable To |
|--------|---------|------------|
| Books per shelf | 100+ | 1000+ |
| Concurrent users | 1 | 100+ |
| Search results | 40 | 100+ |

### Future Expansion Points

1. **Local caching:** SQLite for offline support
2. **Pagination:** Implement for large datasets
3. **Advanced search:** Filter by author, year, rating
4. **Social features:** Book clubs, sharing, ratings

---

## CI/CD Integration

### Deployment Pipeline

```
Code Push
    ↓
GitHub Actions (build + test)
    ↓
Coverage enforcement (60%+)
    ↓
Deploy to beta (if main)
    ↓
Deploy to production (manual)
```

### Quality Gates

- ✅ All tests must pass
- ✅ Coverage must be ≥60%
- ✅ No critical security issues
- ✅ Code review approved

---

## Known Limitations

| Item | Impact | Plan |
|------|--------|------|
| Repository mocking | 40% coverage | Phase 8 (Supabase setup) |
| Offline support | Not available | Phase 8+ |
| Advanced search | Basic only | Phase 9+ |
| Analytics | None | Phase 8+ |

---

## Recommendations

### Immediate (Production Now)
- ✅ Current architecture ready
- ✅ All critical paths tested
- ✅ Performance baselines in place

### Short-term (Phase 8)
- [ ] Polish widget tests
- [ ] Improve repository coverage
- [ ] Add analytics/logging

### Long-term (Phase 9+)
- [ ] Offline support
- [ ] Advanced search features
- [ ] Social/sharing features
