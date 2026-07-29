---
name: phase-7-progress-update
description: Phase 7 - Strategic Pivot & Pragmatic Path Forward
metadata:
  type: project
---

# Phase 7 — Progress Update & Strategic Pivot

**Date:** 2026-07-27  
**Status:** Evaluating optimal path  
**Current Coverage:** 66.7% (223 tests)  
**Target:** 75-80%  

---

## Assessment Summary

### What Was Attempted

Phase 7.1 (Repository Integration Tests) was initiated with the goal of creating comprehensive Supabase integration tests for `BookshelfRepository` and `AuthRepository`.

**File Started:** `test/integration/repositories/bookshelf_repository_integration_test.dart`

**Approach:** Mock Supabase SDK's PostgrestFilterBuilder and query patterns

**Outcome:** ❌ Encountered complexity with Supabase SDK's builder pattern (generic types, chained methods)

### Why It's Complex

The Supabase Flutter SDK uses sophisticated builder patterns designed for production use, not test mocking:

```dart
// What the SDK does:
final result = await client
  .from('table')           // Returns PostgrestFilterBuilder<T>
  .select()                // Returns PostgrestFilterBuilder<T>
  .eq('user_id', id)       // Returns PostgrestFilterBuilder<T>
  .maybeSingle();          // Returns Future<Map>

// What mocking requires:
// - Mock PostgrestFilterBuilder with correct type parameters
// - Support all chaining patterns
// - Handle both sync (chaining) and async (execution) calls
// - Maintain type safety throughout
```

This is technically possible but requires extensive infrastructure that doesn't scale well to multiple test files.

---

## Strategic Decision: Pragmatic Pivot

Based on Phase 6's pragmatic success (focusing on high-ROI service layer instead of struggling with Supabase complexity), **we recommend pivoting to Widget Tests with Full DI** for Phase 7.

### Why This Makes Sense

**Phase 6 Lessons Learned:**
- ✅ Service layer (GoogleBooksService): Simple HTTP mocking = 30 tests in 2 hours
- ✅ Model layer (BookSearchResult): Pure functions = 42 tests in 1 hour
- ❌ Supabase SDK mocking: Complex patterns = struggling after 1 hour

**Phase 7 Opportunity:**
- Widget tests with complete app context
- Already proven patterns from Phase 6
- Clear path to 75-80% coverage
- Realistic timeline (2-3 hours vs 4+ hours struggling)

---

## Recommended Path Forward

### OPTION A: Widget Tests with Full DI (RECOMMENDED) ⭐

**Focus:** BookshelfScreen, SignupScreen, SplashScreen widget tests

**Implementation:**
1. Create test helpers for complete app context
2. Mock repositories (not Supabase internals)
3. Test user flows end-to-end
4. Achieve 80%+ coverage on screens

**Coverage Gain:** +8-10%  
**Time Required:** 3-4 hours  
**Success Probability:** Very High (proven pattern)

**Files to Create:**
- `test/widget/screens/bookshelf_screen_integration_test.dart` (8-10 tests)
- `test/widget/screens/signup_screen_integration_test.dart` (6-8 tests)
- `test/widget/screens/splash_screen_integration_test.dart` (4-5 tests)

### OPTION B: Defer Repository Tests to Phase 8 (Alternative)

Keep current Supabase integration testing as Phase 8 work where:
- Supabase local stack can be used
- More time to build proper mocking infrastructure
- Or use integration test approach with real database

**Coverage Gain:** +3-5% (less than Option A)  
**Time Required:** Later phase  
**Risk:** Falls out of current sprint

---

## Coverage Analysis: Both Options

### Current State
```
66.7% (223 tests)
├─ Services: 100% (GoogleBooksService)
├─ Models: 100% (BookSearchResult)
├─ Widgets: 50-90% (Screens need work)
├─ Repositories: 6-16% (Supabase complex)
└─ Utilities: 100% (Utils)
```

### With Option A (Widget Tests)
```
~75-77% achievable
├─ Bookshelf Screen: 6.7% → 80%+
├─ Signup Screen: 56% → 80%+
├─ Splash Screen: 4.3% → 50%+
├─ Plus edge case completion: +1-2%
└─ Repositories deferred to Phase 8
```

### With Option B (Skip Widgets)
```
~70-72% achievable
├─ Repositories: 6-16% → 40% (partial coverage)
├─ Edge cases: +1-2%
└─ Widgets remain untested
```

---

## Technical Comparison

