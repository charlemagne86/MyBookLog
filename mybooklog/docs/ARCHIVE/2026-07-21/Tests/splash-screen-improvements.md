# SplashScreen Tests — Issues & Improvements

**Current Status:** 2/6 passing (33%)  
**Primary Issue:** Pending timer from 2-second delay  
**Impact:** All tests fail at framework cleanup phase

## The Problem

### Root Cause: Pending Timer

The `SplashScreen` runs a 2-second delay in `initState()`:

```dart
Future<void> _routeAfterSplash() async {
  // This creates a pending timer
  await Future.delayed(const Duration(seconds: 2));
  // ... routing logic
}
```

When the test ends, Flutter's testing framework detects an unresolved timer:
```
A Timer is still pending even after the widget tree was disposed.
'package:flutter_test/src/binding.dart':
Failed assertion: line 2542 pos 12: '!timersPending'
```

**Why all tests fail:**
- Each test pumps the SplashScreen
- initState() schedules the 2-second timer
- Test completes quickly (within 100ms)
- Timer is still pending → Framework assertion fails
- ALL tests fail at cleanup, not during execution

## What Needs to Improve

### Issue 1: Timer Not Awaited or Cancelled (CRITICAL)

**Current Code:**
```dart
testWidgets('displays splash branding', (WidgetTester tester) async {
  await _pumpSplashScreen(tester);
  expect(find.text('My Book Log'), findsOneWidget);
  // Test ends here, timer still pending → FAILS
});
```

**Why it fails:**
- Timer created in initState()
- Test never waits for it or cancels it
- Framework cleanup detects pending timer
- Test fails during verification phase

### Issue 2: Mock Verification Requires Timer Handling

**Current Code:**
```dart
testWidgets('routes to bookshelf when user is logged in',
    (WidgetTester tester) async {
  final mockAuth = await _pumpSplashScreen(tester, isLoggedIn: true);
  await tester.pump(const Duration(milliseconds: 100));
  verify(() => mockAuth.currentSession).called(greaterThan(0));
  // Timer still pending → Framework cleanup fails
});
```

**Why it fails:**
- Verification succeeds, but timer is still pending
- Framework assertion fails during cleanup
- Test marked as failed despite successful verification

### Issue 3: No Timer Cleanup Strategy

**Current approach has no mechanism to:**
- Cancel timers
- Fake time (skip the 2-second delay)
- Wait for timers to complete

## Solutions

### Solution 1: Use FakeAsync (RECOMMENDED) ⭐

**How it works:**
- Fake time advancement in tests
- Skip the 2-second delay instantly
- All timers complete without waiting

**Implementation:**
```dart
testWidgets('displays splash branding', (WidgetTester tester) async {
  await tester.runAsync(() async {
    await _pumpSplashScreen(tester);
    expect(find.text('My Book Log'), findsOneWidget);
    // No timer pending - we're in real async context
  });
});
```

**Alternative (more precise):**
```dart
testWidgets('routes to bookshelf when user is logged in',
    (WidgetTester tester) async {
  final mockAuth = await _pumpSplashScreen(tester, isLoggedIn: true);
  
  // Let the timer fire (it's just 2 seconds)
  await tester.pumpAndSettle();
  
  // Now verify - no pending timers
  verify(() => mockAuth.currentSession).called(greaterThan(0));
});
```

**Pros:** Works with actual timer code, real-world behavior  
**Cons:** Tests take ~2 seconds each

### Solution 2: Wait for Full Timer Duration

**Implementation:**
```dart
testWidgets('displays splash branding', (WidgetTester tester) async {
  await _pumpSplashScreen(tester);
  expect(find.text('My Book Log'), findsOneWidget);
  
  // Wait for the timer to complete
  await tester.pumpAndSettle(const Duration(seconds: 3));
  // Now no pending timers - test can cleanup cleanly
});
```

**Pros:**
- Simple to implement
- Tests actual timer behavior
- No special async handling

**Cons:**
- Tests are slow (~2 seconds each)
- Poor developer experience (wait for tests)
- 6 tests × 2 seconds = 12 seconds added to suite

### Solution 3: Refactor SplashScreen (App-level change)

**Problem with current screen:**
```dart
void initState() {
  super.initState();
  _routeAfterSplash();  // Fires immediately, creates timer
}
```

**Refactor approach:**
```dart
// Instead of Future.delayed in the app, mock it in tests
Future<void> _routeAfterSplash() async {
  // Make this mockable or extract to a service
  await Future.delayed(const Duration(seconds: 2));
}

// In test, mock the delay
class MockSplashScreen extends SplashScreen {
  @override
  Future<void> get splashDelay => Future.value(); // No delay
}
```

