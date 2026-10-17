---
name: review
description: >-
  Use to review code changes before a PR is merged, or when asked for a code
  review. Checks correctness, test coverage, impact, standards, scaling, and
  security, and reports findings by severity. Works on a local diff or a PR.
---

# Review

## Get the diff

- Local branch: `git diff main...HEAD`
- GitHub PR: `gh pr diff <number>`

Read `AGENTS.md` (conventions), the *Change impact map* in `docs/architecture.md`,
and any impact rows or gotchas in `docs/changes/`.

## Checklist

1. **Correctness:** Does the change do what the plan/issue asked? Are edge cases handled?
2. **Tests:** Is new behavior tested? Does a bug fix have a regression test? Does the full suite pass?
3. **Impact:** For each changed function/interface, were callers updated?
   Are the matching impact-map rows respected? Is there new coupling that needs a row?
4. **Standards:** Does it follow the conventions in `AGENTS.md`? Naming, structure, error handling.
5. **Scaling:** Any N+1 queries, unbounded loops or loads, or full-table scans
   that will hurt at the expected scale?
6. **Security:** Hardcoded secrets? Unparameterized SQL? Unvalidated input?
7. **Docs:** Is there a fragment `docs/changes/<branch>.md` (sync-docs)? Shared docs
   (`progress.md`, `architecture.md`, ADR index, `AGENTS.md`) must **not** be edited
   directly on a feature branch. Exception: a `consolidate-docs` PR.
8. **Improvements:** Optional ideas. **List them only; don't implement.**

## Output format

```markdown
### Must fix
- file:line — issue — suggested fix
### Should fix
- …
### Nice to have
- …
### Verdict: approve | changes requested
```
