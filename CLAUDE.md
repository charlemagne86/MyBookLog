# MyBookLog Development Directives

**Purpose:** Establish coding standards, documentation practices, and daily work tracking for MyBookLog development.

**Effective Date:** 2026-07-20  
**Version:** 1.0

---

## 1. Code Documentation Standards

### 1.1 Plain English Comments Required

**Rule:** Every code update must include comments in clear, plain English that explain:
- **WHAT** the code does (business purpose)
- **WHY** it does it (business logic)
- **HOW** it works (technical implementation steps)

**Target Audience:** A non-programmer or programmer unfamiliar with this codebase should understand the code's purpose from comments alone.

### 1.2 Comment Placement & Style

```dart
/// BUSINESS LOGIC:
/// Users need to search their existing shelf before adding a book to avoid
/// duplicates. This method performs a case-insensitive partial match on title
/// and author fields.
///
/// TECHNICAL IMPLEMENTATION:
/// 1. Normalize input query to lowercase for case-insensitive comparison
/// 2. Trim whitespace to handle user typos
/// 3. Check if title or author contains the query as a substring
/// 4. Return true if match found, false otherwise
///
/// Example:
///   final book = ShelfBook(title: 'The Great Gatsby', author: 'F. Scott Fitzgerald');
///   book.matchesQuery('gatsby')     // true (matches title)
///   book.matchesQuery('scott')      // true (matches author)
///   book.matchesQuery('tolkien')    // false (no match)
bool matchesQuery(String query) {
  if (query.isEmpty) return true; // Empty query matches all
  
  final lowerQuery = query.toLowerCase().trim();
  
  // Check title
  if (title.toLowerCase().contains(lowerQuery)) return true;
  
  // Check author
  if ((author ?? '').toLowerCase().contains(lowerQuery)) return true;
  
  return false;
}
```

### 1.3 Comment Levels

Use appropriate comment levels based on complexity:

| Level | Use Case | Example |
|-------|----------|---------|
| **Block Comment** | Complex business logic, multi-step procedures | See 1.2 above |
| **Inline Comment** | Non-obvious implementation details | `final uid = auth.uid() ?? throwError()` |
| **Line Comment** | Parameter validation, edge cases | `// Empty query matches all books` |
| **Function Doc** | Public APIs, exported functions | `/// Fetches the user's bookshelf from Supabase` |

### 1.4 What NOT to Comment

❌ Don't comment obvious code:
```dart
// BAD: This is obvious from the code
final count = books.length;  // Set count to length of books
```

✅ Comment non-obvious code:
```dart
// GOOD: Explains why we trim, why case-insensitive matters
final lowerQuery = query.toLowerCase().trim();
```

### 1.5 Examples by Layer

#### Models
```dart
/// BUSINESS LOGIC:
/// Books on a shelf can be marked as read/unread, with an optional date
/// when they were read. This is used to answer "have I read this?" instantly.
///
/// TECHNICAL:
/// - isRead: true if user has read the book
/// - markedReadOn: date read (null if unread)
/// - Created from database join of bookshelf_items + books_catalog
class ShelfBook {
  /// Parse a database row from the joined query
  /// (bookshelf_items LEFT JOIN books_catalog)
  static ShelfBook fromJoinedRow(Map<String, dynamic> row) { ... }
}
```

#### Repositories
```dart
/// BUSINESS LOGIC:
/// Adding a book to shelf is atomic: either the book is added to both
/// catalog and user's shelf, or nothing changes. This prevents the
/// "add succeeded but shelf link failed" corruption.
///
/// TECHNICAL:
/// Uses server-side RPC (add_book_to_shelf) which handles upsert
/// and shelf linking in a single transaction, avoiding race conditions.
Future<bool> addBook({required String isbn, ...}) async {
  // RPC is SECURITY DEFINER, so it runs as database owner
  // This ensures only the app can modify catalog, not direct client access
  final result = await _client.rpc('add_book_to_shelf', params: {...});
  
  // already_on_shelf=true means user already had this book
  return result['already_on_shelf'] == true;
}
```

#### Services
```dart
/// BUSINESS LOGIC:
/// Google Books API often returns malformed data. This parser extracts
/// only high-confidence data and gracefully handles missing fields.
///
/// TECHNICAL:
/// 1. Reject entries without volumeInfo (incomplete data)
/// 2. Prefer ISBN-13 over ISBN-10 (more reliable)
/// 3. Convert http:// thumbnails to https:// (browser requirement)
/// 4. Trim all strings to remove extra whitespace from API
static BookSearchResult? fromGoogleVolume(Map<String, dynamic> volume) { ... }
```

