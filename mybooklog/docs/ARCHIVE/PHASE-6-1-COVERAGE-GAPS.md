---
name: phase-6-1-coverage-gaps
description: Phase 6.1 - Coverage gap analysis and prioritized test plan
metadata:
  type: project
---

# Phase 6.1 — Coverage Gap Analysis

**Date:** 2026-07-29  
**Current Coverage:** 59.6% (388/651 lines)  
**Target:** 75-80%  
**Gap to Close:** +15-20%  

---

## Coverage Summary by File

| File | Lines | Covered | Coverage | Priority | Gap |
|------|-------|---------|----------|----------|-----|
| **CRITICAL (0-20%)** |
| app_colors.dart | 1 | 0 | 0.0% | LOW | - |
| splash_screen.dart | 23 | 1 | 4.3% | HIGH | +18.7% |
| bookshelf_repository.dart | 30 | 2 | 6.7% | CRITICAL | +83.3% |
| auth_repository.dart | 19 | 3 | 15.8% | CRITICAL | +74.2% |
| **IMPORTANT (20-60%)** |
| google_books_service.dart | 37 | 9 | 24.3% | HIGH | +50.7% |
| app_config.dart | 2 | 1 | 50.0% | MEDIUM | +25.0% |
| bookshelf_screen.dart | 143 | 78 | 54.5% | MEDIUM | +25.5% |
| signup_screen.dart | 91 | 51 | 56.0% | MEDIUM | +24.0% |
| book_search_result.dart | 42 | 24 | 57.1% | MEDIUM | +22.9% |
| **GOOD (70%+)** |
| app_theme.dart | 127 | 93 | 73.2% | LOW | - |
| book_on_shelf.dart | 54 | 46 | 85.2% | LOW | - |
| shelf_book.dart | 22 | 21 | 95.5% | LOW | - |
| login_screen.dart | 56 | 55 | 98.2% | LOW | - |
| utils.dart | 4 | 4 | 100.0% | COMPLETE | ✓ |
| **TOTAL** | **651** | **388** | **59.6%** | | **+15-20%** |

---

## Gap Analysis by Priority

### CRITICAL PRIORITY (Must cover for Phase 6)

#### 1. bookshelf_repository.dart — 6.7% (2/30 lines)
**File:** `lib/src/data/repositories/bookshelf_repository.dart`  
**Gap:** 83.3% (28 lines uncovered)  
**Impact:** Bookshelf operations are core to app functionality

**What's Covered:**
- Minimal coverage of existing mocks/fixtures

**What's Missing:**
- fetchShelf() RPC call
- addBook() RPC call
- removeBook() RPC call
- setReadStatus() RPC call
- Error handling and edge cases
- Session/auth edge cases

**Estimated Tests Needed:** 8-10 tests

**Test Plan:**
```dart
// BookshelfRepository - Fetch Operations
- Test successful shelf fetch
- Test fetch with empty shelf
- Test fetch with large shelf (100+ items)
- Test fetch on network error
- Test fetch on session expired
- Test fetch on malformed response

// BookshelfRepository - Add/Remove Operations
- Test add book successfully
- Test add duplicate book
- Test add on network error
- Test remove book successfully
- Test remove non-existent book

// BookshelfRepository - Status Updates
- Test mark book as read
- Test mark book as unread
- Test status update on invalid state
```

**Priority Reasoning:** Core CRUD operations; if untested, regression risk is high.

---

#### 2. auth_repository.dart — 15.8% (3/19 lines)
**File:** `lib/src/data/repositories/auth_repository.dart`  
**Gap:** 74.2% (16 lines uncovered)  
**Impact:** Authentication is critical for app security and access control

**What's Covered:**
- Minimal coverage of basic structure

**What's Missing:**
- signIn() RPC call
- signUp() RPC call
- signOut() RPC call
- Password validation
- Email validation
- Session management
- Error handling

**Estimated Tests Needed:** 8-12 tests (many already exist in error_test.dart)

**Test Plan:**
```dart
// AuthRepository - Sign In
- Test successful login with valid credentials
- Test login failure with wrong password
- Test login failure with invalid email format
- Test login with rate limiting (429)
- Test login timeout

// AuthRepository - Sign Up
- Test successful signup with valid data
- Test signup with weak password
- Test signup with email already exists
- Test signup with invalid email format

// AuthRepository - Sign Out
- Test successful logout
- Test logout with network error
- Test logout with expired session
```

**Priority Reasoning:** Authentication bypasses can be security issues; critical paths must be tested.

---

#### 3. google_books_service.dart — 24.3% (9/37 lines)
**File:** `lib/src/data/services/google_books_service.dart`  
**Gap:** 50.7% (28 lines uncovered)  
**Impact:** Affects search functionality and book data accuracy

