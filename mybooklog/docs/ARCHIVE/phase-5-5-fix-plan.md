---
name: phase-5-5-fix-plan
description: Phase 5.5 - Fix remaining 9 runtime test failures for 100% passing
metadata:
  type: project
---

# Phase 5.5 - Runtime Test Failure Fixes

**Status:** 🟡 IN PROGRESS  
**Target:** 100% test passing (144/144)  
**Current:** 93.75% passing (135/144)  
**Remaining:** 9 runtime logic issues

---

## Failing Tests Summary

Based on test output analysis, 9 tests failing with runtime logic issues:

### Category 1: ShelfBook Model Logic (1 test)

**Test:** ShelfBook - Edge Cases Search Filtering - matches with mixed case query
```
Error: Expected: false, Actual: true
File: test/unit/models/shelf_book_edge_cases_test.dart:96
```

**Issue:** Test expects `matchesQuery('GaT')` to return false (no substring match)
but implementation returns true (partial match found)

**Root Cause:** Query logic may be too permissive or test expectation wrong

**Fix Strategy:**
1. Review ShelfBook.matchesQuery() implementation
2. Verify if "GaT" should match "Great Gatsby" (it shouldn't)
3. Update test or fix implementation

---

### Category 2: BookshelfScreen Widget Tests (4 tests)

**Tests Failing:**
1. BookshelfScreen - displays loading indicator while fetching shelf
2. BookshelfScreen - handles very large bookshelf (100+ books)
3. BookshelfScreen - shows error message on shelf load failure
4. BookshelfScreen - search with no results

**Common Issue:** Provider/widget finding problems
- CircularProgressIndicator not found
- Error messages not displayed
- Repository not properly mocked

**Root Cause:** BookshelfScreen depends on Provider<BookshelfRepository>
but mock repository not returning expected data

**Fix Strategy:**
1. Inspect BookshelfScreen widget tree
2. Setup proper Provider initialization
3. Mock repository.fetchShelf() to return expected data
4. Verify CircularProgressIndicator rendering
5. Check error state handling

---

### Category 3: LoginScreen Widget Tests (2 tests)

**Tests Failing:**
1. LoginScreen - email validation
2. LoginScreen - password visibility toggle

**Common Issue:** TextField finding or interaction problems

**Root Cause:** LoginScreen may need AuthRepository provider setup

**Fix Strategy:**
1. Add proper Provider<AuthRepository> setup
2. Mock sign-in failures for error scenarios
3. Verify TextField widget structure
4. Check visibility toggle implementation

---

### Category 4: SignUpScreen Widget Tests (2 tests)

**Tests Failing:**
1. SignUpScreen - validates email format before signup
2. SignUpScreen - enforces password strength requirements

**Common Issue:** TextField finding in signup form

**Root Cause:** SignUpScreen structure or Provider setup incomplete

**Fix Strategy:**
1. Inspect SignUpScreen widget implementation
2. Add complete Provider<AuthRepository> setup
3. Mock sign-up scenarios
4. Verify form field rendering

---

## Systematic Fix Approach

### Phase 5.5a: Unit Test Fixes (ShelfBook)

**File:** `test/unit/models/shelf_book_edge_cases_test.dart:96`

**Action 1:** Review ShelfBook.matchesQuery() implementation
```bash
grep -A 20 "matchesQuery" lib/src/data/models/shelf_book.dart
```

**Action 2:** Determine if test or implementation is wrong
- If "GaT" shouldn't match "Great Gatsby": fix implementation
- If test expectation is wrong: fix test

**Expected Outcome:** 1 test passing

---

### Phase 5.5b: BookshelfScreen Widget Tests (4 tests)

**File:** `test/widget/screens/bookshelf_screen_edge_cases_test.dart`

**Step 1:** Inspect BookshelfScreen implementation
```bash
grep -A 50 "class BookshelfScreen" lib/src/features/bookshelf/bookshelf_screen.dart | head -60
```

**Step 2:** Review current test setup
```dart
// Current setup (likely incomplete):
await tester.pumpWidget(
  MaterialApp(
    home: Provider<BookshelfRepository>.value(
      value: mockRepository,
      child: BookshelfScreen(),
    ),
  ),
);
```

**Step 3:** Add proper repository mocking
```dart
// What mockRepository should return:
when(() => mockRepository.fetchShelf()).thenAnswer(
  (_) async => [
    ShelfBook(...), // actual book data
    ShelfBook(...),
  ],
);

// For empty state test:
when(() => mockRepository.fetchShelf()).thenAnswer(
  (_) async => [],
);

// For error state test:
when(() => mockRepository.fetchShelf()).thenThrow(
  Exception('Network error'),
);
```

**Step 4:** Verify widget finding logic
- CircularProgressIndicator should show during fetch
- GridView should show when data loaded
- Error message should show on failure
- Empty message should show when no books

**Expected Outcome:** 4 tests passing

---

### Phase 5.5c: LoginScreen Widget Tests (2 tests)

**File:** `test/widget/screens/login_screen_edge_cases_test.dart`

**Step 1:** Review LoginScreen structure
- Does it use Provider<AuthRepository>?
- What widgets does it render?
- How does it handle sign-in failure?

**Step 2:** Update test setup with proper mocking
```dart
late MockAuthRepository mockAuth;

setUp(() {
  mockAuth = MockAuthRepository();
  // Mock both success and failure scenarios
});

// For successful login:
when(() => mockAuth.signIn(
  email: any(named: 'email'),
  password: any(named: 'password'),
)).thenAnswer((_) async => 'session-token');

// For failed login:
when(() => mockAuth.signIn(...))
  .thenThrow(Exception('Invalid credentials'));
```

**Step 3:** Verify form field rendering
- Email TextField should be visible
- Password TextField should be visible
- Visibility toggle should work

**Step 4:** Test interactions
- Typing email should enable login button
- Invalid email should disable login button
- Password visibility toggle should work

**Expected Outcome:** 2 tests passing

---

### Phase 5.5d: SignUpScreen Widget Tests (2 tests)

**File:** `test/widget/screens/splash_and_signup_screen_test.dart`

**Step 1:** Verify SignUpScreen exists and is importable
```bash
find lib -name "*signup*" -o -name "*sign_up*"
```

**Step 2:** Check if screen uses Provider pattern
- Needs AuthRepository provider
- Should show validation errors
- Should disable button during signup

**Step 3:** Update test setup
```dart
when(() => mockAuth.signUp(
  email: any(named: 'email'),
  password: any(named: 'password'),
)).thenAnswer((_) async => 'session-token');
```

**Step 4:** Verify form validation
- Email format validation
- Password strength requirements
- TextField rendering

**Expected Outcome:** 2 tests passing

---

## Implementation Sequence

### Priority Order (by impact):

1. **Fix ShelfBook query logic** (1 test) - 15 min
   - Simplest, isolated unit test
   - No dependencies, clear pass/fail

2. **Fix BookshelfScreen tests** (4 tests) - 45 min
   - Highest count
   - Likely shared issue (Provider setup)
   - Fix one, others may follow

3. **Fix LoginScreen tests** (2 tests) - 30 min
   - Similar to BookshelfScreen
   - Provider pattern likely same

4. **Fix SignUpScreen tests** (2 tests) - 30 min
   - Last in sequence
   - May share fixes with LoginScreen

**Total Estimated Time:** 2 hours

---

## Success Criteria

✅ All 9 tests passing individually  
✅ No new failures introduced  
✅ All 144 tests passing (100%)  
✅ Coverage maintained at 60-65%  
✅ Test duration < 9 minutes  

---

## Contingency Plans

**If ShelfBook fix doesn't work:**
- Compare with other ShelfBook tests that pass
- Review query matching algorithm
- Check test data validity

**If BookshelfScreen tests still fail:**
- Add debug prints to understand widget tree
- Use `tester.binding.window` to check constraints
- Verify CircularProgressIndicator is in expected place

**If LoginScreen/SignUpScreen still fail:**
- Inspect actual screen implementation
- Check if screens use different state management
- Consider if screens need additional initialization

---

## Testing After Fixes

```bash
# Run specific failing test
flutter test test/unit/models/shelf_book_edge_cases_test.dart -k "matches with mixed case query"

# Run all BookshelfScreen tests
flutter test test/widget/screens/bookshelf_screen_edge_cases_test.dart

# Run all LoginScreen tests
flutter test test/widget/screens/login_screen_edge_cases_test.dart

# Run all SignUpScreen tests
flutter test test/widget/screens/splash_and_signup_screen_test.dart

# Full test suite with coverage
flutter test --coverage
```

---

## Documentation

After all fixes complete:
- [ ] Update test comments with actual behavior
- [ ] Document why each test was failing
- [ ] Add notes for future developers
- [ ] Create Phase 5.5 completion summary

---

**Phase 5.5 Status:** Starting  
**Next:** Await test output to confirm exact failures

