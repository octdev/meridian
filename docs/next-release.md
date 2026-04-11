# Next Release — Migration Notes

Accumulates vault-structural changes made during development that will require
migration script entries in the next release. Clear this file after cutting the
release and creating the migration scripts.

Format mirrors the migration script structure (global vs. per-company) so
entries can be copied directly into `scripts/upgrade/migrations/vX.Y.Z.sh`.
See `src/documentation/Upgrades.md` — Writing Upgrade Scripts for the script
template and rules.

---

## Pending migrations

### Global changes
_(Changes to vault-wide structure: Process/, templates, .obsidian config, .scripts/)_

_None pending._

### Per-company changes
_(Changes inside Work/[Company]/: new subfolders, new seed files)_

**Move Current Priorities.md from Process/ to Work/[Company]/Goals/**

- Source: `Process/Current Priorities.md`
- Destination: `Work/[Company]/Goals/Current Priorities.md`
- Action: if `Process/Current Priorities.md` exists, move it to
  `Work/$COMPANY/Goals/Current Priorities.md` (use `mv`, skip if destination
  already exists). If `Work/$COMPANY/Goals/` does not exist, create it first.
- Note: if the user has content in `Process/Current Priorities.md`, it must be
  preserved — this is not a copy_if_new, it is a move. Warn the user to review
  after migration.

---

## Release checklist reminder

When cutting the release, complete all items in the checklist at the bottom of
`src/documentation/Upgrades.md` — then delete the relevant entries above.