### 1.6 Business Logic in Comments

Always explain the "why" from user perspective:

```dart
/// BUSINESS LOGIC:
/// Users aged 60+ often have unreliable recall of exact titles but
/// remember authors well. Search must match both to be useful:
/// - "Great Gatsby" → finds by title
/// - "Scott Fitzgerald" → finds by author
/// - "Gatsby" alone → finds (substring of title)
/// Without this, users say "I can't find my book!" and abandon the app.
///
/// TECHNICAL:
/// Substring matching is case-insensitive to handle proper noun variants
/// (e.g., "garcia márquez" vs "García Márquez").
bool matchesQuery(String query) { ... }
```

---

## 2. Daily Work Documentation

### 2.1 Folder Structure

Every day's work is organized in the vault under a consistent structure:

```
Projects/Daily/
├── 2026-07-20/
│   ├── SUMMARY.md ................. Executive summary (5-10 lines max)
│   ├── Work/
│   │   ├── feature-name-1/
│   │   │   ├── work.md ............ What was done, branch, code changes
│   │   │   └── branch-history.txt . Git log showing commits
│   │   └── feature-name-2/
│   │       ├── work.md
│   │       └── branch-history.txt
│   ├── Tests/
│   │   ├── unit-tests/
│   │   │   ├── results.md ......... Test execution summary
│   │   │   └── output.txt ........ Full test output
│   │   ├── widget-tests/
│   │   │   ├── results.md
│   │   │   └── output.txt
│   │   └── coverage/
│   │       ├── report.md ......... Coverage report
│   │       └── metrics.json ...... Coverage data
│   └── PRs/
│       ├── PR-#123-feature-x.md .. PR creation/updates
│       └── PR-#124-feature-y.md
│
├── 2026-07-21/
│   ├── SUMMARY.md
│   ├── Work/
│   ├── Tests/
│   └── PRs/
│
├── Weekly/
│   ├── 2026-W29/
│   │   ├── EXECUTIVE_SUMMARY.md .. Weekly summary
│   │   ├── Coverage-Trends.md .... Coverage by day
│   │   ├── Performance.md ........ Perf metrics
│   │   └── Issues-Blockers.md ... Blockers encountered
│   └── 2026-W30/
│
└── Index.md ...................... Master index linking all daily docs
```

### 2.2 Daily SUMMARY.md Format

Create one per day (e.g., `2026-07-20/SUMMARY.md`):

```markdown
# Work Summary — 2026-07-20

**Branch:** `feature/comprehensive-testing` (main)  
**Purpose:** Implement automated testing framework with 100% coverage goal  
**Status:** ✅ Complete

## What Was Done

- Created test fixtures and mock repositories
- Wrote 49 unit tests for models and repositories (100% coverage)
- Set up GitHub Actions CI/CD pipeline
- Created comprehensive testing documentation

## Code Changes
- 3 new test fixture files
- 3 new unit test files  
- 1 GitHub Actions workflow
- 1 test configuration script
- 2 documentation files

## Tests Executed
- Unit tests: 49/49 passing ✅
- Coverage: 40% (models layer at 100%)
- Execution time: 8.3 seconds

## Related Documents
- [[Work/testing-framework-setup]] — Detailed work log
- [[Tests/unit-tests/results]] — Test execution report
- [[PRs/PR-123-testing-framework]] — PR creation log

## Blockers/Notes
None. Framework ready for Phase 2 (widget tests).

## Next Steps
1. Implement Phase 2 widget tests (week of 2026-07-21)
2. Target 60% coverage
3. Create screen test helpers
```

### 2.3 Work Folder Files

For each feature/task (e.g., `Work/feature-testing-framework/work.md`):

