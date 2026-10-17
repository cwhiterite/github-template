# Doc fragments

Feature branches **never edit shared docs** (`docs/progress.md`, `docs/architecture.md`,
`docs/adr/README.md`, `AGENTS.md`). Instead, each branch writes **one** file here:

```text
docs/changes/<branch-name-without-agent/>.md     e.g. docs/changes/42-login-form.md
```

Copy [`_template.md`](_template.md), fill in only the sections that apply, and delete
the rest. Update the same file on later turns in the same branch.

- **New files never conflict**, so parallel PRs stop colliding on docs.
- **Agents read these too.** Until `consolidate-docs` runs, the latest gotchas and
  impact-map rows may only exist here.
- **`consolidate-docs`** folds merged fragments into the master docs through its own
  PR and deletes them. It never touches `README.md` or `_template.md`.

See [ADR 0001](../adr/0001-parallel-agents-workflow.md) for the reasoning.
