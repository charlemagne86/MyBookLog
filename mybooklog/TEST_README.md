# MyBookLog Testing Framework

Complete guide to the automated testing, code coverage, and performance benchmarking framework for MyBookLog.

## Quick Start

### Run All Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test category
flutter test test/unit/                    # Unit tests only
flutter test test/widget/                  # Widget tests only
flutter test test/integration/             # Integration tests only
```

### View Coverage

```bash
# Generate coverage report
flutter test --coverage

# View in terminal
lcov --list coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
# Open in browser: open coverage/html/index.html
```

---

## Testing Architecture

The test suite is organized into four tiers matching the testing pyramid:

### Tier 1: Unit Tests (50% of suite)
**Location:** `test/unit/`  
**Coverage Target:** 100% for models, services, repositories  
**Time:** ~5 seconds

Unit tests verify pure logic without framework dependencies or network calls.

```
test/unit/
├── models/              # Model parsing, equality, transformation
├── services/            # Business logic, query building, parsing
├── repositories/        # Repository methods with mocked Supabase
└── config/             # Configuration values
```

**Run:** `flutter test test/unit/`

### Tier 2: Widget Tests (25% of suite)
**Location:** `test/widget/`  
**Coverage Target:** 90%+ for screens  
**Time:** ~30 seconds

Widget tests verify UI interactions, navigation, and state changes.

```
test/widget/
├── screens/            # Login, SignUp, Bookshelf, Search screens
├── widgets/            # Reusable widget components
└── helpers/           # TestAppWrapper, finder extensions
```

**Run:** `flutter test test/widget/`

### Tier 3: Integration Tests (15% of suite)
**Location:** `test/integration/`  
**Coverage Target:** Key user flows  
**Time:** ~45 seconds

Integration tests verify multi-screen flows and state management.

```
test/integration/
├── auth_flow_test.dart           # Login → Bookshelf
├── book_operations_test.dart     # Search → Add → Read → Remove
└── error_handling_test.dart      # Network error recovery
```

**Run:** `flutter test test/integration/`

### Tier 4: E2E Tests (10% of suite)
**Location:** `integration_test/`  
**Coverage Target:** Critical user journeys  
**Time:** ~2 minutes

E2E tests run on real/emulated devices with actual Supabase backend.

**Run:** `flutter test integration_test/`

---

## Test Fixtures & Mocks

### Test Data Factories

Create consistent test objects using `TestData`:

```dart
import 'package:mybooklog_test/fixtures/test_data.dart';

// Create a sample book
final book = TestData.sampleShelfBook(
  title: 'Dune',
  author: 'Frank Herbert',
  isRead: true,
);

// Create multiple books
final books = TestData.sampleShelfBooks(count: 10);

// Access constants
const isbn = TestData.validIsbn13;
const url = TestData.validThumbnailUrl;
```

See `test/fixtures/test_data.dart` for all available factories.

### Mock Repositories

Use pre-built mocks for testing without network:

```dart
import 'package:mybooklog_test/fixtures/mock_repositories.dart';

// Setup successful auth
MockSupabaseClient mockClient = MockSupabaseClient();
setupMockAuthSuccess(mockClient, userId: 'test-user');

// Setup shelf fetch
setupMockShelfFetch(
  mockClient,
  books: [
    {'book_id': 'b1', 'books_catalog': {...}},
  ],
);
```

See `test/fixtures/mock_repositories.dart` for mock utilities.

### Widget Test Helpers

Convenient extensions for widget testing:

```dart
import 'package:mybooklog_test/helpers/widget_test_helpers.dart';

// Pump a test widget
await tester.pumpTestWidget(
  const LoginScreen(),
  providers: [
    Provider.value(value: mockAuthRepository),
  ],
);

// Enter text
await tester.typeText('user@example.com');

// Tap button
await tester.tapButton('Login');

// Check for error
await tester.waitFor(find.text('Invalid credentials'));
```

See `test/helpers/widget_test_helpers.dart` for all helpers.

---

## Writing Tests

### Unit Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyModel', () {
    group('method name', () {
      test('describes expected behavior', () {
        // Arrange: Set up test data
        final input = 'test input';

        // Act: Execute the code being tested
        final result = MyModel.method(input);

        // Assert: Verify the result
        expect(result, 'expected output');
      });
    });
  });
}
```

