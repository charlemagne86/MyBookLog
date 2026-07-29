---
name: phase-7-plan
description: Phase 7 - E2E & Integration Testing Expansion (75-80% coverage target)
metadata:
  type: project
---

# Phase 7 — E2E & Integration Testing Expansion

**Phase Status:** Starting  
**Baseline Coverage:** 66.7% (223 tests)  
**Target Coverage:** 75-80%  
**Estimated Duration:** 2-3 days  
**Start Date:** 2026-07-29  

---

## Executive Summary

Phase 7 focuses on closing the coverage gap through integration tests and comprehensive widget testing with proper infrastructure. The goal is to reach production-grade coverage (75-80%) by thoroughly testing critical paths that require full app context.

**Key Objectives:**
1. Integration tests for repositories (Supabase operations)
2. Widget tests with complete dependency injection
3. Complete Phase 5 edge-case tests (4 remaining)
4. Achieve 75-80% coverage target
5. Document advanced testing patterns

---

## Phase Breakdown

### Phase 7.1 — Repository Integration Tests (10 hours)
**Goal:** Test repository layer with Supabase mock patterns

#### BookshelfRepository (Currently 6.7%, Target: 80%+)

**Tests to Add (10-12 tests):**
1. fetchShelf() with various data scenarios
   - Empty shelf
   - Shelf with 1-100 items
   - Malformed response handling
   - Network error handling

2. addBook() operations (3 tests)
   - Successful add
   - Duplicate detection
   - Error scenarios

3. removeBook() operations (2 tests)
   - Successful removal
   - Error handling

4. setReadStatus() operations (2 tests)
   - Mark as read/unread
   - Error handling

**Implementation Approach:**
- Create `test/integration/repositories/bookshelf_repository_integration_test.dart`
- Mock Supabase responses comprehensively
- Test actual query patterns
- Verify error handling

#### AuthRepository (Currently 15.8%, Target: 80%+)

**Tests to Add (8-10 tests):**
1. signIn() scenarios (3 tests)
   - Successful login
   - Invalid credentials
   - Network errors

2. signUp() scenarios (3 tests)
   - Successful signup
   - Email exists
   - Network errors

3. signOut() (1 test)
   - Successful logout

4. Session management (2 tests)
   - Session retrieval
   - Auth state changes

**Implementation Approach:**
- Create `test/integration/repositories/auth_repository_integration_test.dart`
- Mock Supabase auth client
- Test actual sign-in/up flows
- Verify session handling

**Total Tests:** 18-22 new integration tests
**Estimated Coverage Gain:** +8-10%

---

### Phase 7.2 — Widget Tests with Full Infrastructure (10 hours)
**Goal:** Test screens with complete app context

#### BookshelfScreen (Currently 54.5%, Target: 80%+)

**Tests to Add (8-10 tests):**
1. Display scenarios
   - Loading state display
   - Empty shelf display
   - Shelf with books display

2. User interactions
   - Search/filter functionality
   - Logout button
   - Add book navigation

3. Error handling
   - Network error display
   - Error recovery

4. Navigation
   - Navigate to book details
   - Navigate to add book

**Implementation Approach:**
- Create `test/widget/screens/bookshelf_screen_integration_test.dart`
- Full dependency injection (repositories, services)
- Test with GoRouter navigation
- Mock all backend services

#### SignupScreen (Currently 56.0%, Target: 80%+)

**Tests to Add (6-8 tests):**
1. Form validation
   - Valid input acceptance
   - Invalid input rejection
   - Password matching

2. Submission scenarios
   - Successful signup
   - Email exists error
   - Network error

3. Navigation
   - Redirect after signup
   - Error recovery

**Implementation Approach:**
- Create `test/widget/screens/signup_screen_integration_test.dart`
- Complete form testing
- Navigation verification
- Error handling

#### SplashScreen (Currently 4.3%, Target: 50%+)

**Tests to Add (4-5 tests):**
1. Initialization
   - Session check on startup
   - Auth state evaluation
   - Loading display

2. Navigation
   - Navigate to login when not authenticated
   - Navigate to bookshelf when authenticated
   - Handle session check errors

**Implementation Approach:**
- Create `test/widget/screens/splash_screen_integration_test.dart`
- Mock auth repository
- Test routing logic
- Verify loading states

**Total Tests:** 18-23 new widget tests
**Estimated Coverage Gain:** +8-10%

---

