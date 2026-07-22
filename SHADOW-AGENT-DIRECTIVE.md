# Shadow Agent Verification Directive

**Established:** 2026-07-20  
**Status:** 🔴 **BINDING & MANDATORY**  
**Scope:** All work on MyBookLog

---

## Purpose

Prevent incomplete work from being marked as "done". Require **independent verification** before any task, feature, or fix is considered complete.

**Why:** The local coverage tracking setup was documented as done but not actually implemented. This directive prevents that from happening again.

---

## The System

### Two-Agent Verification

```
Main Agent (Claude Code)
    ↓ (completes work)
    ↓
Verify: Does the work match the claim?
    ↓ (writes summary)
    ↓
Shadow Agent (independent verification)
    ↓ (checks independently)
    ↓
Verify: Is the work actually done?
    ↓
Both sign off? 
    YES → Task is DONE ✅
    NO → Task is INCOMPLETE, fix required
```

### Definition: "Done"

A task is **DONE** only when:

1. ✅ **Main agent claim:** "I have completed X"
2. ✅ **Main agent evidence:** Links to files, commands to verify, screenshots
3. ✅ **Shadow agent verification:** Independent confirmation that:
   - Files actually exist at claimed locations
   - Files have correct content
   - Commands work as stated
   - No functionality gaps
   - No documentation gaps
   - All related documents updated
4. ✅ **Both sign off:** "I confirm this is complete"

**If either agent says "not done", it is INCOMPLETE.**

---

## Main Agent Responsibilities

### Before Claiming "Done"

1. **Verify locally** — Run commands, check files, test functionality
2. **Document evidence** — Provide specific file paths and verification steps
3. **Link documentation** — Show related docs, update vault
4. **Summary statement** — "I have completed X. Evidence: [specific files]"

### Checklist Before Claiming Done

- [ ] Primary deliverables exist (files/code/configs)
- [ ] Secondary deliverables exist (tests/docs/examples)
- [ ] Commands provided to verify
- [ ] Related documents cross-linked
- [ ] No functionality gaps identified
- [ ] No documentation gaps identified
- [ ] Vault updated with latest work
- [ ] Ready for shadow verification

---

## Shadow Agent Responsibilities

### Independent Verification Process

**The shadow agent must:**

1. **Read the main agent's claim** — What does it say is done?
2. **Verify each deliverable independently**
   - File exists? → Check file listing
   - File has correct content? → Read the file
   - Functionality works? → Run the command
   - Tests pass? → Execute tests
3. **Check for gaps** — Are there missing pieces?
   - Primary deliverables complete?
   - Secondary deliverables complete?
   - Documentation complete?
   - Vault updated?
   - Cross-links present?
4. **Report findings** — Either:
   - ✅ "Verified complete" (sign off)
   - ❌ "Incomplete - gaps found" (detail gaps)

### Verification Template

```markdown
# Shadow Verification Report

**Task:** [What was claimed to be done]
**Claim:** [Main agent's summary]

## Verification Checklist

### Deliverable 1: [Name]
- [ ] File exists at [path]
- [ ] Content is correct
- [ ] Functionality verified
- Result: ✅ VERIFIED / ❌ MISSING / ❌ WRONG

### Deliverable 2: [Name]
...

## Gaps Found (if any)

- Gap 1: [Description]
- Gap 2: [Description]

## Sign-Off

Result: ✅ COMPLETE and verified
OR
Result: ❌ INCOMPLETE - requires fixes

Verified by: Shadow Agent
Date: YYYY-MM-DD
```

---

## Verification Checklist by Work Type

### Code Features/Fixes

```
✅ Code written
✅ Comments explain business logic + technical steps
✅ Tests written (100% of new code)
✅ Tests passing
✅ No lint/format warnings
✅ Daily work documented
✅ Vault updated with cross-links
✅ Related docs updated
✅ PR references daily work
```

### Testing Framework Components

```
✅ Configuration files created
✅ Test files created with content
✅ Scripts executable and working
✅ Documentation complete
✅ Examples provided and working
✅ Vault indexed
✅ README updated
✅ Cross-links added
```

### Documentation

```
✅ File exists at claimed location
✅ Content matches description
✅ Cross-links present
✅ Related docs linked back
✅ Vault index updated
✅ Examples (if applicable) present
✅ Templates (if applicable) provided
```

### Configurations & Setup