### Widget Test Pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mybooklog_test/helpers/widget_test_helpers.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows error on login failure', (tester) async {
      // Arrange
      final mockAuthRepository = MockAuthRepository();
      when(() => mockAuthRepository.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(const AuthException('Invalid credentials'));

      await tester.pumpTestWidget(
        const LoginScreen(),
        providers: [
          Provider.value(value: mockAuthRepository),
        ],
      );

      // Act
      await tester.typeText('test@example.com');
      await tester.typeText('password');
      await tester.tapButton('Login');

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

### Repository Test Pattern

```dart
import 'package:mocktail/mocktail.dart';
import 'package:mybooklog_test/fixtures/mock_repositories.dart';

void main() {
  group('BookshelfRepository', () {
    late MockSupabaseClient mockClient;
    late BookshelfRepository repository;

    setUp(() {
      mockClient = MockSupabaseClient();
      setupMockAuthSuccess(mockClient);
      repository = BookshelfRepository(mockClient);
    });

    test('fetchShelf returns parsed books', () async {
      // Arrange
      setupMockShelfFetch(mockClient, books: [
        {
          'book_id': 'b1',
          'books_catalog': {'title': 'Dune'},
        },
      ]);

      // Act
      final result = await repository.fetchShelf();

      // Assert
      expect(result, hasLength(1));
      expect(result[0].title, 'Dune');
    });
  });
}
```

---

## Code Coverage

### Measuring Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage in terminal
lcov --list coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals

| Layer | Target | Current |
|-------|--------|---------|
| Models | 100% | — |
| Services | 100% | — |
| Repositories | 95% | — |
| Screens | 85% | — |
| Utils | 100% | — |

### Coverage Enforcement

The CI pipeline enforces minimum 80% overall coverage:

```bash
# Local check (same as CI)
bash .github/scripts/check_coverage.sh 80
```

PRs will be blocked if coverage drops below this threshold.

---

## Performance Benchmarking

### Running Benchmarks

```bash
# Run performance tests
flutter test test/benchmarks/

# Run with profiling data
flutter test test/benchmarks/ --profile
```

### Benchmark Examples

```dart
test('fetchShelf with 100 books completes in <500ms', () async {
  final stopwatch = Stopwatch()..start();
  final result = await repository.fetchShelf();
  stopwatch.stop();

  expect(result, hasLength(100));
  expect(stopwatch.elapsedMilliseconds, lessThan(500));
});
```

### Performance Targets

| Operation | Target | Status |
|-----------|--------|--------|
| Shelf fetch (100 books) | <500ms | ✓ |
| Shelf fetch (500+ books) | <2000ms | ✓ |
| Google Books search | <1000ms | ✓ |
| Screen render | <300ms | ✓ |
| Complete auth flow | <3000ms | ✓ |

---

## Continuous Integration

### GitHub Actions Workflows

#### `test.yml` - On every PR and push
- Runs `flutter analyze`
- Runs all unit tests with coverage
- Runs widget tests with coverage
- Merges coverage reports
- Enforces 80% minimum coverage
- Uploads results to Codecov
- Posts coverage comment on PR

#### `performance.yml` - Weekly (Monday 3 AM UTC)
- Runs performance benchmarks
- Compares against baseline
- Alerts if regressions detected

#### `e2e.yml` - Nightly (2 AM UTC)
- Runs E2E tests on Android emulator
- Runs E2E tests on iOS simulator
- Captures screenshots on failure

### Local Pre-commit Hook

Automatically run tests before committing:

```bash
# Install pre-commit hook
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Or use a tool like husky
npm install husky
npx husky install
```

---

## Best Practices

### Do's ✅

- **Test one thing per test** — Single assertion per test when possible
- **Use descriptive test names** — `test('returns books sorted by title')`
- **Setup and teardown** — Use `setUp()` and `tearDown()` for test isolation
- **Mock external dependencies** — Never call real APIs in tests
- **Test edge cases** — Empty lists, null values, errors
- **Keep tests fast** — Unit tests should be <100ms each
- **Test behavior, not implementation** — Focus on what, not how

### Don'ts ❌

- **Don't test the framework** — `expect(1 + 1, 2)` is not a useful test
- **Don't skip flaky tests** — Fix them instead
- **Don't share state between tests** — Each test should be independent
- **Don't hardcode values** — Use factories and fixtures
- **Don't comment out tests** — Delete them or fix them
- **Don't sleep in tests** — Use `pumpAndSettle()` instead

### Test Organization

```dart
void main() {
  group('Component', () {
    // Setup common to all tests in this group
    late Component component;

    setUp(() {
      component = Component();
    });

    group('method1', () {
      test('behavior when X', () { ... });
      test('behavior when Y', () { ... });
    });

    group('method2', () {
      test('behavior when Z', () { ... });
    });
  });
}
```

---

## Debugging Tests

### Enable verbose output

```bash
flutter test --verbose
```

### Debug a single test

```bash
flutter test test/unit/models/shelf_book_test.dart -v
```

### Use debugPrint in tests

```dart
import 'package:flutter/foundation.dart';

debugPrint('Current shelf: ${shelf.length} books');
```

### Use breakpoints (VS Code)

1. Set breakpoint in test file
2. Run: `flutter test --start-paused test/unit/models/shelf_book_test.dart`
3. Open DevTools debugger link in browser

---

## Maintenance & Monitoring

### Weekly

- Review flaky tests in CI logs
- Fix or skip tests marked flaky
- Update test dependencies

### Monthly

- Review coverage reports
- Identify low-coverage areas
- Create issues for coverage gaps

### Quarterly

- Analyze performance trends
- Identify slow tests
- Optimize hot paths

---

## Common Issues

### Issue: Tests timeout
**Solution:** Use `pumpAndSettle()` to wait for animations to complete.

### Issue: "No Material widget found"
**Solution:** Wrap your widget in `TestAppWrapper` which provides Material context.

### Issue: Mock not being called
**Solution:** Verify you're using the mock instance, not creating a new one. Check `setUp()`.

### Issue: Snapshot/golden file mismatch
**Solution:** Review the changes, then run: `flutter test --update-goldens`

---

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mockito/Mocktail](https://pub.dev/packages/mocktail)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)
- [Code Coverage with LCOV](http://ltp.sourceforge.net/coverage/lcov.php)

---

## Next Steps

1. **Add unit tests for all models** → Target: 100% coverage
2. **Add unit tests for repositories** → Test with mocks
3. **Add widget tests for screens** → Focus on user flows
4. **Set up CI/CD** → GitHub Actions workflows
5. **Monitor coverage** → Codecov dashboard
6. **Add E2E tests** → Critical user journeys

---

*Last updated: 2026-07-20*  
*Maintainer: Testing Framework Team*
