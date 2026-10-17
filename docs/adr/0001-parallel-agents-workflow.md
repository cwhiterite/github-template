# 0001: Parallel agents: worktrees, doc fragments, one-at-a-time merges

- **Status:** Accepted
- **Date:** 2026-10-16

## Context

We want 2–3 agents working at the same time. Three things go wrong without rules:

1. **Shared checkout.** Agents in one folder overwrite each other's files and switch
   branches under each other.
2. **Shared docs.** Every agent's `sync-docs` step edited the same sections of
   `docs/progress.md` and `docs/architecture.md`, so nearly every PR conflicted.
3. **Overlapping code.** An agent only learns which files it needs after reading the
   request and the code, so overlap can't be fully prevented, only made cheap.

Constraints: solo developer, learning git; a human approves every merge
(`AGENTS.md` rule 1, branch protection on `main`); no servers or extra tooling.

## Decision

- **Isolation:** one git worktree and branch per agent (`scripts/agent-worktree.ps1`),
  branched from a freshly fetched `origin/main`.
- **Overlap check:** the `plan` skill lists each file with a change type
  (`add` / `modify` / `restructure`) and the functions/sections touched. Plans are
  compared with a checklist; overlapping tasks run in waves, the rest in parallel.
- **Doc fragments:** feature branches never edit shared docs. Each branch writes one
  file, `docs/changes/<branch>.md`. The `consolidate-docs` skill folds merged
  fragments into the master docs through its own PR, whenever the human chooses.
- **Merge queue:** the `merge` skill brings one PR at a time up to date by merging
  `origin/main` into it, resolves only additive conflicts, runs the full suite, and
  pushes. The human clicks Merge. Then the next PR.

## Options considered

| Option | Pros | Cons |
| ------ | ---- | ---- |
| One fragment file per branch, with a section per target doc (**chosen**) | One file per agent; can't conflict; easy to read | Consolidator has to route sections to the right doc |
| Folder per doc (`docs/progress/`) holding a master plus per-agent files | Very explicit | 2–4 new files per branch; moves existing docs and breaks links |
| Agents edit shared docs, resolve conflicts at merge | No new process | Conflict on nearly every PR |
| Rebase branches onto `main` | Linear history | Rewrites history; needs force-push; easy to get wrong while learning |
| Merge `origin/main` into the branch (**chosen**) | Same conflicts caught; no force-push; GitHub "Update branch" does it too | Extra merge commits in history |
| Scheduler script reading JSON plan manifests | Automatic wave planning | Overkill for 2–3 agents; more to maintain; revisit if orchestration is automated |
| Merge agent merges to `main` itself | Fully hands-off | Breaks rule 1 and branch protection |

## Consequences

- Easier: parallel PRs no longer conflict on docs; conflicts are handled one PR at a
  time; every merge is still approved by a human.
- Harder: master docs lag behind until `consolidate-docs` runs, so agents must read
  `docs/changes/` as well (the `plan` skill says so). ADR numbers are assigned at
  consolidation (drafts are named `XXXX-title.md`) to avoid two branches taking the
  same number.
- Revisit if: more than ~3 agents run at once, orchestration becomes automated (then
  consider the scheduler script), or a merge queue/CI is added on GitHub.