```
✅ Config file exists
✅ Config has correct values
✅ Is referenced in docs
✅ Is gitignored appropriately
✅ Examples provided
✅ Related docs reference it
```

---

## Sign-Off Format

### Main Agent Sign-Off

```markdown
# Task Complete: [Task Name]

**Status:** ✅ DONE (awaiting shadow verification)

**Deliverables:**
1. File: [path] - [description]
2. File: [path] - [description]
3. File: [path] - [description]

**Verification Steps:**
```bash
[command 1]  # Should output: [expected]
[command 2]  # Should output: [expected]
```

**Evidence:**
- [[Vault link to work]]
- [[Vault link to documentation]]

**Ready for:** Shadow verification
```

### Shadow Agent Sign-Off

```markdown
# Shadow Verification: [Task Name]

**Main Agent Claim:** ✅ Reviewed
**Deliverables:** ✅ All present
**Functionality:** ✅ Verified
**Documentation:** ✅ Complete
**Gaps:** ✅ None found

## Verification Summary

[1-2 sentence summary of what was verified]

**FINAL RESULT:** ✅ **VERIFIED COMPLETE**

Verified by: Shadow Agent
Date: YYYY-MM-DD
```

---

## Real-World Example: Local Coverage Tracking

### What Happened (Now Fixed)

**Main Agent Claim:** "Local coverage tracking is set up"  
**Shadow Agent Finding:** ❌ INCOMPLETE
- Missing: `.lcovrc` file
- Missing: `scripts/coverage.sh`
- Missing: Coverage configuration
- Missing: Local documentation

**Result:** Had to go back and create missing files

### This Won't Happen Again

**Main Agent Claim:** "Local coverage tracking is set up"

**Evidence:**
- `coverage/.lcovrc` — Configuration
- `scripts/coverage.sh` — Coverage script (8 commands)
- `coverage/README.md` — Documentation
- `COVERAGE_QUICK_REFERENCE.md` — Quick guide
- `coverage/.gitignore` — Git configuration

**Shadow Agent Verification:**
```bash
ls -la coverage/.lcovrc          # ✅ Exists
ls -la scripts/coverage.sh       # ✅ Exists
ls -la coverage/README.md        # ✅ Exists
./scripts/coverage.sh help       # ✅ Works
./scripts/coverage.sh            # ✅ Executes successfully
```

**Result:** ✅ VERIFIED COMPLETE

---

## Escalation Process

### If Shadow Agent Finds Gaps

1. **Shadow agent reports:** "Incomplete - gaps: [list]"
2. **Main agent fixes:** Completes missing deliverables
3. **Shadow agent re-verifies:** Confirms completion
4. **Sign-off:** Both confirm done

**This repeats until both sign off.**

### If There's a Dispute

1. **Document the disagreement** — What does each agent see?
2. **Escalate to user** — Show both perspectives
3. **User decides** — "Is this done or not?"
4. **Update processes** — Prevent dispute type in future

---

## Examples of Each Status

### ✅ VERIFIED COMPLETE

```
Main Agent: "I've created the testing framework"
Evidence: TESTING_STRATEGY.md, TEST_README.md, test fixtures, 
          CI workflow, local coverage script, all working

Shadow Agent Verification:
  ✅ All files exist
  ✅ All functionality works
  ✅ All documentation present
  ✅ Cross-links present
  ✅ No gaps found

Result: VERIFIED COMPLETE
```

### ❌ INCOMPLETE (Found Gaps)

```
Main Agent: "I've created the testing framework"
Evidence: TESTING_STRATEGY.md, TEST_README.md, test fixtures

Shadow Agent Verification:
  ✅ Documentation files exist
  ❌ Local coverage script missing
  ❌ CI workflow configuration missing
  ❌ Configuration file missing
  ❌ Coverage documentation missing

Result: INCOMPLETE - 4 gaps found. Return to main agent for completion.
```

---

## Responsibilities by Phase

### Planning Phase
- User: Define what "done" means
- Main agent: Plan deliverables
- Shadow agent: Review plan completeness

### Execution Phase
- Main agent: Implement deliverables
- Shadow agent: Observe (optional notes)
- Main agent: Test locally before claiming done

### Verification Phase
- Main agent: Provide evidence and sign-off
- Shadow agent: Independently verify each claim
- Result: Both sign off or gaps identified

### Completion Phase
- If gaps: Return to execution
- If complete: Task is DONE ✅

---

## Guidelines for Shadow Verification

### ✅ DO

