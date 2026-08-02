# CI/CD Pipeline Setup & Usage Guide

## Quick Start

### 1. Local Development Setup

```bash
# Clone repository
git clone https://github.com/your-username/MyBookLog.git
cd MyBookLog/mybooklog

# Install dependencies
flutter pub get

# Run tests locally before pushing
flutter test --coverage
```

### 2. Making Changes

```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "Your change description"

# Push to remote
git push origin feature/your-feature
```

### 3. Create Pull Request

On GitHub:
1. Click "Compare & pull request"
2. Add description of changes
3. Click "Create pull request"

### 4. Wait for CI/CD

GitHub Actions automatically:
- ✅ Runs all tests
- ✅ Checks code format
- ✅ Validates coverage
- ✅ Uploads to Codecov

**Status:** Check green checkmark in PR

### 5. Merge

Once CI passes and code review approved:
- Click "Squash and merge"
- Delete branch

---

## Understanding CI/CD Status

### ✅ All Checks Passed

```
✓ Flutter Tests & Coverage / test
  All tests passed, coverage meets requirements
  Coverage: 76.1% (above 60% minimum)
```

**Next step:** Ready to merge after review approval

### ❌ Tests Failed

```
✗ Flutter Tests & Coverage / test
  Some tests failed, see details
```

**Actions:**
1. Click "Details" to see which tests failed
2. Fix failing tests locally
3. Commit and push again
4. CI runs automatically on new push

### ⚠️ Coverage Below Threshold

```
✗ Flutter Tests & Coverage / test
  Coverage 58.2% is below minimum 60.0%
```

**Actions:**
1. Add tests for uncovered code paths
2. Run `flutter test --coverage` locally
3. Commit and push
4. CI re-runs automatically

### ⏳ In Progress

```
🔄 Flutter Tests & Coverage / test
  Workflow is running...
```

**Wait:** Takes 5-8 minutes typically

---

## Codecov Coverage Comments

### Example PR Comment

```
## Coverage Report

| Metric | Value | Change |
|--------|-------|--------|
| Overall Coverage | 76.1% | ⬆️ +12.8% |
| Patch Coverage | 85.3% | ✅ Above 80% |

### Coverage by File
- google_books_service.dart: 100% ✅
- book_search_result.dart: 100% ✅
- auth_repository.dart: 15.8% ⬇️

**Status:** Coverage maintained, patch well-tested
```

**What it means:**
- ⬆️ Coverage improved
- ⬇️ Coverage decreased
- ✅ Meets or exceeds threshold
- ⚠️ Below threshold

---

## Troubleshooting

### CI Passes Locally But Fails on GitHub

**Problem:** Tests pass locally but fail in CI

**Cause:** Usually environment difference or timing issue

**Solution:**
1. Match Flutter version: `flutter --version`
2. If 3.16.0, you're good
3. If different, run `flutter upgrade` or downgrade
4. Run `flutter test --coverage` again

### Format Check Fails

**Problem:** `dart format --set-exit-if-changed` fails

**Solution:**
```bash
# Auto-format all code
dart format -w .

# Commit formatted code
git add .
git commit -m "Format code [skip ci]"
git push
```

### Coverage Dropped

**Problem:** PR has less coverage than main branch

**Expected:** May happen if removing code is normal

**Solution:**
1. Add tests for new code
2. Aim for 80%+ coverage on new features
3. If dropping coverage intentionally, explain in PR

**Acceptable reasons to drop:**
- Removing untested legacy code ✅
- Test infrastructure (excluded from coverage) ✅

**Not acceptable:**
- Skipping tests on new features ❌
- Removing working tests ❌

### Tests Pass But Coverage Doesn't Upload

**Problem:** Codecov comment doesn't appear on PR

**Cause:** Usually minor (badge generation only)

**Solution:**
- Tests are still passing (main goal)
- Codecov upload is best-effort
- Manual check: run `flutter test --coverage` locally

