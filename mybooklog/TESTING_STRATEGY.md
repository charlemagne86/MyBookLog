# MyBookLog — Comprehensive Testing & Performance Framework

**Purpose:** Achieve 100% code coverage with regression prevention and continuous performance benchmarking.  
**Date Created:** 2026-07-20

---

## Testing Strategy Overview

### Testing Pyramid

```
                 🔺
              E2E Tests (5%)
           - Full app flows
         - Supabase integration
        ___________________
             Widget Tests (25%)
          - Screen interactions
        - Navigation flows
       - State changes
      ________________________
           Unit Tests (70%)
        - Models (parsing, validation)
      - Services (business logic)
     - Repositories (Supabase queries)
    - Utils (helpers, formatting)
   ____________________________
```

### Coverage Goals by Layer

| Layer | Target | Type | Files |
|-------|--------|------|-------|
| **Models** | 100% | Unit | `data/models/*.dart` |
| **Services** | 100% | Unit + Mock | `data/services/*.dart` |
| **Repositories** | 100% | Unit + Mock | `data/repositories/*.dart` |
| **Utils** | 100% | Unit | `core/utils.dart` |
| **Screens** | 90%+ | Widget | `features/*/` |
| **Routing** | 85%+ | Widget + E2E | `core/router/` |
| **Theme** | 80%+ | Widget | `core/theme/` |

---

## Test File Organization

```
test/
├── unit/
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config_test.dart
│   │   ├── utils/
│   │   │   └── utils_test.dart
│   │   ├── theme/
│   │   │   └── app_theme_test.dart
│   │   └── router/
│   │       └── app_router_test.dart
│   └── data/
│       ├── models/
│       │   ├── book_search_result_test.dart
│       │   └── shelf_book_test.dart
│       ├── services/
│       │   ├── google_books_service_test.dart
│       │   └── supabase_service_test.dart
│       └── repositories/
│           ├── auth_repository_test.dart
│           └── bookshelf_repository_test.dart
├── widget/
│   ├── auth/
│   │   ├── login_screen_test.dart
│   │   ├── signup_screen_test.dart
│   │   └── splash_screen_test.dart
│   ├── bookshelf/
│   │   ├── bookshelf_screen_test.dart
│   │   └── widgets/
│   │       └── book_on_shelf_test.dart
│   └── book_search/
│       ├── search_results_page_test.dart
│       └── add_book_page_test.dart
├── integration/
│   ├── auth_flow_test.dart
│   ├── add_book_flow_test.dart
│   ├── shelf_management_test.dart
│   └── search_integration_test.dart
├── performance/
│   ├── benchmarks/
│   │   ├── shelf_fetch_benchmark.dart
│   │   ├── search_benchmark.dart
│   │   └── widget_build_benchmark.dart
│   └── golden/
│       └── (golden files for visual regression)
├── fixtures/
│   ├── mock_supabase_client.dart
│   ├── mock_router.dart
│   ├── test_data.dart
│   └── test_helpers.dart
└── widget_test.dart (existing, to be refactored)
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
- [x] Test file structure created
- [ ] Mock/fixture infrastructure
- [ ] Unit tests for models
- [ ] Unit tests for utils & services
- [ ] Coverage tracking setup

### Phase 2: Repositories & State (Week 2)
- [ ] Repository unit tests (mocked Supabase)
- [ ] Auth flow tests
- [ ] Provider state management tests
- [ ] Coverage: 60%+

### Phase 3: Widget Tests (Week 3)
- [ ] Screen widget tests
- [ ] Navigation tests
- [ ] User interaction flows
- [ ] Coverage: 80%+

### Phase 4: Integration & Performance (Week 4)
- [ ] Integration tests (with real Supabase test DB)
- [ ] Performance benchmarks
- [ ] Golden file tests
- [ ] Coverage: 100%

### Phase 5: CI/CD & Automation (Ongoing)
- [ ] GitHub Actions workflow
- [ ] Coverage enforcement (no PRs below threshold)
- [ ] Performance regression detection
- [ ] Automated reporting

---

## Key Testing Patterns

### 1. Mocking Strategy

**Supabase Client Mock:**
```dart
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockAuthClient extends Mock implements GotrueClient {}
class MockRealtimeClient extends Mock implements RealtimeClient {}
```

**Router Mock:**
```dart
class MockGoRouter extends Mock implements GoRouter {}
```

**Provider Setup:**
```dart
ProviderContainer testProviderContainer({
  SupabaseClient? supabaseClient,
  // ... other mocks
}) {
  return ProviderContainer(
    overrides: [
      supabaseClientProvider.overrideWithValue(
        supabaseClient ?? MockSupabaseClient(),
      ),
    ],
  );
}
```

### 2. Test Data Factories

```dart
// Reusable test fixtures
class TestData {
  static ShelfBook sampleBook() => ShelfBook(...);
  static BookSearchResult sampleSearchResult() => BookSearchResult(...);
  static User sampleUser() => User(...);
}
```

### 3. Widget Testing Pattern

```dart
Future<void> pumpApp(WidgetTester tester, {required Widget home}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: home,
      // mocked router, theme, etc.
    ),
  );
}
```

---

## Coverage Configuration

### setup.cfg (for coverage tool)

```ini
[coverage:run]
branch = True
omit =
    */test/*
    */main.dart
    **/*.g.dart
    **/*.freezed.dart

