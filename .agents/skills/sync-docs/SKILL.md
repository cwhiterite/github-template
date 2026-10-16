---
name: sync-docs
description: >-
  Use at the end of any turn that changed code, before finishing. Updates
  architecture, progress, impact map, and ADRs so the next agent (or human)
  can onboard from docs instead of re-reading code.
---

# Sync docs

Keep every edit terse. These docs exist to save tokens and time, so don't pad them.

## Steps

1. Run `git diff` (and `git status` for new files) to see what changed this turn.
2. **`docs/architecture.md`**
   - Modules table: add, remove, or rename rows if structure changed.
   - Diagrams: update the component diagram or key flows if a call chain changed.
   - **Change impact map:** add a row for any coupling you discovered,
     **especially if a change broke something elsewhere** during this turn.
3. **`docs/progress.md`**
   - Update *Current state* and *Next steps*.
   - Add a *Log* entry (date, did, decided, broke/fixed, next).
   - Add a *Known gotcha* if a bug took more than one attempt or a fix reversed earlier behavior.
4. **`docs/adr/`:** If a structural decision was made, write the ADR and add it to the index.
5. **`AGENTS.md`:** Update only if commands, stack, paths, or rules changed. Keep it short.

## Done when

A fresh agent reading only `AGENTS.md` and `docs/` would know what changed,
why, what's next, and what not to break.