```markdown
# Testing Framework Implementation

**Date:** 2026-07-20  
**Feature:** Comprehensive automated testing framework  
**Branch:** `feature/testing-framework` → `main`  
**Phase:** Phase 1 (Foundation)

## Business Purpose

MyBookLog needs regression prevention as features are added. Without automated tests:
- Bug fixes cause new bugs
- Performance regressions go undetected
- Users abandon app due to crashes

This framework provides:
- 100% code coverage enforcement
- Automated regression detection
- Performance benchmarking
- CI/CD blocking bad code before merge

## What Was Implemented

### 1. Test Infrastructure
- ✅ Test data factories (`test_data.dart`)
- ✅ Mock repositories (`mock_repositories.dart`)
- ✅ Widget test helpers (`widget_test_helpers.dart`)

### 2. Example Unit Tests
- ✅ ShelfBook model tests (22 tests)
- ✅ BookSearchResult model tests (15 tests)
- ✅ BookshelfRepository tests (12 tests)

### 3. CI/CD Pipeline
- ✅ GitHub Actions workflow (`test.yml`)
- ✅ Coverage enforcement script (`check_coverage.sh`)

### 4. Documentation
- ✅ TESTING_STRATEGY.md (architecture)
- ✅ TEST_README.md (developer guide)

## Technical Details

### Code Changes

#### New Files
1. `test/fixtures/test_data.dart` (89 lines)
   - Factories for ShelfBook, BookSearchResult
   - Test constants (ISBNs, URLs)
   
2. `test/fixtures/mock_repositories.dart` (156 lines)
   - Mock Supabase client
   - Mock repositories
   - Setup helpers

3. `test/helpers/widget_test_helpers.dart` (203 lines)
   - TestAppWrapper widget
   - WidgetTester extensions
   - Common test scenarios

#### Modified Files
1. `pubspec.yaml`
   - Added: mocktail, coverage, integration_test
   - No API changes

#### Deleted Files
None. No breaking changes.

### Testing

**Unit Tests Written:**
- ShelfBook (22 tests covering parsing, search, equality, copyWith)
- BookSearchResult (15 tests covering API parsing, ISBN extraction)
- BookshelfRepository (12 tests covering RPC calls, error handling)

**Test Results:**
```
49 tests passed in 8.3s
Coverage: 40% (models: 100%)
Lint: No issues
Format: Clean
```

### Performance Impact
- Build time: +15 seconds (one-time for new dependencies)
- Test suite execution: 8-10 seconds
- No impact on app runtime

## Related Documentation

- [[archive/Remediation-Index]] — Background on why testing matters
- [[Tests/unit-tests/results]] — Detailed test execution report
- TESTING_FRAMEWORK_SETUP.md — Overall strategy

## Git Commits

```
commit abc123 - Add test fixtures and mock infrastructure
commit def456 - Add unit tests for models and repositories
commit ghi789 - Set up GitHub Actions CI/CD
commit jkl012 - Add comprehensive testing documentation
```

See [[branch-history]] for full git log.

## Approval & Sign-Off

- ✅ Code review: Passed
- ✅ Tests: 49/49 passing
- ✅ Coverage: Meets baseline (40%, improving to 85%+ by week 4)
- ✅ Documentation: Complete

**Ready for:** Merge to main + Phase 2 start
```

### 2.4 Test Execution Results

For each test run (e.g., `Tests/unit-tests/results.md`):

```markdown
# Unit Test Execution Report

**Date:** 2026-07-20  
**Time:** 15:32 UTC  
**Duration:** 8.3 seconds  
**Branch:** `feature/testing-framework`

## Summary

| Metric | Result |
|--------|--------|
| Tests Run | 49 |
| Passed | 49 ✅ |
| Failed | 0 |
| Skipped | 0 |
| Coverage | 40% |
| Status | **PASS** |

## Results by Category

### Models (100% coverage)
- `ShelfBook` — 22/22 passing
  - Parsing: 6 tests
  - Searching: 4 tests
  - Equality: 2 tests
  - copyWith: 3 tests
  - Other: 7 tests

- `BookSearchResult` — 15/15 passing
  - Parsing Google volumes: 5 tests
  - ISBN extraction: 7 tests
  - Equality: 3 tests

### Repositories (95% coverage)
- `BookshelfRepository` — 12/12 passing
  - fetchShelf: 4 tests
  - addBook: 3 tests
  - removeBook: 2 tests
  - setReadStatus: 2 tests
  - Error handling: 1 test

## Coverage Breakdown

```
Covered Lines: 412
Total Lines: 1031
Coverage: 40%

By File:
  models/shelf_book.dart ........... 100%
  models/book_search_result.dart ... 100%
  repositories/bookshelf_repository.dart .. 95%
  config/app_config.dart ........... 85%
  utils.dart ....................... 75% (non-critical helpers)
