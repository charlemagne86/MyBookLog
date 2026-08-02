# MyBookLog Testing Framework

![Coverage](https://img.shields.io/badge/coverage-76.1%25-brightgreen)
![Tests](https://img.shields.io/badge/tests-371%20passing-brightgreen)
![Pass Rate](https://img.shields.io/badge/pass%20rate-100%25-brightgreen)

## Overview

MyBookLog has a comprehensive testing framework with 371 tests covering critical functionality. The framework is organized into unit tests, widget tests, and integration tests, with automated CI/CD monitoring via GitHub Actions and Codecov.

**Current Coverage:** 76.1% (target met: 75-80%)  
**Tests Passing:** 371/371 (100%)  
**CI/CD Status:** ✅ Active

## Test Organization

### Unit Tests (150+ tests)

**Models** (`test/unit/models/`)
- ShelfBook model tests (22 tests)
- BookSearchResult model tests (42 tests)
  - Comprehensive edge case coverage
  - 100% code coverage achieved

**Services** (`test/unit/services/`)
- GoogleBooksService tests (30 tests)
  - Search, ISBN extraction, error handling
  - 100% code coverage achieved
  - Timeout and malformed response handling

**Repositories** (`test/unit/repositories/`)
- BookshelfRepository error handling (20+ tests)
- AuthRepository error scenarios (20+ tests)
- Coverage gaps documented for Phase 7

### Widget Tests (40+ tests)

**Screens** (`test/widget/screens/`)
- LoginScreen tests (includes edge cases)
- SplashScreen navigation tests
- BookshelfScreen interaction tests (deferred to Phase 7)
- SignupScreen validation tests (deferred to Phase 7)

### Integration Tests (3+ tests)

**Complete User Flows** (`integration_test/`)
- Authentication flow tests
- Bookshelf operations tests
- Navigation and routing tests
- Performance baseline tests

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Specific Test File
```bash
flutter test test/unit/models/book_search_result_comprehensive_test.dart
```

### Run Widget Tests Only
```bash
flutter test --tags widget
```

### Run Unit Tests Only
```bash
flutter test --tags unit
```

### Generate Coverage Report (HTML)
```bash
# Generate LCOV coverage
flutter test --coverage

# Convert to HTML (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
# or
xdg-open coverage/html/index.html  # Linux
```

## CI/CD Pipeline

### Automated Workflow

**Trigger:** Push to `main`/`develop` or pull requests  
**Runtime:** 5-8 minutes

**Steps:**
1. Code checkout
2. Flutter setup (3.16.0)
3. Dependency installation
4. Code analysis (`flutter analyze`)
5. Format validation (`dart format`)
6. Test execution with coverage
7. Coverage threshold check (minimum 60%)
8. Codecov upload
9. Artifact archival

### Branch Protection

Main branch requires:
- ✅ All GitHub status checks passing
- ✅ 60% minimum code coverage
- ✅ Code review approval
- ✅ Branch up to date with main

### Coverage Requirements

| Level | Threshold | Purpose |
|-------|-----------|---------|
| Project | 60% minimum | Prevent coverage regression |
| New Code (Patch) | 80% target | Encourage comprehensive testing |

## Test Structure & Patterns

### Business Logic Comments

All tests include clear business logic comments:

```dart
testWidgets('shows loading indicator on initial load', (WidgetTester tester) async {
  // TECHNICAL: First load fetches from database
  // Should show spinner until data arrives
  
  // Test implementation...
});
```

### Mock Patterns

**Repository Mocking:**
```dart
class MockBookshelfRepository extends Mock implements BookshelfRepository {}

when(() => mockRepo.fetchShelf()).thenAnswer((_) async => testBooks);
```

**HTTP Client Mocking:**
```dart
class MockHttpClient extends Mock implements http.Client {}

when(() => mockClient.get(any())).thenAnswer(
  (_) async => http.Response('{"items":[]}', 200),
);
```

## Coverage by File

| File | Coverage | Status |
|------|----------|--------|
| google_books_service.dart | 100% | ✅ Complete |
| book_search_result.dart | 100% | ✅ Complete |
| utils.dart | 100% | ✅ Complete |
| login_screen.dart | 98.2% | ✅ Excellent |
| shelf_book.dart | 95.5% | ✅ Excellent |
| book_on_shelf.dart | 85.2% | ✅ Good |
| app_theme.dart | 73.2% | ✅ Good |
| signup_screen.dart | 56.0% | ⏳ Phase 7 |
| bookshelf_screen.dart | 54.5% | ⏳ Phase 7 |
| app_config.dart | 50.0% | - Simple config |
| auth_repository.dart | 15.8% | ⏳ Phase 7 |
| bookshelf_repository.dart | 6.7% | ⏳ Phase 7 |
| splash_screen.dart | 4.3% | ⏳ Phase 7 |
| app_colors.dart | 0.0% | - Constants only |

## Adding New Tests

### Before Writing Tests

1. Identify what you're testing (model, service, widget, integration)
2. Check existing test patterns in that category
3. Use appropriate mocking strategy

### Test Template

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Name - Component', () {
    setUp(() {
      // Initialize test dependencies
    });

    test('describes what it tests', () {
      // TECHNICAL: Explain the technical scenario
      // Expected behavior description
      
      // Arrange
      final testData = ...;
      
      // Act
      final result = ...;
      
      // Assert
      expect(result, isNotNull);
    });
  });
}
```

### Coverage Goals

**When writing tests:**
- Aim for 80%+ coverage on new code
- Include happy path and error cases
- Test edge cases (null, empty, overflow)
- Verify error messages are clear

## Known Coverage Gaps

### Phase 5 Pending (4 edge-case tests)
- LoginScreen: form scrolling on small screens
- LoginScreen: rapid button tap prevention
- LoginScreen: network error display
- BookshelfScreen: error message on load failure

These are deferred to Phase 7 for complex async widget patterns.

### Phase 7 Work Items

**Repositories (Supabase mocking):**
- bookshelf_repository.dart: +75% coverage needed
- auth_repository.dart: +60% coverage needed

**Screens (Widget testing with proper setup):**
- bookshelf_screen.dart: +25% coverage needed
- signup_screen.dart: +25% coverage needed
- splash_screen.dart: +95% coverage needed

**Target:** 75-80% coverage via integration tests + enhanced widget test setup

## Troubleshooting Tests

### Test Hangs / Times Out
- Check for infinite loops in mocks
- Verify `pumpAndSettle()` is called after async operations
- Use `timeout: Duration(seconds: 5)` parameter

### Widget Not Found
- Ensure `pumpAndSettle()` was called after `pumpWidget()`
- Check if widget is inside a conditional that's false
- Verify correct finder (`find.byType()`, `find.byIcon()`, etc.)

### Mock Not Working
- Ensure mock is passed via Provider or directly
- Verify `when().thenAnswer()` uses correct method signature
- Check parameter matching (use `any()` if needed)

### Coverage Not Generated
- Run `flutter test --coverage` (not just `flutter test`)
- Verify `coverage/lcov.info` file was created
- Check that tests actually ran (should see test output)

## Performance Baselines

### Test Execution Time

| Category | Time |
|----------|------|
| Unit tests | ~3-4 min |
| Widget tests | ~2-3 min |
| Integration tests | ~1-2 min |
| Coverage generation | ~30 sec |
| **Total** | **~5-8 min** |

### Recommendations for Faster Testing

1. Run unit tests only for local development: `flutter test test/unit/`
2. Run integration tests separately for CI/CD
3. Use test sharding in CI for parallel execution

## CI/CD Monitoring

### Check Test Status

1. **Locally:** `flutter test --coverage`
2. **On GitHub:**
   - Go to repository → Actions tab
   - View latest workflow run
   - Check "Flutter Tests & Coverage" job

### View Coverage Reports

1. **Codecov:** https://codecov.io/gh/username/MyBookLog
2. **Local:** Generate HTML report with `genhtml`
3. **GitHub:** Codecov comment on each PR

### Monitor Coverage Trends

- Codecov dashboard shows coverage history
- PR comments highlight coverage impact
- Badges in README updated on main branch merges

## Best Practices

### ✅ Do

- Write tests for new features **before** merging
- Include both happy path and error cases
- Use descriptive test names that explain the scenario
- Comment business logic reasons for the test
- Keep tests isolated (no dependencies on test order)
- Mock external dependencies (APIs, databases)

### ❌ Don't

- Skip tests for "just this time" (coverage regression)
- Use `skip: true` without a GitHub issue reference
- Write tests that depend on other tests running first
- Mock internal classes (test through public interface)
- Create tests that are too slow (>1 sec per test)
- Leave commented-out test code

## Resources

- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Coverage with Codecov](https://docs.codecov.com/)

## Questions?

Refer to:
1. Existing test examples in `test/` directory
2. Test documentation in code comments
3. Phase 6 completion documents in Projects/

---

**Last Updated:** 2026-07-29  
**Coverage:** 76.1%  
**Tests:** 371 passing (100%)  
**CI/CD:** ✅ Active
