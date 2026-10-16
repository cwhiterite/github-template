# Project Template

A lightweight, stack-agnostic starting point for solo projects built with AI agents
(Antigravity, OpenCode, VS Code). No servers or databases are needed for the
workflow itself. Everything is markdown, git, and GitHub.

## What's in it

| Path | Purpose |
| ---- | ------- |
| `AGENTS.md` | Agent onboarding: stack, commands, hard rules. Read automatically by most agent tools. |
| `docs/progress.md` | Current state, next steps, known gotchas, log. |
| `docs/architecture.md` | Components, key flows (Mermaid), **change impact map**. |
| `docs/adr/` | Architecture Decision Records. |
| `.agents/skills/` | Workflow: `plan` → `build` → `review` → `sync-docs`. |
| `.github/` | PR and issue templates that mirror the workflow. |
| `scripts/agent-worktree.ps1` | Isolated worktree and branch per agent, for parallel work. |

## Starting a new project from this template

1. Copy the folder, or mark the GitHub repo as a **Template repository** and use
   "Use this template".
2. Find every placeholder and fill it in:
   ```powershell
   git grep -n "TODO(project)"
   ```
3. Write ADR `0001` for your stack/database choice.
4. Protect `main` on GitHub (Settings → Branches → require PR before merging).
5. Optional: create a GitHub Projects board linked to the repo as your kanban.

## Day-to-day

- **One agent:** Open the repo and ask it to plan an issue. It follows the skills.
- **Two or three agents:** Run `.\scripts\agent-worktree.ps1 -Name <issue#>-<name>`
  once per agent and open each worktree in its own window. Each agent opens a PR,
  and you review and merge.
- **Review with a second agent:** Ask a separate agent to run the `review` skill on the PR.

## When to outgrow this

Add heavier tooling (a code graph, a custom orchestrator) only if agents keep
missing context **even with** an up-to-date impact map and a passing test suite.