---

## Local Testing Before Push

### Recommended Workflow

```bash
# 1. Run full test suite with coverage
flutter test --coverage

# 2. Check results
echo "Tests: $(grep -c '^00:' coverage/lcov.info)"
echo "Coverage: $(python3 -c '...')"  # See calculating coverage

# 3. If coverage >= 60%, ready to push
git push origin feature-branch

# 4. If coverage < 60%, add more tests
#    Then repeat steps 1-3
```

### Calculating Coverage Locally

```bash
python3 << 'EOF'
from pathlib import Path

lcov = Path('coverage/lcov.info')
total = covered = 0

for line in lcov.read_text().split('\n'):
  if line.startswith('LF:'):
    total += int(line[3:])
  elif line.startswith('LH:'):
    covered += int(line[3:])

if total > 0:
  pct = covered / total * 100
  print(f"Coverage: {pct:.1f}% ({covered}/{total} lines)")
EOF
```

---

## Advanced CI/CD Topics

### Skipping CI on Specific Commits

```bash
# Skip CI for documentation-only changes
git commit -m "Update README [skip ci]"
```

### Viewing Workflow Logs

1. Go to GitHub repository
2. Click "Actions" tab
3. Click latest workflow run
4. Click "Flutter Tests & Coverage"
5. Click "Run tests with coverage"
6. View full output

### Manual Coverage Badge

Add to README.md:
```markdown
![Coverage](https://img.shields.io/badge/coverage-76.1%25-brightgreen)
```

Updates automatically when Codecov processes new coverage

---

## Performance Tips

### Faster Local Testing

```bash
# Only unit tests (faster)
flutter test test/unit/

# Skip coverage calculation
flutter test  # instead of flutter test --coverage
```

### Watch Mode During Development

```bash
# Automatically re-run tests on file changes
flutter test --watch
```

### Parallel Test Execution (CI Only)

Configured in GitHub Actions workflow, runs automatically

---

## Branch Protection Rules

### What Blocks Merging

❌ **Will not allow merge if:**
- Tests don't pass
- Coverage drops below 60%
- Code review not approved
- Branch not up to date with main

✅ **Will allow merge if:**
- All tests passing
- Coverage meets requirements
- At least 1 approval
- Branch is up to date

### Updating Branch Against Main

```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

---

## Monitoring Coverage

### Daily Monitoring

- Check last workflow run in Actions tab
- Coverage badge in README shows current %
- Codecov dashboard at codecov.io

### Weekly Review

- Review coverage trends on Codecov
- Check for coverage regression patterns
- Identify files with low coverage

### When Coverage is Low

**If overall drops below 60%:**
1. Identify files with new uncovered code
2. Write tests for those files
3. Target 80%+ on new code
4. Submit PR with tests

---

## Frequently Asked Questions

**Q: Why does CI take 5-8 minutes?**  
A: Flutter compilation and test execution. Typical breakdown:
- Setup: 2-3 min
- Tests: 1-2 min
- Coverage: 30-60 sec

**Q: Can I merge without waiting for CI?**  
A: No, branch protection requires all checks pass first.

**Q: What if CI is flaky?**  
A: Report in GitHub issues. Current pass rate is 100% (371/371).

**Q: How do I see coverage for specific files?**  
A: Run locally: `flutter test --coverage` then generate HTML report.

**Q: Can I increase the 60% threshold?**  
A: Yes, edit `codecov.yml` (but only increase, never decrease).

---

## Support

**Having issues?**

1. Check this guide first
2. Search GitHub issues
3. See TESTING.md for detailed test info
4. Check workflow logs (Actions tab)

**Report CI/CD issues:**
- GitHub Issues with label `ci-cd`
- Include workflow run URL
- Describe what happened vs expected

---

**Last Updated:** 2026-07-29  
**CI/CD Status:** ✅ Active  
**Support:** See TESTING.md for detailed documentation