```

## Performance

| Operation | Time |
|-----------|------|
| Compile tests | 2.1s |
| Run unit tests | 5.2s |
| Generate coverage | 1.0s |
| **Total** | **8.3s** |

## Issues & Notes

✅ No flaky tests detected.  
✅ No timeout failures.  
⚠️ Coverage gap in utils.dart — update for Phase 2.

## Next Steps

1. Run widget tests (planned 2026-07-21)
2. Implement integration tests (planned 2026-07-22)
3. Set up nightly CI runs (planned 2026-07-23)

## Full Output Log

See `output.txt` for complete test output including stderr.

---

**Executed by:** Claude Code  
**Environment:** Ubuntu 22.04, Flutter 3.16.0, Dart 3.11.0
```

### 2.5 Weekly Executive Summary

Create one per week (e.g., `Weekly/2026-W29/EXECUTIVE_SUMMARY.md`):

```markdown
# Weekly Executive Summary — Week 29 (2026-07-20 to 2026-07-26)

**Overall Status:** 🟢 On Track  
**Progress:** Phase 1 testing framework complete, Phase 2 starting  
**Risk Level:** Low

## Key Achievements

| Date | Achievement | Impact |
|------|-------------|--------|
| 2026-07-20 | Testing framework design & setup | Foundation for 100% coverage |
| 2026-07-21 | 49 unit tests passing, 40% coverage | Models fully tested |
| 2026-07-22 | CI/CD pipeline configured | Automated regression detection |
| 2026-07-23 | Widget test helpers created | Ready for Phase 2 |
| 2026-07-24 | Documentation complete | Team clarity on standards |

## Metrics

| Metric | This Week | Previous | Trend |
|--------|-----------|----------|-------|
| Code Coverage | 40% | 0% | ⬆️ +40% |
| Test Count | 49 | 10 | ⬆️ +39 |
| Build Time | 8.3s | 12s | ⬆️ -3.7s |
| Merge Blockers | 0 | 0 | ✅ Clear |

## Coverage Trend

```
Week 29: 40% (models layer: 100%)
Week 30: 60% (+ widget tests)
Week 31: 75% (+ integration tests)
Week 32: 85%+ (+ E2E + performance)

Goal: 100% enforced at 80% minimum in CI
```

## Risks & Mitigations

| Risk | Mitigation | Status |
|------|-----------|--------|
| Coverage backsliding | CI enforces minimum | ✅ In place |
| Tests become flaky | Regular review process | ✅ Weekly check |
| Performance regression | Benchmark suite | ⏳ Starting week 30 |

## Blockers

✅ None. All tasks completed as planned.

## Team Capacity

- Testing framework: 1 developer (complete)
- Feature development: Ready to resume (0 blockers)
- Code review: Capacity available

## Next Week Goals

1. ✅ Implement Phase 2 (widget tests for auth flow) — Target 60% coverage
2. ✅ Begin Phase 3 planning (integration tests)
3. ✅ First nightly CI run
4. ✅ Performance baselines established

## Links

- Daily summaries: [[Daily/2026-07-20]], [[Daily/2026-07-21]], ...
- Test reports: [[Tests/weekly-summary]]
- PR activity: [[PRs/weekly-activity]]
```

### 2.6 Master Index

Create `Projects/Daily/Index.md`:

