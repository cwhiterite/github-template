---
name: consolidate-docs
description: >-
  Use when asked to consolidate, fold in, or clean up doc fragments, or after the
  merge queue is empty. Moves merged fragments from docs/changes/ into the master
  docs (progress, architecture, ADR index), numbers draft ADRs, deletes the
  fragments, and opens one PR for the human to merge.
---

# Consolidate docs

Safe to run while other agents are working: their branches only **add** new
fragment files, and this skill only edits master docs and deletes fragments that
are already on `main`.

## Steps

1. **Start from fresh main on a new branch:**
   ```powershell
   git switch main
   git pull
   git switch -c agent/consolidate-docs-YYYY-MM-DD
   ```
2. **Collect fragments:** every file in `docs/changes/` except `README.md` and
   `_template.md`. Order them oldest first by their *Log* date. Nothing to
   consolidate -> stop and say so.
3. **Fold each section into its master doc.** Keep it terse; merge duplicates.
   | Fragment section | Goes to |
   | ---------------- | ------- |
   | Log | `docs/progress.md` *Log* (newest first) |
   | Status | `docs/progress.md` *In progress / broken* |
   | Known gotchas | `docs/progress.md` *Known gotchas* |
   | Impact map rows | `docs/architecture.md` *Change impact map* |
   | Architecture updates | `docs/architecture.md` modules / diagrams / data. Check the code if a note is unclear. |
   | ADRs drafted | Rename `XXXX-…` to the next free number, set the title number, add to `docs/adr/README.md` |
   | AGENTS.md proposals | **Don't apply.** List them in the PR description for the human. |
4. **Refresh** *Current state* and *Next steps* in `docs/progress.md` from the
   whole picture. Trim old *Log* entries that are captured in an ADR or no longer matter.
5. **Delete** the consumed fragments with `git rm`.
6. **Commit and open a PR:**
   ```powershell
   git add -A docs
   git commit -m "docs: consolidate fragments"
   git push -u origin HEAD
   gh pr create --fill
   ```
   Tell the human the PR is ready, including any AGENTS.md proposals to decide on.
