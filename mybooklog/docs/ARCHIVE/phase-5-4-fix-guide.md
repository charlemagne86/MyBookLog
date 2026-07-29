---
name: phase-5-4-fixes
description: Phase 5.4 compilation and test failures - fixes for 10 failing tests
metadata:
  type: project
---

# Phase 5.4 Test Failure Analysis & Fixes

**Status:** Partial Success (84/94 tests passing, 89.4%)  
**Failures:** 10 tests with compilation/runtime errors  
**Root Causes:** File paths, null safety, missing mocks, widget structure  

## Summary

Phase 5.4 verification run shows strong progress:
- ✅ 84 tests passing (89.4%)
- ❌ 10 tests failing (10.6%)
- **Pattern:** All failures are systematic, not random flakiness
- **Solution:** Targeted fixes to mock infrastructure

## Detailed Failure Analysis

### Category 1: File Path Errors (2 failures)

**Tests Affected:**
- `login_screen_edge_cases_test.dart`
- `bookshelf_screen_edge_cases_test.dart` (compilation errors)

**Root Cause:**
Test files use incorrect import paths:
```dart
// ❌ WRONG - file doesn't exist
import 'package:mybooklog/src/features/login/login_screen.dart';

// ✅ CORRECT - actual location
import 'package:mybooklog/src/features/auth/login_screen.dart';
```

**Actual File Locations:**
- LoginScreen: `lib/src/features/auth/login_screen.dart`
- BookshelfScreen: `lib/src/features/bookshelf/bookshelf_screen.dart`

**Fix:**
Update import paths in Phase 5 test files to match actual structure.

---

### Category 2: Null Safety Type Errors (3 failures)

**Tests Affected:**
- `shelf_book_edge_cases_test.dart`
- `bookshelf_screen_edge_cases_test.dart`

**Root Cause:**
ShelfBook model has `thumbnailUri: String` (required, non-nullable).
Test files incorrectly pass `thumbnailUri: null`:

```dart
// ❌ WRONG - null not allowed for required String
ShelfBook(
  bookId: 'test',
  title: 'Test',
  author: 'Author',
  thumbnailUri: null,  // ERROR: Can't assign null to String
  isRead: false,
)

// ✅ CORRECT - empty string when no thumbnail
ShelfBook(
  bookId: 'test',
  title: 'Test',
  author: 'Author',
  thumbnailUri: '',  // Empty string for missing thumbnail
  isRead: false,
)
```

**Fix:**
Replace all `thumbnailUri: null` with `thumbnailUri: ''` in test files.

---

### Category 3: Missing Constructor Parameters (2 failures)

**Tests Affected:**
- `bookshelf_repository_error_test.dart`
- `auth_repository_error_test.dart`

**Root Cause:**
Repository constructors require Supabase client, but tests don't provide it:

```dart
// ❌ WRONG - missing required _client parameter
repository = BookshelfRepository();

// ✅ CORRECT - provide mock client
repository = BookshelfRepository(mockClient);
```

**Repository Signatures:**
```dart
class BookshelfRepository {
  final SupabaseClient _client;
  BookshelfRepository(this._client);  // Requires _client
}

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);  // Requires _client
}
```

**Fix:**
Add mock Supabase client setup in test setUp() methods:
```dart
late MockSupabaseClient mockClient;

setUp(() {
  mockClient = MockSupabaseClient();
  repository = BookshelfRepository(mockClient);
});
```

---

### Category 4: Widget Structure Issues (2 failures)

**Tests Affected:**
- `splash_and_signup_screen_test.dart`

**Root Cause:**
Test looks for TextField that doesn't exist in SignUpScreen:
```dart
// Test tries to find TextField
expect(find.byType(TextField), findsWidgets);

// But SignUpScreen may not have that widget or uses different structure
```

**Fix:**
Inspect actual SignUpScreen widget tree and update test to find correct widgets.

---

### Category 5: Import/Usage Errors (1 failure)

**Tests Affected:**
- `login_screen_edge_cases_test.dart`

**Root Cause:**
File import error cascades to multiple test cases, causing "Method not found: 'LoginScreen'" errors.

**Fix:**
Correct the import path fixes Category 1 errors.

---

## Implementation Plan

### Phase 5.4a: Quick Fixes (30 minutes)

1. **Fix File Paths**
   - Update `login_screen_edge_cases_test.dart` import
   - Update `bookshelf_screen_edge_cases_test.dart` import
   - Update `splash_and_signup_screen_test.dart` imports

2. **Fix Null Safety Issues**
   - Replace all `thumbnailUri: null` with `thumbnailUri: ''`
   - In: `shelf_book_edge_cases_test.dart` (8 instances)
   - In: `bookshelf_screen_edge_cases_test.dart` (5 instances)

3. **Fix Repository Constructors**
   - Create `MockSupabaseClient` extends Mock implements SupabaseClient
   - Add to: `bookshelf_repository_error_test.dart`
   - Add to: `auth_repository_error_test.dart`
   - Initialize in setUp() with repository = Repository(mockClient)

### Phase 5.4b: Widget Inspection (15 minutes)

4. **Verify SignUpScreen Structure**
   - Read actual SignUpScreen implementation
   - Find correct widget finders for test
   - Update `splash_and_signup_screen_test.dart`

### Phase 5.4c: Verification (20 minutes)

5. **Re-run Tests**
   - Execute full test suite again
   - Target: 94/94 passing (100%)
   - Measure coverage improvement

---

## Expected Results After Fixes

**Before:**
- 84/94 passing (89.4%)
- 10 compilation/type errors
- Coverage: ~52% (Phase 4 baseline)

**After:**
- 94/94 passing (100%) ✅
- 0 compilation errors ✅
- Coverage: ~67-72% (Phase 5 target)

---

## Files to Modify

1. `test/unit/models/shelf_book_edge_cases_test.dart` — 8 null fixes
2. `test/widget/screens/bookshelf_screen_edge_cases_test.dart` — 5 null fixes + imports
3. `test/widget/screens/login_screen_edge_cases_test.dart` — import path fix
4. `test/widget/screens/splash_and_signup_screen_test.dart` — import paths + widget finding
5. `test/unit/repositories/bookshelf_repository_error_test.dart` — mock client setup
6. `test/unit/repositories/auth_repository_error_test.dart` — mock client setup

---

## Root Cause Summary

| Category | Count | Fixable | Effort |
|----------|-------|---------|--------|
| File path errors | 2 | Yes | 5 min |
| Null safety | 3 | Yes | 10 min |
| Constructor params | 2 | Yes | 10 min |
| Widget structure | 2 | Yes | 15 min |
| Import errors | 1 | Yes | 5 min |
| **TOTAL** | **10** | **100%** | **~45 min** |

All failures are systematic and fixable. No design changes needed.

---

## Next Steps

1. Apply the 6 targeted fixes above
2. Re-run full test suite: `flutter test --coverage`
3. Verify: 94/94 tests passing
4. Measure coverage improvement (target: 67-72%)
5. Create Phase 5.4 completion summary
6. Document learnings in test framework guide

**Estimated Total Time:** 1-1.5 hours for full Phase 5.4 completion

