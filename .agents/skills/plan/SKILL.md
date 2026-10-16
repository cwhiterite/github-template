---
name: plan
description: >-
  Use at the start of any feature, bug fix, or refactor, before writing code.
  Produces a short plan covering goal, impact analysis (what could break),
  approach, and test plan, then waits for approval.
---

# Plan

## Steps

1. Read `AGENTS.md`, then `docs/progress.md` (especially *Known gotchas*), then
   the relevant parts of `docs/architecture.md`.
2. Restate the **goal and intent** in 1–2 sentences. If anything is ambiguous, ask.
3. **Impact analysis.** This is the step that prevents "fixing X breaks Y".
   - List the files/functions you expect to change.
   - For each one, search the codebase for callers and dependents.
   - Check the *Change impact map* for matching rows.
   - List what could break and which tests cover it. Flag anything with no test coverage.
4. **Approach.** Ordered steps. For non-trivial work, note alternatives and why you rejected them.
5. **Test plan.** Existing tests that must keep passing, plus new tests to add.
6. If this is a structural decision (dependency, data model, framework, new
   pattern), draft an ADR in `docs/adr/` from the template.
7. Present the plan. **Wait for approval** before building unless the task is trivial.

## Output format

```markdown
**Goal:** …
**Changes:** file/function list
**Could break:** item (covered by test X | NOT covered)
**Approach:** 1. … 2. …
**Tests:** keep passing … / add …
**ADR:** none | drafted NNNN-…
```
