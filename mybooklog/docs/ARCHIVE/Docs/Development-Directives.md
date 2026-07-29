# Development Directives

**Established:** 2026-07-20  
**Status:** 🔴 **ACTIVE & BINDING**

Standard directives for all MyBookLog development: code documentation, daily work tracking, and cross-linking practices.

---

## 1. Code Documentation

### Standard

Every code update must include comprehensive comments explaining:
- **BUSINESS LOGIC** — Why this matters to users
- **TECHNICAL** — How the implementation works

**Target:** A non-programmer should understand the code's purpose from comments alone.

### By Layer

**Models:**
```dart
/// BUSINESS LOGIC:
/// The shelf tracks which books a user owns. Each book can be marked
/// as read/unread. This answers "Have I read this?" instantly,
/// preventing accidental duplicate purchases.
///
/// TECHNICAL:
/// - isRead: boolean flag (true = read, false = unread)
/// - markedReadOn: ISO 8601 date when marked read (optional)
class ShelfBook { ... }
```

**Services:**
```dart
/// BUSINESS LOGIC:
/// Google Books API sometimes returns incomplete data.
/// This parser extracts only high-confidence fields, handling
/// missing data gracefully. Bad data is worse than no data.
///
/// TECHNICAL:
/// 1. Reject entries missing volumeInfo
/// 2. Prefer ISBN-13 over ISBN-10
/// 3. Convert http:// to https://
static BookSearchResult? fromGoogleVolume(Map data) { ... }
```

**Repositories:**
```dart
/// BUSINESS LOGIC:
/// Adding a book to shelf is atomic: either succeeds completely
/// or fails completely. This prevents data inconsistency.
///
/// TECHNICAL:
/// Uses server-side RPC (add_book_to_shelf) which handles
/// catalog upsert and shelf linking in a single SQL transaction.
Future<bool> addBook({...}) async { ... }
```

### Comment Levels

| Level | When | Example |
|-------|------|---------|
| Block | Complex logic | BUSINESS LOGIC + TECHNICAL sections |
| Inline | Non-obvious code | `// Empty query matches all books` |
| Function | Public APIs | `/// Fetches user's bookshelf` |

### What NOT to Comment

❌ **Don't comment obvious code:**
```dart
final count = books.length;  // Get the number of books (BAD)
```

✅ **Do comment non-obvious code:**
```dart
// Case-insensitive search: Users 60+ type "garcia marquez"
// vs "García Márquez". Without this, search fails.
final query = input.toLowerCase();
```

---

## 2. Daily Work Documentation

### Folder Structure

```
Projects/Work/
└── 2026-07-22/                 ← Current week
    ├── INDEX.md                ← Documentation index
    ├── QUICK-START.md
    ├── OVERVIEW.md
    ├── SETUP-GUIDE.md
    ├── USER-GUIDE.md
    ├── REFERENCE.md
    ├── ARCHITECTURE.md
    └── PERFORMANCE-BASELINES.md
```

### SUMMARY.md (Daily)

Create one per day. **5-10 lines maximum.**

```markdown
# Work Summary — 2026-07-22

**Branch:** `feature/xxx`  
**Purpose:** [One-line purpose]  
**Status:** ✅ Complete

## What Was Done
- Item 1
- Item 2

## Tests
- Unit: XX/XX passing
```

### Work Log (Detailed)

For each major feature/task:

```markdown
# Feature: [Name]

**Date:** 2026-07-22  
**Branch:** `feature/xxx`

## Business Purpose
Why this feature matters to users

## What Was Implemented
- Detail 1
- Detail 2

## Technical Details
Code changes, architecture decisions

## Testing
Tests added, results
```

### Test Results

For each test run:

```markdown
# Test Execution Report

**Date:** 2026-07-22 15:32 UTC  
**Duration:** 8.3s

## Summary
| Metric | Result |
|--------|--------|
| Tests | 49 ✅ |
| Coverage | 40% |
```

---

## 3. Cross-Linking

### Format

Use Obsidian wikilink syntax: `[[filename]]`

### Example

```markdown
## Related Documents

- **Daily summary:** [[Work/2026-07-22/SUMMARY]]
- **Detailed work:** [[Work/2026-07-22/Work/feature-name]]
- **Test results:** [[Work/2026-07-22/Tests/results]]
- **Architecture:** [[Docs/Testing-Framework]]
```

### Benefits

✅ **Context** — Understand what came before/after  
✅ **Discoverability** — Find related work easily  
✅ **Traceability** — Follow decision chain  
✅ **Navigation** — Jump between docs  
✅ **Knowledge Preservation** — New team members understand history  

---

## 4. Implementation Checklist

### Before Every Commit

- [ ] **Comments added** to all changed code
  - [ ] Business logic explained
  - [ ] Technical steps explained
  - [ ] Non-obvious code has inline comments

- [ ] **Tests pass**
  - [ ] No failures
  - [ ] Coverage maintained/improved
  - [ ] No new warnings

- [ ] **Code quality**
  - [ ] `flutter analyze` passes
  - [ ] `dart format` clean
  - [ ] No unused imports

### Before Pushing

- [ ] Branch is up-to-date (`git pull`)
- [ ] All CI checks pass locally
- [ ] Daily work documented
- [ ] Test results recorded

### Before Creating PR

- [ ] PR references daily documentation
- [ ] Test results linked
- [ ] Wikilinks added
- [ ] Code reviewed against standards

---

## 5. Definition of Done

A task is "done" only when:

1. ✅ Code written with comprehensive comments
2. ✅ All tests pass (100% of new code tested)
3. ✅ No lint/format warnings
4. ✅ Daily work documented
5. ✅ Test results recorded
6. ✅ Cross-links added
7. ✅ PR created (if applicable)

---

## 6. FAQ

**Q: Do I need to comment every line?**  
A: No. Comment non-obvious code. Loops and conditionals don't need comments.

**Q: How detailed should documentation be?**  
A: SUMMARY = 5-10 lines. Work log = 500-2000 words. Test results = Structured report.

**Q: Can I skip daily documentation for small changes?**  
A: No. Even small changes are documented for traceability.

**Q: What if I don't finish a task?**  
A: Document the current state, what remains, and why it wasn't finished.

---

**This is binding for all MyBookLog development.**  
**Version:** 1.0 | **Updated:** 2026-07-23

