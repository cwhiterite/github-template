# AGENTS.md

> Read this first. It is the minimum context needed to work in this repo.
> Keep it under ~150 lines. Details belong in `docs/`.

## Project

<!-- TODO(project): One paragraph. What is this, who is it for, what phase is it in? -->

## Stack

<!-- TODO(project): Language(s), framework, database, test runner, package manager. -->

## Commands

| Task             | Command                    |
| ---------------- | -------------------------- |
| Install          | <!-- TODO(project) -->     |
| Run              | <!-- TODO(project) -->     |
| Test (all)       | <!-- TODO(project) -->     |
| Test (one file)  | <!-- TODO(project) -->     |
| Lint / format    | <!-- TODO(project) -->     |

## Where things live

| Path                     | What                                                        |
| ------------------------ | ----------------------------------------------------------- |
| `docs/progress.md`       | Current state, next steps, **known gotchas**. Read first.   |
| `docs/architecture.md`   | Structure, key flows, **change impact map**.                |
| `docs/adr/`              | Decisions and the reasoning behind them.                    |
| `.agents/skills/`        | Workflow steps: `plan`, `build`, `review`, `sync-docs`.     |
| `scripts/`               | Helper scripts (e.g. `agent-worktree.ps1`).                 |
| <!-- TODO(project) -->   | Source code                                                 |
| <!-- TODO(project) -->   | Tests                                                       |

## Workflow

Every task follows: **plan → build (incl. tests) → review → sync-docs**.

Each step is a skill at `.agents/skills/<name>/SKILL.md`. If your tool does not
load skills automatically, open and follow the file directly.

## Hard rules

1. **Never commit to `main`.** Work on `agent/<issue#>-<short-name>`. A human merges via PR.
2. **Check impact before editing.** Before changing a function, module, schema, or
   interface: search for its callers and check the *Change impact map* in
   `docs/architecture.md`.
3. **Every bug fix gets a regression test** that fails before the fix and passes after.
4. **Run the full test suite**, not just new tests, before calling anything done.
5. **Max 3 fix attempts** on a failing test. Then stop, summarize what you tried, and ask.
6. **Don't undo a previous fix** without checking *Known gotchas* in `docs/progress.md`.
   If you're about to reverse earlier behavior, say so explicitly.
7. **Sync docs** (`sync-docs` skill) before ending any turn that changed code.
8. **No new dependencies** without stating why. Structural choices get an ADR.

## Conventions

<!-- TODO(project): Naming, formatting, error handling, logging, folder layout, etc. -->
