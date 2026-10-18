---
name: merge
description: >-
  Use when a PR or agent branch is behind main or has merge conflicts, or when
  asked to work through the merge queue of parallel agent PRs. Brings one branch
  at a time up to date with main, resolves only additive conflicts, runs the full
  test suite, and pushes. Never merges into main itself; the human clicks Merge.
---

# Merge (one PR at a time)

## Never

- Push to `main`, force-push, or rebase.
- Merge a PR yourself (`gh pr merge`, GitHub button) unless the human explicitly says so.
- Guess at a conflict. If unsure, abort and report.

## Steps

1. **Pick the order.** `gh pr list`. Use the order the human gives; otherwise the
   plan's wave order, then oldest first. Work on **one** PR at a time.
2. **Find where the branch lives.** `git worktree list`. If the branch is checked
   out in a worktree, run every command there (`git -C <path> …` or open it).
   Git won't check out one branch in two folders.
3. **Bring it up to date:**
   ```powershell
   git fetch origin
   git merge origin/main
   ```
   No conflicts -> go to step 5.
4. **Resolve conflicts.** Before choosing anything, check *Known gotchas* in
   `docs/progress.md` and `docs/changes/` so you don't undo an earlier fix.
   - **Additive** (both sides added lines, e.g. two new routes or list items):
     keep both, in a sensible order.
   - **Lockfiles:** take main's version (`git checkout --theirs <file>`), then
     re-run the install command from `AGENTS.md` to regenerate it.
   - **Logic** (both sides changed the same code differently) **or unsure:**
     `git merge --abort`, then report to the human: the files, what each side
     intended, and a suggested resolution. Stop here for this PR.
   - When done: `git add <files>` then `git commit --no-edit`.
5. **Verify.** Run the full test suite and lint (commands in `AGENTS.md`). If
   something fails and the cause isn't clearly your conflict resolution, don't fix
   feature logic here: report it and send the PR back to its owner.
6. **Push** with a normal `git push`. The PR updates itself.
7. **Report:** "PR #N is up to date with main, tests pass, conflicts resolved:
   … Ready for you to merge." Wait for the human to merge it.
8. **Next PR.** After each merge, `main` has moved, so repeat from step 2 for the
   next PR.

## After the queue is empty

- Suggest running `consolidate-docs`.
- Clean up each merged worktree and branch:
  ```powershell
  .\scripts\agent-worktree.ps1 -Name <name> -Remove
  git branch -d agent/<name>
  ```