### Phase 7.3 — Edge Case Completion (5 hours)
**Goal:** Complete Phase 5 pending edge-case tests

**4 Remaining Tests:**
1. BookshelfScreen - shows error message on shelf load failure
2. LoginScreen - form scrolls on small screens
3. LoginScreen - handles rapid login button taps (prevents double submission)
4. LoginScreen - shows error message on network failure

**Approach:**
- Fix with proper widget test infrastructure from Phase 7.2
- Use complete dependency injection
- Resolve async timing issues
- Verify edge case handling

**Estimated Coverage Gain:** +1-2%

---

### Phase 7.4 — Cross-Feature Integration (5 hours)
**Goal:** Test complete user journeys

**End-to-End Scenarios (4-5 tests):**

1. **Complete Auth Flow**
   - Signup → Login → Bookshelf
   - Verify state transitions
   - Test navigation chain

2. **Search to Add Book**
   - Search for book
   - Display results
   - Add to shelf
   - Verify shelf updated

3. **Session Persistence**
   - Login
   - Close app
   - Reopen app
   - Verify still logged in

4. **Error Recovery**
   - Network error during search
   - Retry search
   - Verify recovery

5. **Concurrent Operations** (if time)
   - Multiple operations simultaneously
   - Verify data consistency

**Estimated Coverage Gain:** +2-3%

---

### Phase 7.5 — Documentation & Finalization (3 hours)
**Goal:** Document Phase 7 work and closure

**Deliverables:**
- Phase 7 completion summary
- Integration testing patterns guide
- Widget testing with full context guide
- Coverage metrics report
- Path to 85-90% coverage (Phase 8)

**Estimated Coverage Gain:** N/A (documentation)

---

## Coverage Goal Breakdown

**Current:** 66.7% (434/651 lines)  
**Target:** 75-80%  
**Lines to Cover:** 23-57 additional lines

### By Phase 7 Subphase

| Phase | Focus | Tests | Coverage Gain | Target |
|-------|-------|-------|---------------|--------|
| 7.1 | Repository integration | 18-22 | +8-10% | 74-76% |
| 7.2 | Widget with full context | 18-23 | +8-10% | 75-80% |
| 7.3 | Phase 5 edge cases | 4 | +1-2% | 76-82% |
| 7.4 | Cross-feature E2E | 4-5 | +2-3% | 78-85% |
| **Total** | **44-54 tests** | **+20-25%** | **86-91%** |

**Note:** Target is 75-80%, but implementing all subphases will likely reach 80-85%

---

## Testing Patterns to Establish

### 1. Repository Integration Testing

**Pattern:**
```dart
// Mock Supabase client completely
when(() => mockClient.from('table')).thenReturn(mockQuery);
when(() => mockQuery.select()).thenReturn(mockBuilder);
when(() => mockBuilder.eq()).thenReturn(mockBuilder);
when(() => mockBuilder.eq()).thenAnswer((_) async => mockData);

// Test actual repository methods
final result = await repository.fetchShelf();

// Verify data transformation
expect(result, isNotEmpty);
expect(result[0].title, equals('Expected'));
```

### 2. Widget Testing with Full Context

**Pattern:**
```dart
// Create test app with full dependency injection
testWidgets('feature works with full context', (tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<Repository>.value(value: mockRepo),
        Provider<Service>.value(value: mockService),
        // ... complete dependency tree
      ],
      child: MaterialApp(
        router: GoRouter(routes: [...]),
        // Full app setup
      ),
    ),
  );

  // Test interactions
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // Verify results
  expect(find.byType(SuccessWidget), findsOneWidget);
});
```

### 3. E2E User Journey Testing

**Pattern:**
```dart
// Test complete flow from start to finish
testWidgets('user can signup and add book', (tester) async {
  // 1. Launch app
  await tester.pumpWidget(createTestApp());

  // 2. Navigate through signup
  await tester.enterText(find.byType(TextField), 'email@example.com');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();

  // 3. Verify state change
  expect(find.byType(BookshelfScreen), findsOneWidget);

  // 4. Verify persistence
  // Continue testing next flow
});
```

---

## File Structure

```
test/
├── integration/                          # NEW
│   └── repositories/
│       ├── auth_repository_integration_test.dart
│       └── bookshelf_repository_integration_test.dart
│
└── widget/
    └── screens/
        ├── bookshelf_screen_integration_test.dart    # NEW
        ├── signup_screen_integration_test.dart       # NEW
        ├── splash_screen_integration_test.dart       # NEW
        ├── bookshelf_screen_edge_cases_test.dart     # COMPLETE
        ├── login_screen_edge_cases_test.dart         # COMPLETE
        └── ...existing tests
```

