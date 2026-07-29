---
name: phase-6-plan
description: Phase 6 Coverage Expansion & CI/CD Integration plan
metadata:
  type: project
---

# Phase 6 — Coverage Expansion & CI/CD Integration

**Phase Status:** Starting  
**Baseline Coverage:** 60-65% (151+/144 tests passing)  
**Target Coverage:** 75-80%  
**Estimated Duration:** 3-4 days  
**Start Date:** 2026-07-29  

---

## Executive Summary

Phase 5 successfully achieved production-ready test coverage (60-65%, 151+ tests). Phase 6 focuses on:

1. **Coverage Gap Analysis** — Identify uncovered code paths
2. **Missing Test Cases** — Write tests for gaps
3. **CI/CD Integration** — Automate test runs via GitHub Actions
4. **Performance Baselines** — Establish regression detection
5. **Documentation** — Complete Phase 6 work documentation

**Expected Outcome:**
- ✅ 75-80% coverage achieved
- ✅ GitHub Actions CI/CD pipeline active
- ✅ Performance regression detection enabled
- ✅ Comprehensive testing documentation complete

---

## Phase Breakdown

### Phase 6.1 — Coverage Gap Analysis (2 hours)
**Goal:** Identify uncovered code paths and categorize by priority

#### Tasks
1. Run coverage report and identify gaps
2. Analyze by file and function
3. Categorize gaps by:
   - Critical paths (must cover)
   - Important features (should cover)
   - Edge cases (nice to have)
   - Dead code (ignore)

#### Output
- Coverage report: `PHASE-6-1-COVERAGE-GAPS.md`
- Gap analysis by priority
- Test plan for gaps

---

### Phase 6.2 — Critical Path Coverage (8 hours)
**Goal:** Write tests for all critical paths not yet covered

#### Files to Analyze (Priority: HIGH)

**1. lib/src/config/app_config.dart**
- Coverage: ~85%
- Missing: Configuration edge cases, fallback scenarios
- Tests needed: 3-5 tests

**2. lib/src/data/models/shelf_book.dart**
- Coverage: ~100% (already well-covered)
- Status: COMPLETE

**3. lib/src/data/models/book_search_result.dart**
- Coverage: ~100% (already well-covered)
- Status: COMPLETE

**4. lib/src/data/services/google_books_service.dart**
- Coverage: ~75%
- Missing: Timeout scenarios, rate limiting, response parsing edge cases
- Tests needed: 5-8 tests

**5. lib/src/data/repositories/auth_repository.dart**
- Coverage: ~80%
- Missing: Concurrent operations, session edge cases
- Tests needed: 3-5 tests

**6. lib/src/data/repositories/bookshelf_repository.dart**
- Coverage: ~80%
- Missing: Large dataset handling, concurrent operations, race conditions
- Tests needed: 4-6 tests