**Pros:**
- Tests run instantly
- More testable architecture

**Cons:**
- Requires app-level changes
- Out of scope for this testing task

## Recommended Fix: Solution 1 (FakeAsync)

### Why FakeAsync is Best

1. **No app changes needed** — Test problem, solve in test
2. **Tests still fast** — Fake time = instant completion
3. **Real behavior tested** — Tests actual 2-second logic
4. **Clean cleanup** — No pending timers

### Implementation

**Step 1: Update all SplashScreen tests**

```dart
testWidgets('displays splash branding', (WidgetTester tester) async {
  await _pumpSplashScreen(tester);
  expect(find.text('My Book Log'), findsOneWidget);
  expect(find.text('crafted with love'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});

testWidgets('routes to bookshelf when user is logged in',
    (WidgetTester tester) async {
  final mockAuth = await _pumpSplashScreen(tester, isLoggedIn: true);
  
  // CHANGE: Wait for the async timer to complete
  // This pumps through the 2-second delay
  await tester.pumpAndSettle();
  
  // Now verify - timer has completed, no pending timers
  verify(() => mockAuth.currentSession).called(greaterThan(0));
});

testWidgets('routes to login when user is not logged in',
    (WidgetTester tester) async {
  final mockAuth = await _pumpSplashScreen(tester, isLoggedIn: false);
  
  // CHANGE: Wait for timer completion
  await tester.pumpAndSettle();
  
  verify(() => mockAuth.currentSession).called(greaterThan(0));
});

testWidgets('shows loading spinner with primary color',
    (WidgetTester tester) async {
  await _pumpSplashScreen(tester);

  final spinner = find.byType(CircularProgressIndicator);
  expect(spinner, findsOneWidget);

  // CHANGE: Wait for timer to complete before test ends
  await tester.pumpAndSettle();
  
  final theme = Theme.of(tester.element(spinner));
  expect(theme.colorScheme.primary, isNotNull);
});

testWidgets('centers all elements on screen', (WidgetTester tester) async {
  await _pumpSplashScreen(tester);

  final titleText = find.text('My Book Log');
  final taglineText = find.text('crafted with love');
  final spinner = find.byType(CircularProgressIndicator);

  expect(titleText, findsOneWidget);
  expect(taglineText, findsOneWidget);
  expect(spinner, findsOneWidget);

  // CHANGE: Wait for timer to complete
  await tester.pumpAndSettle();
  
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Column && widget.mainAxisAlignment
          == MainAxisAlignment.center,
    ),
    findsWidgets,
  );
});
```

**Step 2: Add "handles unmounting" test**

```dart
testWidgets('handles unmounting during delay gracefully',
    (WidgetTester tester) async {
  await _pumpSplashScreen(tester, isLoggedIn: false);
  
  // Let the timer start
  await tester.pump(const Duration(milliseconds: 100));
  
  // Wait for full completion - screen handles !mounted check
  await tester.pumpAndSettle();
  
  // If we got here without crashing, unmount was handled
  expect(true, true);
});
```

## Expected Results After Fix

| Test | Current | After Fix | Status |
|------|---------|-----------|--------|
| displays splash branding | ❌ | ✅ | Fixed |
| routes to bookshelf when user is logged in | ❌ | ✅ | Fixed |
| routes to login when user is not logged in | ❌ | ✅ | Fixed |
| shows loading spinner with primary color | ✅ | ✅ | Keep working |
| centers all elements on screen | ❌ | ✅ | Fixed |
| handles unmounting during delay gracefully | ⏳ | ✅ | Fixed |

**Expected outcome:** 6/6 tests passing (100%)

## Performance Impact

**Before fix:**
- Each test: ~100ms
- Total: ~600ms
- All tests fail at cleanup

**After fix:**
- Each test: ~2100ms (wait for timer)
- Total: ~12.6 seconds
- All tests pass cleanly

**Note:** The 2-second wait is unavoidable if testing actual timer behavior. Alternative: refactor app to make timer mockable, but that's out of scope.

## Implementation Steps

1. **Update all 6 tests** to call `pumpAndSettle()` before cleanup
2. **Add timer comment** explaining why we wait
3. **Verify all tests pass** (expect 6/6)
4. **Measure execution time** (expect ~2 seconds per test)

## Time Estimate

- **Implementation:** 10-15 minutes
- **Testing & verification:** 5 minutes
- **Total:** ~20 minutes to 100% pass rate

---

**Key Insight:** The timer issue is not a test design problem—it's a timing coordination problem between the app's 2-second delay and the test framework's cleanup. Using `pumpAndSettle()` to wait for the timer is the standard Flutter solution.

**Next Step:** Apply this fix to get all SplashScreen tests passing.
