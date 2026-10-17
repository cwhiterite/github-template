---
name: build
description: >-
  Use after a plan is approved to implement code changes and tests. Covers
  branch safety, test-first for bug fixes, running the full suite, and the
  3-attempt limit on failing tests.
---

# Build (and test)

## Steps

1. **Branch check.** Run `git branch --show-current`. If you're on `main`, create
   `agent/<issue#>-<short-name>` first. Never commit to `main`.
   - In a parallel worktree, work **only inside that folder**.
   - If `main` has moved since you planned (e.g. you waited for an earlier wave),
     run `git fetch origin` and `git merge origin/main` before editing.
2. **Tests first where it matters.**
   - Bug fix: write a test that reproduces the bug and **fails**. Confirm it fails.
   - Feature: add or extend tests for the new behavior.
3. **Implement** the smallest change that satisfies the plan. Don't make unrelated edits.
   If you find you need to change something the plan didn't list, stop and update the plan.
4. **Run the full test suite** (command in `AGENTS.md`), not just the new tests.
   This is how you catch "changing X broke Y".
5. **On failure:** fix and re-run, **up to 3 attempts**. If it still fails, stop. Then:
   - summarize what you tried and what you think the cause is,
   - add a note under *Status* in your fragment `docs/changes/<branch>.md`,
   - ask the human.
6. Run lint/format (command in `AGENTS.md`).
7. **Commit** only if the user asked you to or you're working in an agent
   worktree. Message format: `<type>: <summary> (#issue)` where type is
   `feat|fix|refactor|test|docs|chore`.

## Done when

- All tests pass (full suite, not a subset).
- Lint is clean.
- You can name the test that guards each item from the plan's *Could break* list.