---

## Success Criteria

### Coverage Targets

| Target | Current | Phase 7 | Success |
|--------|---------|---------|---------|
| Overall | 66.7% | 75-80% | ✅ +8-13% |
| bookshelf_repo | 6.7% | 80%+ | ✅ +73%+ |
| auth_repo | 15.8% | 80%+ | ✅ +64%+ |
| bookshelf_screen | 54.5% | 80%+ | ✅ +25%+ |
| signup_screen | 56.0% | 80%+ | ✅ +24%+ |
| splash_screen | 4.3% | 50%+ | ✅ +45%+ |

### Test Metrics

| Metric | Target |
|--------|--------|
| New Tests | 44-54 |
| Pass Rate | >97% |
| Compilation Errors | 0 |
| Files at 80%+ | 12+ |

### Quality

| Aspect | Target |
|--------|--------|
| Documentation | Comprehensive patterns guide |
| Code Quality | Production-ready |
| Regression Detection | Enabled (from Phase 6) |

---

## Risk Assessment

| Risk | Probability | Mitigation |
|------|-------------|-----------|
| Supabase mocking complexity | Medium | Use established patterns, incremental testing |
| Widget test infrastructure | Low | Full DI learned from Phase 6.4 |
| Async/timing issues | Low | Proper Completer usage from Phase 5 |
| Time overrun | Medium | Focus on coverage-critical tests first |

---

## Optimization Opportunities

### If Behind Schedule

1. **Focus on high-impact tests first**
   - bookshelf_repo integration (10 tests)
   - auth_repo integration (8 tests)
   - Reach 75% with ~18 tests

2. **Defer lower-priority tests**
   - Cross-feature E2E (lower coverage gain)
   - Some widget edge cases

3. **Parallel implementation**
   - Phase 7.1 and 7.2 can run in parallel
   - Different files = no merge conflicts

### If Ahead of Schedule

1. **Implement Phase 7.4 comprehensively**
   - 5+ E2E scenarios
   - Complex user journeys
   - Performance testing

2. **Add load testing**
   - Large dataset handling
   - Concurrent operations
   - Performance baselines

3. **Begin Phase 8 planning**
   - Performance optimization
   - Advanced caching
   - Parallelization setup

---

## Phase 7 vs Phase 8

### Phase 7 (This Phase) — Testing Expansion
- Focus: Coverage to 75-80%
- Methods: Integration + Widget tests
- Scope: All critical paths tested
- Duration: 2-3 days

### Phase 8 (Next Phase) — Performance & Optimization
- Focus: Coverage to 85-90% + Optimization
- Methods: Advanced testing + Profiling
- Scope: Edge cases + Performance optimization
- Duration: 2-3 days

### Phase 9 (Later Phase) — Security & Deployment
- Focus: Production readiness
- Methods: Security testing
- Scope: Security audit + Deployment automation
- Duration: 1-2 days

---

## Dependencies & Prerequisites

### From Phase 6

✅ **Available:**
- GitHub Actions CI/CD
- Codecov integration
- Performance baselines
- Development documentation

✅ **Can Build On:**
- Test infrastructure patterns
- Mock setup patterns
- Performance monitoring

### New Requirements

📋 **Need to Establish:**
- Supabase integration test patterns
- Full dependency injection in tests
- GoRouter testing patterns
- Async/timing best practices

---

## Success Metrics Summary

| Area | Success Criteria |
|------|-----------------|
| Coverage | 75-80% achieved |
| Tests Added | 44-54 new tests |
| Pass Rate | >97% maintained |
| Quality | 0 compilation errors |
| Documentation | Comprehensive patterns |
| Time | 2-3 days (schedule) |

---

## Recommendation

**Proceed with Phase 7** to reach production-grade coverage (75-80%). The infrastructure from Phases 6 and prior phases provides solid foundation for integration and widget testing.

**Priority order:**
1. Phase 7.1 - Repository integration (highest ROI for coverage)
2. Phase 7.2 - Widget with full context
3. Phase 7.3 - Edge case completion
4. Phase 7.4 - E2E if time permits

---

**Phase 7 Plan Status:** ✅ READY TO START  
**Estimated Duration:** 2-3 days  
**Target Coverage:** 75-80%  
**Recommendation:** PROCEED

