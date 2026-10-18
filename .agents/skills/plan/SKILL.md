---
name: plan
description: >-
  Use at the start of any feature, bug fix, or refactor, before writing code.
  Produces a short plan covering goal, per-file impact (change type and symbols
  touched), what could break, approach, and test plan, then waits for approval.
  Also use when asked to compare several agents' plans to decide what can run in
  parallel.
---

# Plan

## Steps

1. Read `AGENTS.md`, then `docs/progress.md` (especially *Known gotchas*), then
   **every fragment in `docs/changes/`** (newer gotchas and impact rows may only
   be there), then the relevant parts of `docs/architecture.md`.
2. Restate the **goal and intent** in 1–2 sentences. If anything is ambiguous, ask.
3. **Impact analysis.** This is the step that prevents "fixing X breaks Y".
   - List every file you expect to change, with:
     - **change:** `add` (new file, or appending to a list/section),
       `modify` (changing an existing function or section), or
       `restructure` (rename, move, delete, signature change, rewrite);
     - **symbols:** functions, classes, components; for HTML/CSS/Markdown, the
       section or heading;
     - **size:** S (<20 lines), M (20–100), L (>100).
   - For each one, search the codebase for callers and dependents.
   - Check the *Change impact map* (and fragments) for matching rows.
   - List what could break and which tests cover it. Flag anything with no test coverage.
   - Set **confidence** (high / medium / low) in the file list. Be honest.
4. **Approach.** Ordered steps. For non-trivial work, note alternatives and why you rejected them.
5. **Test plan.** Existing tests that must keep passing, plus new tests to add.
6. If this is a structural decision (dependency, data model, framework, new
   pattern), draft an ADR as `docs/adr/XXXX-short-title.md` from the template.
7. Present the plan. **Wait for approval** before building unless the task is trivial.

## Output format

```markdown
**Goal:** …
**Changes:** (confidence: high | medium | low)
| File | Change | Symbols / sections | Size |
| ---- | ------ | ------------------ | ---- |
| src/… | modify | `parseOrder` | S |
**Depends on:** none | other task/branch
**Could break:** item (covered by test X | NOT covered)
**Approach:** 1. … 2. …
**Tests:** keep passing … / add …
**ADR:** none | drafted XXXX-…
```

## Comparing plans (parallel work)

When several agents have planned, compare every pair of plans. Two tasks run
**one after the other** (in separate waves) if any of these is true:

1. They share a **protected file**: lockfile, project/build file, migration,
   shared config, or `AGENTS.md`.
2. Either one **restructures** a file the other touches.
3. Both **modify the same symbol** or section.
4. One **depends on** the other's output.
5. Either plan has **low confidence** and they share any file.
6. Both make **L-sized** edits to the same file.

Otherwise they run **in parallel**. Both adding to the same place (two new nav
links, two new routes) is fine: the `merge` skill keeps both.

Put the heavier or structural task in the earlier wave. Output:

```markdown
**Wave 1 (parallel):** task-a, task-b
**Wave 2:** task-c (after task-a: both modify `router.js` -> `routes`)
```

If an agent later needs a file that isn't in its plan, it adds it to the plan and
tells the human, who decides whether to keep it in the current wave.