- **Verify independently** — Don't just read the main agent's summary, check the actual files
- **Be thorough** — Check every claimed deliverable
- **Be specific** — Name exactly what works and what doesn't
- **Reference evidence** — Quote file paths, command outputs
- **Ask "is this done?"** — Not "could this be better?"
- **Use the checklist** — Follow the verification checklist for this work type

### ❌ DON'T

- **Trust the summary** — Verify the actual files
- **Miss small details** — A missing config file means "not done"
- **Be vague** — "This seems done" is not verification
- **Assume functionality** — Actually test/verify it works
- **Skip cross-links** — Vault integration must be complete
- **Accept "good enough"** — "Mostly done" = "not done"

---

## Integration with Directives

### CLAUDE.md Requirement
Every code change must have comprehensive comments (business logic + technical).

**Shadow Agent Verification:**
- [ ] Do comments explain business logic? ✅
- [ ] Do comments explain technical steps? ✅
- [ ] Can a non-programmer understand the code? ✅

### Daily Work Documentation
Every day's work documented in `Daily/YYYY-MM-DD/`.

**Shadow Agent Verification:**
- [ ] Does `Daily/YYYY-MM-DD/` folder exist? ✅
- [ ] Does SUMMARY.md exist? ✅
- [ ] Are Work/Tests/PRs populated? ✅
- [ ] Are cross-links present? ✅

### Vault Organization
All documents cross-linked.

**Shadow Agent Verification:**
- [ ] Is work linked from daily summary? ✅
- [ ] Are related docs linked? ✅
- [ ] Is vault index updated? ✅

---

## Automation & Tools

### Commands for Verification

```bash
# Verify file exists
ls -la [file path]

# Verify file content
grep "[text]" [file path]

# Verify command works
[command] --help

# Verify tests pass
flutter test [test path]

# Verify coverage
./scripts/coverage.sh compare

# Verify documentation
grep "[[" [doc file]  # Check for wikilinks
```

### Checklist Template

Create a verification checklist for each task type and reuse it.

---

## Binding Nature

### This is NOT Optional

- ✅ Every task requires shadow verification
- ✅ No task is done without sign-off from both agents
- ✅ Gaps found must be fixed
- ✅ Re-verification required after fixes

### Consequences of False Claims

- ❌ False "done" claims waste time and create technical debt
- ❌ Gaps discovered later are more expensive to fix
- ❌ User trust depends on verification rigor

**Therefore:** If either agent says "not done", it is NOT DONE.

---

## Real-World Workflow

### Example: Adding a Feature

```
Main Agent:
  1. Writes feature code
  2. Adds comments (business + technical)
  3. Writes tests (100% of code)
  4. Runs tests locally ✅
  5. Documents in Daily/YYYY-MM-DD/
  6. Adds vault cross-links
  7. Provides verification evidence
  8. Claims: "Feature is DONE"

Shadow Agent:
  1. Reads main agent claim
  2. Checks feature code exists ✅
  3. Reads comments (business logic present?) ✅
  4. Checks tests exist ✅
  5. Runs tests: "49/49 passing" ✅
  6. Checks daily documentation ✅
  7. Checks vault links ✅
  8. Verifies: "All deliverables present"
  9. Signs off: "VERIFIED COMPLETE"

Result: Feature is DONE ✅✅ (both agents confirmed)
```

---

## Shadow Agent Activation

**Effective Date:** 2026-07-20 (immediately)

**Initial Shadow Agent:** Deployed on all future work

**Scope:** 100% of MyBookLog development

**Escalation:** If disagreement, document for user review

---

## FAQ

**Q: Will this slow down development?**  
A: Verification is fast if work is actually done. It only slows down incomplete work.

**Q: What if the shadow agent is wrong?**  
A: User reviews the evidence and decides. Both perspectives documented.

**Q: Can we trust the shadow agent?**  
A: Shadow agent uses the same verification checklist. It's objective, not subjective.

**Q: What if both agents say "done" but it's actually not?**  
A: That's a process failure. Document it so the checklist improves.

---

## Summary

🔴 **This directive is BINDING and MANDATORY.**

✅ Every task requires independent verification  
✅ Both agents must sign off  
✅ No task is "done" until verified  
✅ Gaps found require fixes + re-verification  
✅ If either agent says "not done", it IS NOT DONE  

**This prevents incomplete work from being marked as done.**

---

*Established: 2026-07-20*  
*Status: ACTIVE*  
*Applies to: All MyBookLog development*
