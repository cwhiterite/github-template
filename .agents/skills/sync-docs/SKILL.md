---
name: sync-docs
description: >-
  Use at the end of any turn that changed code, before finishing. Records what
  changed in this branch's doc fragment (docs/changes/<branch>.md): log, gotchas,
  impact-map rows, architecture updates, ADR drafts. Never edits shared docs
  directly, so parallel branches don't conflict.
---

# Sync docs

Keep every edit terse. These docs exist to save tokens and time, so don't pad them.

## Rule

On a feature branch, **write only to your fragment**: `docs/changes/<branch>.md`,
where `<branch>` is the branch name without `agent/` (e.g. `42-login-form`).
Do **not** edit `docs/progress.md`, `docs/architecture.md`, `docs/adr/README.md`,
or `AGENTS.md`. The `consolidate-docs` skill moves fragments into those files later.

## Steps

1. Run `git diff main...HEAD` and `git status` to see what this branch changed.
2. If your fragment doesn't exist, copy `docs/changes/_template.md` to it.
   If it does, update it (same branch, later turn). Delete sections that don't apply.
3. Fill in:
   - **Log:** date, did, decided, broke/fixed, next.
   - **Status:** only if something is left broken or blocked.
   - **Known gotchas:** if a bug took more than one attempt or a fix reversed earlier behavior.
   - **Impact map rows:** any coupling you discovered, **especially if a change
     broke something elsewhere** during this branch.
   - **Architecture updates:** modules added/removed/renamed, changed call chains
     or data, precise enough for someone to update the table or diagram.
   - **ADRs drafted:** any `docs/adr/XXXX-short-title.md` you wrote.
   - **AGENTS.md proposals:** commands, stack, paths, or rules that should change.

## Done when

A fresh agent reading `AGENTS.md`, `docs/`, and `docs/changes/` would know what
changed, why, what's next, and what not to break.