```markdown
# Daily Work Index

Master index of all daily work documentation, organized by week.

## Current Week — Week 29 (2026-07-20 to 2026-07-26)

### Daily Summaries
- [[2026-07-20/SUMMARY]] — Testing framework setup ✅
- [[2026-07-21/SUMMARY]] — Phase 1 unit tests
- [[2026-07-22/SUMMARY]] — CI/CD configuration
- [[2026-07-23/SUMMARY]] — Widget test helpers
- [[2026-07-24/SUMMARY]] — Documentation completion

### Weekly Summary
- [[Weekly/2026-W29/EXECUTIVE_SUMMARY]] — Week 29 overview

## Quick Links by Feature

### Testing Framework
- Overview: [[TESTING_FRAMEWORK_SETUP]]
- Daily work: [[2026-07-20/Work/testing-framework-setup]]
- Test results: [[2026-07-20/Tests/unit-tests/results]]
- PR #123: [[2026-07-20/PRs/PR-123-testing-framework]]

### Future Features
(To be added as work progresses)

## By Type

### Work Completed
- [[2026-07-20/Work/testing-framework-setup]]
- [[2026-07-21/Work/unit-tests]]
- [[2026-07-22/Work/ci-cd-pipeline]]
- [[2026-07-23/Work/widget-test-helpers]]
- [[2026-07-24/Work/documentation]]

### Tests Executed
- Unit: [[2026-07-21/Tests/unit-tests/results]]
- Widget: [[2026-07-23/Tests/widget-tests/results]] (planned)
- Integration: [[2026-07-24/Tests/integration-tests/results]] (planned)
- Coverage: [[2026-07-21/Tests/coverage/report]]

### Performance Reports
- Benchmarks: [[Weekly/2026-W29/Performance]]
- Regression analysis: [[Weekly/2026-W29/Performance]]

### PRs & Code Review
- [[2026-07-20/PRs/PR-123-testing-framework]]
- [[2026-07-21/PRs/PR-124-unit-tests]]
- [[2026-07-22/PRs/PR-125-ci-cd]]

## Archive

Past weeks are archived in chronological order:
- [[Weekly/2026-W28/EXECUTIVE_SUMMARY]] (previous week)
- [[Weekly/2026-W27/EXECUTIVE_SUMMARY]] (two weeks ago)
- ...

## Searching

To find work by:
- **Date:** Look in `2026-XX-XX/` folders
- **Feature:** Look in `Work/` subfolders within date
- **Test type:** Look in `Tests/` subfolders
- **Weekly overview:** Look in `Weekly/`

---

*Last updated: 2026-07-24*
```

---

## 3. Cross-Linking Standards

### 3.1 Wikilink Usage

Use `[[filename]]` to link to other vault documents:

```markdown
# Good wikilinks (all resolve correctly)

- See [[TESTING_FRAMEWORK_SETUP]] for framework overview
- Detailed work in [[2026-07-20/Work/testing-framework-setup]]
- Test results: [[2026-07-20/Tests/unit-tests/results]]
- Weekly summary: [[Weekly/2026-W29/EXECUTIVE_SUMMARY]]
- Archive reference: [[archive/PROJECT_ANALYSIS]]

# Bad wikilinks (don't use)
- ~~See file TESTING_FRAMEWORK_SETUP.md~~ ✗ (use [[...]] instead)
- ~~Check /home/charlie/...~~ ✗ (use wikilinks, not paths)
```

### 3.2 Cross-Link Connections

Link related documents:

```markdown
## Related Documentation

- **Background:** [[archive/Feature-Enhancement-Roadmap]]
- **Previous work:** [[2026-07-19/SUMMARY]]
- **Detailed test results:** [[2026-07-20/Tests/unit-tests/results]]
- **Code changes:** See branch history in [[2026-07-20/Work/testing-framework-setup]]
- **PR discussion:** [[2026-07-20/PRs/PR-123-testing-framework]]
- **Next steps:** [[2026-07-21/SUMMARY]]
```

### 3.3 Backlinks

Document files should link back to their daily summary:

```markdown
# Unit Test Results — 2026-07-20

**Related:** [[2026-07-20/SUMMARY]]  
**Part of feature:** [[2026-07-20/Work/testing-framework-setup]]

(content follows)
```

---

## 4. Code Review Integration

### 4.1 PR Documentation

For each PR, document:

```markdown
# PR #123: Testing Framework Setup

**Branch:** `feature/testing-framework` → `main`  
**Author:** Claude Code  
**Date:** 2026-07-20  
**Related work:** [[2026-07-20/Work/testing-framework-setup]]

## What This PR Does

(Description of changes, matching PR body)

## Code Review Checklist

- [x] All code has plain English comments explaining business logic + technical steps
- [x] All new tests passing (49/49)
- [x] Coverage meets or exceeds threshold (40% baseline, on path to 85%)
- [x] No performance regressions
- [x] Documentation updated
- [x] Daily work documented in vault

## Test Results

See [[2026-07-20/Tests/unit-tests/results]] for full test execution report.

## Approval Status

- ✅ Code review: APPROVED
- ✅ Tests: PASSING
- ✅ Coverage: ACCEPTABLE
- ✅ Documentation: COMPLETE

**Ready to merge:** Yes
```

---

## 5. Implementation Checklist

### Before Every Code Commit

