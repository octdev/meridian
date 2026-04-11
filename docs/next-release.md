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

_None pending._

---

## Release checklist reminder

When cutting the release, complete all items in the checklist at the bottom of
`src/documentation/Upgrades.md` — then delete the relevant entries above.