**7. lib/src/features/screens/**
- Coverage: ~50-60%
- Missing: Error states, loading states, edge cases
- Tests needed: 8-12 tests (relates to Phase 5 pending edge cases)

#### Tasks
1. Write tests for critical path gaps
2. Focus on error handling
3. Ensure edge cases covered
4. Target: 12-20 new tests

#### Output
- New test files or additions to existing ones
- Coverage improvement: 60-65% → 70-75%
- Test results report

---

### Phase 6.3 — Feature Coverage Expansion (6 hours)
**Goal:** Write tests for important features and edge cases

#### Key Areas
1. **Search functionality** (Google Books API integration)
   - Timeout handling
   - Malformed API responses
   - Rate limiting scenarios

2. **Bookshelf operations** (CRUD operations)
   - Concurrent add/remove
   - Session expiry during operations
   - Large bookshelf handling

3. **Authentication** (Login/Signup)
   - Password validation rules
   - Email format validation
   - Signup error scenarios

4. **Navigation & Routing**
   - Auth state changes
   - Deep linking (if applicable)
   - State preservation on app resume

#### Tasks
1. Write 10-15 feature-focused tests
2. Cover important edge cases
3. Ensure error scenarios tested
4. Target: 70-75% → 75-80%

#### Output
- Additional test files
- Coverage improvement report
- Feature coverage matrix

---

### Phase 6.4 — CI/CD Integration (4 hours)
**Goal:** Automate testing via GitHub Actions

#### GitHub Actions Workflow
Create `.github/workflows/test.yml`:

```yaml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests with coverage
      run: flutter test --coverage
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        files: ./coverage/lcov.info
    
    - name: Enforce minimum coverage
      run: |
        COVERAGE=$(grep -oP 'lines<area type="procedure".*?>\K[^<]+' coverage/index.html || echo "0")
        if (( ${COVERAGE%.*} < 75 )); then
          echo "Coverage $COVERAGE% is below 75% minimum"
          exit 1
        fi
```

#### Tasks
1. Create GitHub Actions workflow
2. Configure coverage upload to Codecov
3. Add branch protection rules requiring tests to pass
4. Set up coverage reports/badges
5. Document CI/CD process

#### Output
- `.github/workflows/test.yml`
- Coverage badge in README
- CI/CD documentation

---

### Phase 6.5 — Performance Baselines (3 hours)
**Goal:** Establish performance metrics for regression detection

#### Baselines to Capture
1. **Startup time** — App launch to ready state
2. **Navigation latency** — Screen transition time
3. **Search latency** — API search to results
4. **Build time** — Test suite execution time

#### Tasks
1. Extract performance metrics from integration tests
2. Create baseline report
3. Document threshold values
4. Set up performance regression detection

#### Output
- Performance baseline report
- Threshold definitions
- Regression detection script

---

### Phase 6.6 — Documentation & Finalization (2 hours)
**Goal:** Document all Phase 6 work

#### Documentation
1. Phase 6 completion summary
2. Coverage breakdown by file
3. CI/CD process documentation
4. Performance baseline documentation
5. Testing best practices guide

#### Tasks
1. Write completion summary
2. Create coverage report
3. Document CI/CD setup
4. Finalize vault documentation
5. Update project README

#### Output
- `PHASE-6-SUMMARY.md`
- Coverage report with breakdown
- CI/CD documentation
- Performance baseline documentation

---

## Coverage Goals by File

Current → Target:

| File | Current | Target | Gap | Priority |
|------|---------|--------|-----|----------|
| app_config.dart | 85% | 95% | +10% | HIGH |
| shelf_book.dart | 100% | 100% | ✓ | COMPLETE |
| book_search_result.dart | 100% | 100% | ✓ | COMPLETE |
| google_books_service.dart | 75% | 85% | +10% | HIGH |
| auth_repository.dart | 80% | 90% | +10% | HIGH |
| bookshelf_repository.dart | 80% | 90% | +10% | HIGH |
| screens/ | 50-60% | 70% | +10-20% | HIGH |
| **Overall** | **60-65%** | **75-80%** | **+15-20%** | **TARGET** |

---

## Test Estimation

### Phase 6.2 — Critical Paths
- AppConfig: 3-5 tests
- GoogleBooksService: 5-8 tests
- AuthRepository: 3-5 tests
- BookshelfRepository: 4-6 tests
- **Subtotal: 15-24 tests**

### Phase 6.3 — Feature Coverage
- Search edge cases: 3-4 tests
- Bookshelf operations: 3-4 tests
- Auth flows: 2-3 tests
- Navigation: 2-3 tests
- **Subtotal: 10-14 tests**

### Phase 6.4 — CI/CD
- No additional tests (configuration only)

### Phase 6.5 — Performance
- No additional tests (metric extraction from existing)

---

## Success Criteria

✅ **Coverage Achieved:** 75-80% (from 60-65%)  
✅ **New Tests:** 25-38 tests implemented  
✅ **CI/CD Active:** GitHub Actions running on every PR  
✅ **Performance Tracked:** Baselines established and monitored  
✅ **Documentation:** Complete and up-to-date  
✅ **No Regressions:** All Phase 5 tests still passing  

---

## Schedule (Best Case)

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| 6.1 - Gap Analysis | 2h | Day 1, 9am | Day 1, 11am |
| 6.2 - Critical Coverage | 8h | Day 1, 11am | Day 2, 3pm |
| 6.3 - Feature Coverage | 6h | Day 2, 3pm | Day 3, 9am |
| 6.4 - CI/CD | 4h | Day 3, 9am | Day 3, 1pm |
| 6.5 - Performance | 3h | Day 3, 1pm | Day 3, 4pm |
| 6.6 - Documentation | 2h | Day 3, 4pm | Day 3, 6pm |
| **Total** | **25h** | **Day 1** | **Day 3, EOD** |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Coverage plateau at 70% | Medium | High | Add edge case tests, focus on critical paths |
| Test flakiness on CI | Low | Medium | Use proper async/await patterns, avoid timing-dependent tests |
| Performance regression | Low | High | Establish baselines before CI goes live |
| Incomplete coverage of screens | High | Medium | Phase 5.1 pending work on LoginScreen/BookshelfScreen edge cases |

---

## Deliverables

### Code
- 25-38 new tests
- CI/CD workflow configuration
- Performance baseline scripts

### Documentation
- Coverage gap analysis
- Phase 6 completion summary
- CI/CD setup guide
- Performance baseline report
- Updated testing best practices

### Artifacts
- Coverage report (75-80% achieved)
- CI/CD pipeline (GitHub Actions)
- Performance metrics dashboard (if applicable)
- Regression detection system

---

## Phase 6 → Phase 7 Transition

After Phase 6 completion, next phases could include:

**Phase 7 — E2E & Integration Testing Expansion**
- Complete end-to-end user journeys
- Cross-feature integration scenarios
- Load testing
- Target: 85-90% coverage

**Phase 8 — Code Quality & Performance**
- Lint rule enforcement
- Performance optimization
- Code review standards enforcement
- Target: 95%+ coverage

**Phase 9 — Production Readiness**
- Security testing
- Accessibility testing
- Documentation completeness
- Release engineering

---

## Getting Started

### Next Immediate Steps
1. Create `PHASE-6-1-COVERAGE-GAPS.md` with gap analysis
2. Run coverage report to identify specific gaps
3. Categorize by priority
4. Create test plan for gaps
5. Begin Phase 6.2 implementation

### Command to Generate Coverage
```bash
cd /home/charlie/Repositories/MyBookLog/mybooklog
flutter test --coverage
lcov --list coverage/lcov.info
```

### Expected Output
- Detailed coverage breakdown
- Identified gaps by file
- Test count needed for target

---

## Notes

- Phase 5 pending edge cases (4 tests) can be completed in parallel with Phase 6
- CI/CD pipeline can be enabled once Phase 6.2 coverage is adequate
- Performance baselines should be captured before optimizations to avoid false positives
- Focus on critical paths first to maximize coverage gain with minimum effort

---

**Document Created:** 2026-07-29  
**Status:** Ready to begin Phase 6.1  
**Next Review:** After Phase 6.1 gap analysis

