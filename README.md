# Project Template

A lightweight, stack-agnostic starting point for solo projects built with AI agents
(Antigravity, OpenCode, VS Code). No servers or databases are needed for the
workflow itself. Everything is markdown, git, and GitHub.

## What's in it

| Path | Purpose |
| ---- | ------- |
| `AGENTS.md` | Agent onboarding: stack, commands, hard rules. Read automatically by most agent tools. |
| `docs/progress.md` | Current state, next steps, known gotchas, log. |
| `docs/changes/` | Per-branch doc fragments, so parallel PRs don't conflict on docs. |
| `docs/architecture.md` | Components, key flows (Mermaid), **change impact map**. |
| `docs/workflow.md` | One-agent and parallel-agent workflow, with diagram. |
| `docs/adr/` | Architecture Decision Records. |
| `.agents/skills/` | `plan` -> `build` -> `review` -> `sync-docs`, plus `merge` and `consolidate-docs`. |
| `.github/` | PR and issue templates that mirror the workflow, plus `guard.yml` (shared-docs check) and `ci.yml` (runs `scripts/test.ps1`). |
| `scripts/` | Helper scripts: `agent-worktree.ps1` (worktrees), `merge-pr.ps1` (1-step PR merge & cleanup), `protect-main.ps1` (branch protection + required check). |

## Starting a new project from this template

1. Copy the folder, or mark the GitHub repo as a **Template repository** and use
   "Use this template".
2. Find every placeholder and fill it in:
   ```powershell
   git grep -n "TODO(project)"
   ```
3. Delete the marker file. This repo is now a project, so `AGENTS.md` rule 7's
   shared-docs exception no longer applies and `.github/workflows/guard.yml`
   starts enforcing it:
   ```powershell
   Remove-Item .is-template
   ```
4. Create `scripts/test.ps1` with a single line — whatever your stack runs
   (`pytest`, `npm test`, `go test ./...`, `dotnet test`, …). It is the single
   source of truth for the test command: `.github/workflows/ci.yml` executes it,
   and the *Test (all)* row in `AGENTS.md` points at it, so agents and CI can't
   drift apart. Until the file exists, the `tests` check passes with a warning
   instead of running anything — it never goes green for tests that didn't happen.
5. Write ADR `0002` for your stack/database choice (`0001` is the workflow itself).
6. Protect `main` — requires a pull request, **zero** approving reviews, and both
   `Shared docs guard` and `tests`:
   ```powershell
   .\scripts\protect-main.ps1        # add -WhatIf to preview, -Remove to undo
   ```
   Zero approvals is deliberate: GitHub forbids authors from approving their own
   pull requests, so requiring one approval would deadlock a solo repo. Manual
   alternative: Settings -> Branches -> Add a branch protection rule.
7. Optional: create a GitHub Projects board linked to the repo as your kanban.
8. **Status single source of truth:** Keep roadmap and current state exclusively in `docs/progress.md`; link to it from `README.md` rather than duplicating status tables to avoid status drift.

> **Auth gotcha:** pushing anything under `.github/workflows/` is rejected with
> *"…without `workflow` scope"* until you grant it once:
> `gh auth refresh -h github.com -s workflow`

## Day-to-day

- **One agent:** Open the repo and ask it to plan an issue. It follows the skills.
- **Two or three agents:** Run `.\scripts\agent-worktree.ps1 -Name <issue#>-<name>`
  once per agent and open each worktree in its own window. Have each agent plan,
  then ask one agent to compare the plans and split them into waves. Each agent
  opens a PR; a `merge` agent prepares them one at a time; you merge (or run `.\scripts\merge-pr.ps1 <number>`).
  Full flow: [`docs/workflow.md`](docs/workflow.md).
- **Docs:** Run `consolidate-docs` now and then to fold `docs/changes/` into the master docs.
- **Review with a second agent:** Ask a separate agent to run the `review` skill on the PR.

## When to outgrow this

Add heavier tooling (a code graph, a custom orchestrator) only if agents keep
missing context **even with** an up-to-date impact map and a passing test suite.
