# Phase 1 Migration Notes

## Path Changes

| Type | Before | After |
|---|---|---|
| Folder | `References/` (top-level, personal vault only) | `Knowledge/References/` |
| Folder | `Meetings/[Series]/` | `Meetings/Series/[Series]/` |
| Folder | (did not exist) | `Meetings/Single/` |

## New Scaffold Paths

The following paths are now created by `scaffold-vault.sh` that were not created before:

- `Work/<Company>/Meetings/Series/` — created for both personal and work profiles
- `Work/<Company>/Meetings/Single/` — created for both personal and work profiles
- `Knowledge/References/` — created for personal profile only (replaces top-level `References/`)

The following path is no longer created:

- `References/` (top-level) — replaced by `Knowledge/References/` in the personal profile

## Affected Scripts

### `scaffold-vault.sh`

- **Meetings dirs array:** Added `"Work/$COMPANY/Meetings/Series"` and `"Work/$COMPANY/Meetings/Single"` alongside the existing `"Work/$COMPANY/Meetings/1on1s"`.
- **Personal profile dirs:** Changed `"References"` → `"Knowledge/References"`.
- **Obsidian `app.json` `attachmentFolderPath`:** Changed `"References"` → `"Knowledge/References"` for personal profile.
- **Script copy block:** Added `new-standalone-meeting.sh` alongside existing script copies.
- **Work profile summary warning:** Updated from "Northstar/, Life/, and References/ were not created" to "Northstar/, Life/, and top-level Knowledge/ were not created" to reflect the new structure.

### `new-meeting-series.sh`

- **`SERIES_DIR` (was line 99):** Changed `"$MEETINGS_DIR/$SERIES"` → `"$MEETINGS_DIR/Series/$SERIES"`.
- **Series listing loop (was lines 85–88):** Changed `"$MEETINGS_DIR"/*/` iteration with `1on1s` skip guard → `"$MEETINGS_DIR/Series"/*/` iteration (no skip guard needed).
- **Inline usage comment:** Updated to reflect all supported flags and the new path.

### `new-1on1.sh`

- **Path verified unchanged:** `ONEONS_DIR="$VAULT/Work/$CURRENT_COMPANY/Meetings/1on1s"` — no code change.
- **Inline usage comment:** Updated to reflect all supported flags.

## Wikilink Assumption

All Meridian wikilinks use shortest-path format (e.g., `[[Series Name YYYY-MM-DD]]`, not `[[Meetings/Series/Series Name/YYYY-MM-DD/Series Name YYYY-MM-DD]]`). Moving series folders from `Meetings/[Series]/` to `Meetings/Series/[Series]/` does **not** break existing backlinks as long as filenames are unchanged — Obsidian resolves wikilinks by filename, not full path. Users with non-standard full-path wikilinks will need to repair those manually.

## Deviations from Spec

### Shell Commands plugin entry (spec section: "Shell Commands Plugin Entry")

The spec says: "In `scaffold-vault.sh`, find where the `.obsidian/shell-commands.json` (or equivalent config) is written and add an entry for **New Meeting**."

**Deviation:** `scaffold-vault.sh` does not write `.obsidian/shell-commands.json`. The Shell Commands plugin configuration in Meridian is set up manually by the user following the step-by-step instructions in `src/documentation/User Setup.md` (Shell Commands section). There is no programmatic config written at scaffold time.

**Resolution for Phase 2:** Phase 2 (documentation) must add a "Command 6: New Meeting" entry to the Shell Commands section of `User Setup.md`, following the same pattern as Commands 2–5. This is already called out in the Phase 2 spec.

**Resolution for Phase 3:** No migration script action required — the Shell Commands plugin config is user-managed and not part of the vault scaffold.
