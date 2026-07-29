# ARCH-1 — Split the 2,050-line `main.dart` monolith

**Phase:** 3 (Architecture) · **Status:** ✅ Complete (code)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[ARCH-2-appconfig]] · [[ARCH-3-migrations-and-routing]]

## Problem
The whole app lived in one 2,050-line `main.dart`: seven screens, the Google Books HTTP client, ISBN/volume parsing helpers, and every widget. There were no models (`Map<String, dynamic>` with stringly-typed keys throughout), no repository/service layer (every screen called `Supabase.instance.client` directly, which makes the logic untestable), and state was raw `setState` plus a hand-rolled `ChangeNotifier`.

## What was done
Broke the monolith into a layered `lib/src/` structure. `main.dart` is now 15 lines — it only initializes Flutter bindings, calls `Supabase.initialize(...)`, and runs `MyApp`.

### New structure
```
lib/
  main.dart                      # 15 lines: bindings + Supabase.initialize + runApp
  src/
    app.dart                     # MyApp: MultiProvider wiring + MaterialApp.router
    core/
      config/app_config.dart     # build-time config (see ARCH-2)
      router/app_router.dart     # go_router + auth redirect (see ARCH-3)
      theme/                      # app_colors, app_theme, theme_provider (git mv)
      utils.dart                 # toHttpsUrl() helper
    data/
      models/
        book_search_result.dart  # typed Google Books volume + ISBN/volume keys
        shelf_book.dart          # typed shelf row + query/read-status helpers
      repositories/
        auth_repository.dart      # sign in/up/out, session, onAuthStateChange
        bookshelf_repository.dart # fetch/add/remove/setReadStatus over Supabase
      services/
        google_books_service.dart # injectable http.Client, search, ISBN lookup
    features/
      auth/         splash_screen, login_screen, signup_screen
      bookshelf/    bookshelf_screen + widgets/book_on_shelf
      book_search/  add_book_page, search_results_page
```

### Key improvements beyond the file move
- **Typed models.** `BookSearchResult` and `ShelfBook` replace `Map<String, dynamic>`; parsing/normalization logic (ISBN preference, volume keys, read-value coercion) moved into pure static methods that are now unit-tested.
- **Repository layer with dependency injection.** Screens no longer touch `Supabase.instance.client`. They depend on `AuthRepository` / `BookshelfRepository` / `GoogleBooksService`, injected via Provider. This is the prerequisite the testing plan (Section 7) called out — widgets can now be tested against mocked repositories.
- **`GoogleBooksService` takes an injectable `http.Client`** with a request timeout, so its network logic is testable without hitting the real API.

## Verification
- `flutter analyze` → **No issues found** (under the tightened lints from ARCH-4).
- `flutter test` → all tests pass, including the extracted pure-logic units (ISBN extraction, volume normalization, query builder, read-value coercion, password policy).
- `flutter build web --dart-define=GOOGLE_BOOKS_API_KEY=dummy_for_build` → **✓ Built build/web** (full tree compiles).