- [ ] **Comments added:** All updated code has plain English comments
  - [ ] Business logic explained (why)
  - [ ] Technical implementation explained (how)
  - [ ] Non-obvious code has inline comments
  
- [ ] **Tests pass:** `flutter test --coverage` passes
  - [ ] No test failures
  - [ ] Coverage maintained or improved
  - [ ] No new warnings
  
- [ ] **No linting issues:** `flutter analyze` passes
  - [ ] No unused imports
  - [ ] No format issues

### Before Pushing to Remote

- [ ] **Commit message clear:** Describes what & why
- [ ] **Daily work documented:** Added to vault with date folder
- [ ] **Test results recorded:** In `Daily/YYYY-MM-DD/Tests/`
- [ ] **Wikilinks added:** Related documents cross-linked

### Before Creating PR

- [ ] **Branch is up-to-date:** `git pull origin main`
- [ ] **All CI checks pass locally:** Simulate GitHub Actions
- [ ] **PR description complete:** Links to daily work documentation
- [ ] **Test results attached:** References to `Daily/YYYY-MM-DD/Tests/`

### Weekly (Friday)

- [ ] **Weekly summary created:** `Weekly/YYYY-WXX/EXECUTIVE_SUMMARY.md`
- [ ] **Coverage trends documented:** `Weekly/YYYY-WXX/Coverage-Trends.md`
- [ ] **Blockers and risks noted:** For stakeholder awareness
- [ ] **Next week goals outlined:** For continuity

---

## 6. Tools & Commands

### Create Daily Folder

```bash
# Create today's folder
mkdir -p Projects/Daily/2026-07-20/{Work,Tests,PRs}

# Create subfolders for features
mkdir -p Projects/Daily/2026-07-20/Work/feature-name-1
mkdir -p Projects/Daily/2026-07-20/Tests/unit-tests
mkdir -p Projects/Daily/2026-07-20/Tests/widget-tests
mkdir -p Projects/Daily/2026-07-20/Tests/coverage
```

### Git Commands to Include in Daily Docs

```bash
# Show today's commits
git log --oneline --since="today" origin/feature-branch

# Show branch differences
git log --oneline main..feature-branch

# Generate branch history file
git log --oneline --decorate feature-branch > Projects/Daily/2026-07-20/Work/feature-name/branch-history.txt
```

### Test Execution with Output Capture

```bash
# Capture unit test output
flutter test test/unit/ --coverage > Projects/Daily/2026-07-20/Tests/unit-tests/output.txt 2>&1

# Capture coverage report
lcov --list coverage/lcov.info > Projects/Daily/2026-07-20/Tests/coverage/metrics.txt
```

---

## 7. Enforcement & Consistency

### Definition of Done

A task is only "done" when:

1. ✅ Code is written with comprehensive comments (business logic + technical steps)
2. ✅ All tests pass (100% of new code tested)
3. ✅ No lint or format warnings
4. ✅ Daily work documented in vault with date folder
5. ✅ Test results recorded in `Daily/YYYY-MM-DD/Tests/`
6. ✅ Cross-links added to related documents
7. ✅ PR created with reference to daily work documentation

### Code Review Criteria

Every PR must include:

- [ ] Comprehensive code comments (business logic + technical)
- [ ] Passing tests with coverage report
- [ ] Reference to daily work documentation (`Daily/YYYY-MM-DD/`)
- [ ] Links to test results in vault
- [ ] Updated vault documents (if applicable)

---

## 8. Examples

See these documents for concrete examples:

- **Code comments:** `lib/src/data/models/shelf_book.dart` (exemplar)
- **Daily work:** `Projects/Daily/2026-07-20/Work/testing-framework-setup/work.md`
- **Test execution:** `Projects/Daily/2026-07-20/Tests/unit-tests/results.md`
- **Weekly summary:** `Projects/Weekly/2026-W29/EXECUTIVE_SUMMARY.md`
- **PR documentation:** `Projects/Daily/2026-07-20/PRs/PR-123-testing-framework.md`

---

## 9. Questions?

If unclear on any directive:

1. **Code comments:** Reference examples in `lib/src/data/models/`
2. **Vault structure:** See `Projects/Daily/Index.md` for live example
3. **Daily documentation:** Follow template in section 2.3
4. **Cross-linking:** Use `[[filename]]` format consistently

---

**This directive is binding for all future development on MyBookLog.**

*Created: 2026-07-20*  
*Version: 1.0*  
*Status: Active*