**What's Covered:**
- Basic API structure

**What's Missing:**
- search() method full coverage
- Response parsing edge cases
- Timeout handling
- Rate limiting (429) handling
- Malformed response handling
- Special character handling in queries

**Estimated Tests Needed:** 6-8 tests

**Test Plan:**
```dart
// GoogleBooksService - Search
- Test successful search with results
- Test search with empty results
- Test search with timeout (>5s)
- Test search on 429 rate limiting
- Test search with malformed API response
- Test search with special characters
- Test search with very long query
- Test search result parsing (ISBN extraction, etc.)
```

**Priority Reasoning:** API integration is common failure point; malformed responses can crash app.

---

### HIGH PRIORITY (Should cover for better quality)

#### 4. splash_screen.dart — 4.3% (1/23 lines)
**File:** `lib/src/features/auth/splash_screen.dart`  
**Gap:** 18.7% (22 lines uncovered)  
**Impact:** App initialization; if broken, users can't access app

**What's Covered:**
- Minimal widget structure

**What's Missing:**
- Session check on app start
- Auth state evaluation
- Navigation to login/bookshelf
- Error handling
- Loading state

**Estimated Tests Needed:** 3-5 tests

**Test Plan:**
```dart
// SplashScreen - Initialization
- Test shows splash while checking auth
- Test navigates to bookshelf when authenticated
- Test navigates to login when not authenticated
- Test handles session check error
- Test timeout on session check (>5s)
```

**Priority Reasoning:** Critical user journey; app won't work if splash screen fails.

---

### MEDIUM PRIORITY (Should cover for better quality)

#### 5. bookshelf_screen.dart — 54.5% (78/143 lines)
**File:** `lib/src/features/bookshelf/bookshelf_screen.dart`  
**Gap:** 25.5% (65 lines uncovered)  
**Impact:** Main user-facing screen; UX quality depends on coverage

**What's Missing:**
- Error state rendering
- Loading state rendering
- Empty shelf rendering
- Search functionality
- Shelf refresh/reload
- Book item interactions

**Estimated Tests Needed:** 5-7 tests

**Related to Phase 5 Pending:**
- "shows error message on shelf load failure" (Phase 5 edge case)

**Test Plan:**
```dart
// BookshelfScreen - Display States
- Test shows loading indicator while fetching
- Test shows bookshelf with items
- Test shows empty message when shelf is empty
- Test shows error message on load failure
- Test refresh button works

// BookshelfScreen - Interactions
- Test selecting a book navigates to detail
- Test remove book shows confirmation
- Test confirm remove removes from shelf
```

---

#### 6. signup_screen.dart — 56.0% (51/91 lines)
**File:** `lib/src/features/auth/signup_screen.dart`  
**Gap:** 24.0% (40 lines uncovered)  
**Impact:** User onboarding; signup failures drive churn

**What's Missing:**
- Form validation state
- Password strength indicator feedback
- Email validation feedback
- Error message display
- Success state handling
- Loading state during signup

**Estimated Tests Needed:** 4-6 tests

**Test Plan:**
```dart
// SignUpScreen - Validation
- Test email validation in real-time
- Test password requirements display
- Test password match validation
- Test first/last name requirements

// SignUpScreen - Form States
- Test shows error when signup fails
- Test disables button during submission
- Test navigates to bookshelf on success
```

---

#### 7. book_search_result.dart — 57.1% (24/42 lines)
**File:** `lib/src/data/models/book_search_result.dart`  
**Gap:** 22.9% (18 lines uncovered)  
**Impact:** Data parsing quality affects search results

**What's Missing:**
- Edge cases in model parsing
- Null handling for optional fields
- ISBN extraction edge cases
- URL normalization

**Estimated Tests Needed:** 3-4 tests

**Test Plan:**
```dart
// BookSearchResult - Edge Cases
- Test parsing with missing thumbnailUrl
- Test parsing with malformed thumbnailUrl
- Test parsing with missing ISBN
- Test ISBN extraction from complex response
```

---

#### 8. app_config.dart — 50.0% (1/2 lines)
**File:** `lib/src/core/config/app_config.dart`  
**Gap:** 25.0% (1 line uncovered)  
**Impact:** Low (usually just constants)

**Test Plan:**
- Add one simple test for config fallback/validation

---

### LOW PRIORITY (Good coverage, optimization only)

#### app_theme.dart — 73.2%
- Coverage is good
- Missing 34 lines likely dead code or override methods
- Can ignore for Phase 6

#### book_on_shelf.dart — 85.2%
- Coverage is good
- Missing 8 lines likely widget variants/edge states
- Can ignore for Phase 6