| Aspect | Repository Tests | Widget Tests |
|--------|------------------|--------------|
| **Complexity** | High (SDK internals) | Medium (app context) |
| **Success Probability** | Medium (unproven patterns) | High (Phase 6 proven) |
| **ROI** | +3-5% coverage | +8-10% coverage |
| **Time** | 4+ hours | 3-4 hours |
| **Scalability** | Difficult | Straightforward |
| **Coverage Gap** | Still leaves screens untested | Closes critical gap |

---

## Recommendation

**Proceed with OPTION A: Widget Tests with Full DI**

**Rationale:**
1. Phase 6 validated pragmatic approach: focus on what's testable
2. Clear path to 75-80% coverage target
3. Higher probability of success (proven patterns)
4. Better use of time (3-4 hours vs 4+ hours struggling)
5. Leaves organized technical debt (Phase 8 can tackle Supabase)
6. Achieves primary Phase 7 goal (75-80% coverage)

**Phase 8 Priority:**
- Repository integration testing with proper infrastructure
- Can use Supabase local stack or integration test approach
- More time to solve Supabase mocking elegantly

---

## Immediate Next Steps

### If Approved to Proceed with Option A:

1. **Create test infrastructure** (1 hour)
   - Build helper functions for full app context
   - Mock repositories at boundary
   - Setup GoRouter test configuration

2. **Implement widget tests** (2-3 hours)
   - BookshelfScreen: 8-10 tests
   - SignupScreen: 6-8 tests
   - SplashScreen: 4-5 tests

3. **Complete Phase 5 edge cases** (1 hour)
   - Use new widget test infrastructure
   - Fix 4 remaining failing tests

4. **Documentation** (1 hour)
   - Phase 7 completion summary
   - Widget test patterns guide

**Total: ~5-6 hours → +8-10% coverage → 75-77% achieved**

---

## Technical Details (If Approved)

### Test Infrastructure Pattern

```dart
// test/helpers/test_app_builder.dart
class TestAppBuilder {
  static Widget createApp({
    required MockBookshelfRepository bookshelfRepo,
    required MockAuthRepository authRepo,
    required GoRouter router,
  }) {
    return MultiProvider(
      providers: [
        Provider<BookshelfRepository>.value(value: bookshelfRepo),
        Provider<AuthRepository>.value(value: authRepo),
        // ... other dependencies
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }
}

// Usage in tests
testWidgets('bookshelf loads books', (tester) async {
  final mockRepo = MockBookshelfRepository();
  when(() => mockRepo.fetchShelf()).thenAnswer(
    (_) async => [mockBook1, mockBook2]
  );
  
  await tester.pumpWidget(
    TestAppBuilder.createApp(
      bookshelfRepo: mockRepo,
      authRepo: MockAuthRepository(),
      router: createTestRouter(),
    )
  );
  
  await tester.pumpAndSettle();
  expect(find.byType(BookCard), findsWidgets);
});
```

### Mock Pattern (Leveraging Phase 6)

```dart
class MockBookshelfRepository extends Mock implements BookshelfRepository {}

// Setup in test
final mockRepo = MockBookshelfRepository();
when(() => mockRepo.fetchShelf()).thenAnswer(
  (_) async => [
    BookOnShelf(
      id: 'test-1',
      title: 'Test Book',
      authors: ['Author'],
      ...
    ),
  ]
);
```

---

## Timeline Impact

### Current Phase 7 Plan
- Phase 7.1: Repository tests (deferred to 8)
- Phase 7.2: Widget tests (NOW) ← Focus here
- Phase 7.3: Edge cases (NOW) ← Leverage widget infrastructure
- Phase 7.4: E2E scenarios (optional)

**Revised Timeline:**
- ~5-6 hours for widget tests + edge cases
- Clear path to 75-80% coverage
- Documentation in Phase 7.5

---

## Sign-Off

**Current Phase 7 Status:** Evaluating strategic direction

**Recommendation:** ✅ **PROCEED WITH OPTION A (Widget Tests)**
- Higher success probability
- Better timeline
- Achieves primary goal (75-80% coverage)
- Aligns with Phase 6 pragmatic approach
- Organized technical debt (Phase 8)

**Phase 8 (Future):** Tackle repository integration testing with proper setup

---

**Ready to:** Begin Phase 7.2 widget tests OR discuss alternative approach
**Next Action:** Approval to proceed with widget test infrastructure

---

*Document prepared based on Phase 6 experience and current assessment*
*Recommendation prioritizes project success over technical perfection*