[coverage:report]
precision = 2
show_missing = True
skip_covered = False
```

### Command to Run Coverage

```bash
flutter test --coverage --no-pub
lcov --list coverage/lcov.info
```

### Enforce in CI

- Fail PR if coverage drops below 85%
- Fail PR if new code has <95% coverage
- Generate HTML coverage report

---

## Performance Benchmarking

### 1. Benchmark Metrics

| Metric | Target | Tool |
|--------|--------|------|
| **Shelf fetch time** | <500ms | Benchmark test |
| **Search query latency** | <1000ms | Benchmark test |
| **Widget build time** | <100ms | FrameTimings |
| **Memory footprint** | <150MB | Devtools |
| **Jank detection** | 0 missed frames | Performance overlay |

### 2. Benchmark Test Structure

```dart
Future<void> benchmarkShelfFetch() async {
  final sw = Stopwatch()..start();
  // Test code
  sw.stop();
  
  print('Shelf fetch: ${sw.elapsedMilliseconds}ms');
  expect(sw.elapsedMilliseconds, lessThan(500));
}
```

### 3. Performance Regression Detection

- Store baseline metrics in Git
- CI compares new metrics to baseline
- Alert if regression >10%
- Generate performance report per PR

---

## CI/CD Integration (GitHub Actions)

### Workflow: `tests.yml`

```yaml
name: Tests & Coverage

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run tests with coverage
        run: flutter test --coverage --no-pub
      
      - name: Check coverage
        run: |
          lcov --list coverage/lcov.info
          bash scripts/check_coverage.sh 85
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
      
      - name: Run performance benchmarks
        run: flutter test test/performance/benchmarks/
      
      - name: Analyze
        run: flutter analyze
      
      - name: Format check
        run: dart format --set-exit-if-changed .
```

### Coverage Check Script: `scripts/check_coverage.sh`

```bash
#!/bin/bash
THRESHOLD=$1
COVERAGE=$(lcov --list coverage/lcov.info | grep "TOTAL" | awk '{print $2}' | sed 's/%//')
if (( $(echo "$COVERAGE < $THRESHOLD" | bc -l) )); then
  echo "❌ Coverage ${COVERAGE}% is below threshold ${THRESHOLD}%"
  exit 1
fi
echo "✅ Coverage ${COVERAGE}% meets threshold ${THRESHOLD}%"
```

---

## Regression Prevention Checklist

- [ ] All tests pass before merge
- [ ] Coverage maintained (no decrease)
- [ ] No performance regressions (>10%)
- [ ] All lint checks pass
- [ ] Snapshot/golden files updated
- [ ] Accessibility checks pass
- [ ] No debug prints left in code
- [ ] CHANGELOG updated

---

## Tools & Dependencies

### Current (already in pubspec.yaml)
- `flutter_test` — Widget & unit testing
- `provider` — State management
- `go_router` — Navigation

### To Add

```yaml
dev_dependencies:
  # Testing
  mocktail: ^1.4.0              # Mocking
  
  # Coverage
  coverage: ^7.2.0              # Coverage reporting
  
  # Performance
  benchmark_harness: ^5.0.0     # Benchmarking
  
  # Golden files / Snapshots
  golden_toolkit: ^0.13.0       # Visual testing
  
  # Code generation
  build_runner: ^2.4.0          # Test data factories
  
  # Flutter testing helpers
  integration_test:             # Integration tests
    sdk: flutter
```

### Coverage Tools
- `lcov` — Terminal reporting: `brew install lcov`
- `codecov` — Cloud reporting (CI integration)

---

## Running Tests Locally

```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test test/integration/

# Performance benchmarks
flutter test test/performance/benchmarks/

# Single test file
flutter test test/unit/data/models/shelf_book_test.dart

# Watch mode (re-run on changes)
flutter test --watch
```

---

## Metrics Dashboard

Generate periodic reports showing:
- Overall coverage trend
- Per-file coverage breakdown
- Test execution time trend
- Performance benchmark results
- Flaky test detection

Tools: GitHub Actions artifacts + Codecov dashboard

---

## Maintenance

- **Weekly:** Review flaky tests, fix or skip with reason
- **Per-PR:** Ensure tests added for new features
- **Monthly:** Review coverage gaps, create issues for low-coverage areas
- **Quarterly:** Analyze performance trends, optimize hot paths

---

## Related Documentation

- [[Feature-Enhancement-Roadmap]] — Features to test
- [[Remediation-Index]] — Security/correctness regression tests
- CODE_VERIFICATION_REPORT — Baseline for regression detection