#### shelf_book.dart — 95.5%
- Nearly complete coverage
- Missing 1 line likely edge case
- Can ignore for Phase 6

#### login_screen.dart — 98.2%
- Excellent coverage
- Missing 1 line likely edge case
- Can ignore for Phase 6

#### utils.dart — 100%
- Perfect coverage
- Complete

#### app_colors.dart — 0%
- Only 1 line of constants
- Ignore (no logic to test)

---

## Prioritized Test Implementation Order

### Phase 6.2 — CRITICAL (must do)
1. bookshelf_repository.dart (8-10 tests) — +75% coverage improvement
2. auth_repository.dart (8-12 tests) — +65% coverage improvement
3. google_books_service.dart (6-8 tests) — +45% coverage improvement
4. **Subtotal: 22-30 tests, +185% total line coverage improvement**

### Phase 6.3 — HIGH & MEDIUM (should do)
5. splash_screen.dart (3-5 tests) — +15% coverage improvement
6. bookshelf_screen.dart (5-7 tests) — +20% coverage improvement
7. signup_screen.dart (4-6 tests) — +15% coverage improvement
8. book_search_result.dart (3-4 tests) — +10% coverage improvement
9. app_config.dart (1 test) — +25% coverage improvement
10. **Subtotal: 16-27 tests, +85% total line coverage improvement**

### Total Impact
- **Current:** 59.6% (388/651 lines)
- **Phase 6.2:** +185 lines → 65-68% (573/651)
- **Phase 6.3:** +85 lines → 75-80% (658/651+)
- **New Tests:** 38-57 tests total
- **Target Achieved:** 75-80% ✓

---

## Implementation Strategy

### Phase 6.2 (Critical Repositories)
1. Create comprehensive mock for Supabase responses
2. Test each repository method (fetch, add, remove, update)
3. Test error scenarios (network, auth, validation)
4. Test edge cases (empty, large datasets, race conditions)

### Phase 6.3 (Feature Screens)
1. Analyze screen widgets and state management
2. Mock dependencies (repositories, services)
3. Test display states (loading, error, empty, success)
4. Test user interactions (taps, form input)
5. Test navigation flows

### Testing Patterns to Use
- **Unit tests:** Repository methods, models
- **Widget tests:** Screens, forms, error displays
- **Integration tests:** End-to-end flows (already exist)

---

## Coverage Gap Elimination Plan

### Uncovered Lines Analysis

**bookshelf_repository.dart (28 uncovered):**
- ~10 lines in fetchShelf() implementation
- ~6 lines in addBook() implementation
- ~5 lines in removeBook() implementation
- ~4 lines in setReadStatus() implementation
- ~3 lines error handling

**auth_repository.dart (16 uncovered):**
- ~5 lines in signIn() implementation
- ~5 lines in signUp() implementation
- ~3 lines in signOut() implementation
- ~3 lines error handling

**google_books_service.dart (28 uncovered):**
- ~15 lines in search() implementation
- ~8 lines in response parsing
- ~5 lines error handling

*Total uncovered lines to close: ~76 lines*

**Tests to write for closure:**
- 22-30 critical tests (Phase 6.2)
- 16-27 medium-priority tests (Phase 6.3)
- **Total: 38-57 tests**

---

## Success Metrics

| Metric | Current | Target | Method |
|--------|---------|--------|--------|
| Coverage | 59.6% | 75-80% | Write 38-57 tests |
| Critical Paths | ~70% | 100% | Phase 6.2 focus |
| Important Features | ~50% | 85%+ | Phase 6.3 focus |
| Test Count | 151 | 189-208 | +38-57 tests |

---

## Next Steps

### Immediate (Next 2 hours)
1. ✅ Complete gap analysis (THIS DOCUMENT)
2. Review coverage data with focus on critical repositories
3. Create detailed test cases for each gap

### Phase 6.2 (8 hours)
1. Implement 22-30 critical tests
   - bookshelf_repository: 8-10 tests
   - auth_repository: 8-12 tests
   - google_books_service: 6-8 tests
2. Verify coverage improves to 65-68%

### Phase 6.3 (6 hours)
1. Implement 16-27 medium-priority tests
2. Verify coverage reaches 75-80%

---

## Related Documents

- **Phase 6 Plan:** [[PHASE-6-PLAN]]
- **Phase 5 Complete:** [[phase-5-6-1-final]]
- **Phase 5 Pending:** [[PHASE-5-PENDING-EDGE-CASES]]
- **Testing Framework:** [[testing-framework]]

---

**Document Created:** 2026-07-29  
**Next Phase:** Phase 6.2 - Critical Coverage Implementation  
**Estimated Completion:** 2026-07-31

