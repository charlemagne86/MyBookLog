# Coverage Tracking Quick Reference

**Local Coverage Setup for MyBookLog**

---

## One-Minute Setup

```bash
# Make scripts executable
chmod +x scripts/coverage.sh

# Generate your first coverage report
./scripts/coverage.sh

# View HTML report (opens in browser)
./scripts/coverage.sh html
```

---

## Commands Cheatsheet

| Command | Purpose | Output |
|---------|---------|--------|
| `./scripts/coverage.sh` | Generate report + summary + trend | Terminal |
| `./scripts/coverage.sh html` | Generate HTML report | Browser (coverage/html/) |
| `./scripts/coverage.sh trend` | Show today's coverage trend | Terminal |
| `./scripts/coverage.sh compare` | Compare with baseline | Terminal |
| `./scripts/coverage.sh baseline` | Set current as baseline | Terminal |
| `./scripts/coverage.sh help` | Show all commands | Terminal |

---

## Workflow Examples

### Before Every Commit

```bash
./scripts/coverage.sh compare
# If ✓ (no regression), safe to commit
```

### After Major Feature

```bash
./scripts/coverage.sh          # Check current
./scripts/coverage.sh baseline # Set new baseline
```

### Investigate Coverage Gap

```bash
./scripts/coverage.sh html
open coverage/html/index.html
# Click on a file to see line-level coverage
```

### Track Progress

```bash
# Run daily to track improvement
./scripts/coverage.sh trend
```

---

## Understanding the Output

### Terminal Summary

```
TOTAL: 40.2%
```
= 40% of code lines are executed by tests

### HTML Report

Visit `coverage/html/index.html`:
- 🟢 Green = Covered (100%)
- 🟡 Yellow = Partially covered (50-99%)
- 🔴 Red = Not covered (0-49%)

### Trend

```
2026-07-20 10:15: 35%
2026-07-20 12:45: 38%
2026-07-20 15:32: 40%
```
= Coverage improved throughout the day

---

## Files Generated

| File | Location | Regenerate |
|------|----------|------------|
| Terminal report | Console | Every run |
| HTML report | `coverage/html/` | `./scripts/coverage.sh html` |
| Metrics | `coverage/metrics/YYYY-MM-DD.csv` | Every run |
| Baseline | `coverage/metrics/.baseline` | `./scripts/coverage.sh baseline` |

---

## Coverage by Layer (Targets)

```
Models (shelf_book.dart, etc.)
└─ TARGET: 100% ✅ CRITICAL

Services (google_books_service.dart)
└─ TARGET: 100% ✅ CRITICAL

Repositories (bookshelf_repository.dart)
└─ TARGET: 95%+ ✅ HIGH PRIORITY

Screens (auth, bookshelf, search)
└─ TARGET: 85%+ ✅ MEDIUM PRIORITY

Utilities (utils.dart, helpers)
└─ TARGET: 90%+ ✅ MEDIUM PRIORITY
```

---

## FAQ

**Q: Why is my coverage low?**  
A: Some layers (screens) are naturally lower. Focus on 100% for models/services.

**Q: How do I find uncovered code?**  
A: Open `coverage/html/index.html` and click any file to see red (uncovered) lines.

**Q: Can I ignore some files?**  
A: Edit `coverage/.lcovrc` to add exclusion patterns.

**Q: My baseline isn't working?**  
A: Run `./scripts/coverage.sh baseline` after generating coverage.

**Q: How do I track improvement over time?**  
A: Coverage is automatically logged to `coverage/metrics/YYYY-MM-DD.csv`.

---

## Integration Points

- **Local:** This directory (development feedback)
- **CI/CD:** `.github/workflows/test.yml` (enforcement on GitHub Actions)
- **Cloud:** Codecov.io (tracking over time across all PRs)

---

## Related Files

- `coverage/.lcovrc` — LCOV configuration
- `coverage/.gitignore` — Prevent committing coverage files
- `coverage/README.md` — Detailed documentation
- `scripts/coverage.sh` — Coverage script with all commands
- `TESTING_FRAMEWORK_SETUP.md` — Full testing framework overview

---

## Troubleshooting

**"lcov command not found"**
```bash
# macOS
brew install lcov

# Linux  
sudo apt install lcov
```

**"No coverage data"**
```bash
# Ensure tests ran successfully
flutter test --coverage
```

**"HTML report is blank"**
```bash
# Regenerate
./scripts/coverage.sh html
# Clear cache and retry
rm -rf coverage/html
./scripts/coverage.sh html
```

---

## Key Takeaways

✅ Run `./scripts/coverage.sh` before every commit  
✅ Use `./scripts/coverage.sh html` to find gaps  
✅ Set baseline after reaching milestones  
✅ Track trend in `coverage/metrics/`  
✅ Focus on 100% for models and services  

---

*Part of MyBookLog's comprehensive testing framework*  
*See TESTING_FRAMEWORK_SETUP.md for full context*
