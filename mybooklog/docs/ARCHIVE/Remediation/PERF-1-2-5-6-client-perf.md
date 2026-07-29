# PERF-1 / PERF-2 / PERF-5 / PERF-6 — Client performance

**Phase:** 2 (Performance) · **Status:** ✅ Complete (client)
**Related:** [[PROJECT_ANALYSIS]] · [[Remediation-Index]] · [[PERF-3-4-rls-initplan-and-index]]

## PERF-1 — One embedded query instead of two round-trips
`_fetchBooks` fetched `bookshelf_items`, then separately fetched `books_catalog` and merged client-side.
- **Fix:** single PostgREST embedded select over the FK — `.select('*, books_catalog(id, title, author, thumbnail_uri)')` — then flatten the embedded object into the flat map the grid expects.

## PERF-2 — No full refetch after mutations
Toggling read-status or removing a book re-downloaded the whole shelf.
- **Fix:** `_removeBookFromShelf` now removes the item from the local `_books` list; `_toggleBookReadStatus` patches the affected item in place (`is_read` + `marked_read_on`). Both drop the trailing `await _fetchBooks()`.

## PERF-5 — Uncached, cleartext cover images
`Image.network` had no caching and used Google's `http://` URLs, which are blocked on Android/iOS release builds.
- **Fix:** added `cached_network_image`; both cover widgets (search results + shelf tile) now use `CachedNetworkImage` with placeholder/error widgets. Added a top-level `_toHttps()` helper applied at display **and** at ingest (`_normalizeGoogleBooksItems`), so values persisted to `books_catalog` are https going forward.

## PERF-6 — No network timeout
- **Fix:** added `const _googleBooksTimeout = Duration(seconds: 10)` and `.timeout(_googleBooksTimeout)` on all three `http.get` calls (search, load-more, exact-volume).

## Verification
- `flutter analyze` → **No issues found**.
- `flutter test` → 3/3 pass.
- `flutter pub add cached_network_image` succeeded; `crypto` remains removed.
