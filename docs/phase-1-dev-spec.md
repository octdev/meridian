# Phase 1 — Development Spec

**Audience:** Developer implementing vault structure changes and new script.
**Depends on:** Nothing — this is the first phase.
**Feeds into:** Phase 2 (documentation) and Phase 3 (integration/migration scripts).

---

## Context

Meridian is a personal knowledge management system built on Obsidian. It consists of a scaffold script that creates a vault folder structure, a set of utility scripts for ongoing vault management, and documentation distributed into the vault at setup time. See `src/documentation/Architecture.md` for full system context.

This phase implements two structural changes to the vault layout and adds one new script. It does **not** update user documentation — that is Phase 2's responsibility. If any implementation decision deviates from this spec, the implementor must document the deviation in a callout section of `docs/phase-1-migration-notes.md` so Phase 2 and Phase 3 implementors are aware.

---

## What Phase 1 Does NOT Do

- Does not update `src/documentation/` files (User Handbook, Architecture, Reference Guide, User Setup)
- Does not update `meridian-system.html` or `README.md`
- Does not write upgrade migration scripts (that is Phase 3)
- Does not update test scripts (that is Phase 3)
- Does not bump the version (that is Phase 3)

---

## Structural Changes

### Change 1 — References moves under Knowledge

**Before:**
```
vault/
  Knowledge/       Technical/ · Leadership/ · Industry/ · General/
  References/
```

**After:**
```
vault/
  Knowledge/       Technical/ · Leadership/ · Industry/ · General/
                   References/
```

`References/` becomes an unstructured subfolder of `Knowledge/`. No subfolders are created inside `References/` — it remains a flat bucket.

This applies to the **personal vault only**. The work vault (`--profile work`) does not include `Knowledge/` or `References/` and is unchanged.

---

### Change 2 — Meetings subfolders restructured

**Before:**
```
Meetings/
  1on1s/
  [Series Name]/
    [Series Name].md
    YYYY-MM-DD/
      [Series Name] YYYY-MM-DD.md
```

**After:**
```
Meetings/
  1on1s/
  Series/
    [Series Name]/
      [Series Name].md
      YYYY-MM-DD/
        [Series Name] YYYY-MM-DD.md
  Single/
```

- `1on1s/` path is unchanged
- Series folders move one level deeper under `Series/`
- `Single/` is a new empty folder for standalone one-off meeting notes (created by the new `new-standalone-meeting.sh` script)

This applies to **both personal and work vaults**.

---

## Files to Modify

### `src/bin/scaffold-vault.sh`

Two changes required:

**1. Replace `References/` creation with `Knowledge/References/`**

Search for the block that creates the top-level `References/` folder. Change it to create `Knowledge/References/` instead. It should be created as part of the `Knowledge/` folder block, after `Knowledge/General/`.

The folder must be created with the same `mkdir -p` pattern used for other vault directories. No seed files are placed inside it.

**2. Replace Meetings folder creation**

Search for the block that creates `Meetings/1on1s/`. Replace it with:

```bash
mkdir -p "$VAULT_DIR/Work/$COMPANY/Meetings/1on1s"
mkdir -p "$VAULT_DIR/Work/$COMPANY/Meetings/Series"
mkdir -p "$VAULT_DIR/Work/$COMPANY/Meetings/Single"
```

The same change applies to both the personal and work profile branches if they are handled separately.

---

### `src/bin/new-meeting-series.sh`

Two changes required:

**1. Update `SERIES_DIR` path construction (line ~99)**

```bash
# Before
SERIES_DIR="$MEETINGS_DIR/$SERIES"

# After
SERIES_DIR="$MEETINGS_DIR/Series/$SERIES"
```

**2. Update the existing-series listing (lines ~84–88)**

The interactive prompt that lists existing series currently iterates `"$MEETINGS_DIR"/*/` and skips `1on1s/`. After this change, series live at `$MEETINGS_DIR/Series/`. Update to iterate `"$MEETINGS_DIR/Series"/*/` and remove the `1on1s` skip guard (no longer needed since `1on1s` is not a peer of series):

```bash
# Before
for d in "$MEETINGS_DIR"/*/; do
  [[ "$d" == *"1on1s/"* ]] && continue
  [[ -d "$d" ]] && _detail "  $(basename "$d")"
done

# After
for d in "$MEETINGS_DIR/Series"/*/; do
  [[ -d "$d" ]] && _detail "  $(basename "$d")"
done
```

Also update the `MEETINGS_DIR` existence check error hint to reference `Meetings/Series/` if that hint mentions the path.

**3. Update inline usage comment (line 3)**

```bash
# Before
# Usage: new-meeting-series.sh --vault <path> [--series <name>] [--date <YYYY-MM-DD>]

# After
# Usage: new-meeting-series.sh --vault <path> [--company <name>] [--series <name>] [--purpose <text>] [--cadence <text>]
# Creates or updates a meeting series instance at Meetings/Series/<Series>/<Date>/
```

---

### `src/bin/new-1on1.sh`

**Verify only.** The 1on1s path (`$VAULT/Work/$CURRENT_COMPANY/Meetings/1on1s`) is unchanged by this restructure. Confirm line ~74 reads:

```bash
ONEONS_DIR="$VAULT/Work/$CURRENT_COMPANY/Meetings/1on1s"
```

No code change expected. If a change is found, document it in the migration notes.

Update the inline usage comment to reflect all supported flags:

```bash
# Usage: new-1on1.sh --vault <path> [--company <name>] [--name <name>]
# Creates a new 1:1 rolling note or appends a dated entry to an existing one.
# Notes are created at Meetings/1on1s/<Name> 1on1s.md
```

---

## New File — `src/bin/new-standalone-meeting.sh`

### Purpose

Creates a single non-series meeting note for any meeting that warrants its own record but is not a recurring series or 1:1. Places the note in `Meetings/Single/`.

### Flags

| Flag | Required | Default | Behavior |
|---|---|---|---|
| `--vault` | Yes | `$MERIDIAN_VAULT` or interactive picker | Same resolution as all other scripts |
| `--company` | No | Auto-resolved | Same resolution order as `new-meeting-series.sh` |
| `--name` | No | Prompted interactively | Meeting title; used in filename and H1 |
| `--date` | No | Today (`date +%Y-%m-%d`) | Target date; allows prep for future meetings |
| `--folder` | No | Off (single file) | When set, creates a folder + index note instead of flat file |

### File Locations

**Default (single file):**
```
Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>.md
```

**With `--folder`:**
```
Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>/
  YYYY-MM-DD <Name>.md
```

Folder mode exists for meetings where prep materials, slides, or other artifacts need to be co-located. No additional files are seeded inside the folder.

### Note Content

```
---
title: YYYY-MM-DD <Name>
created: YYYY-MM-DD HH:MM:SS
modified: YYYY-MM-DD HH:MM:SS
---
# YYYY-MM-DD <Name>

## Purpose

## Attendees

## Agenda

## Key Points

## Decisions
- ?

## Action Items
- [ ] !

## Next Meeting

---
*Daily note:* [[YYYY-MM-DD]]
```

Note: no `*Series:*` backlink. The `[[YYYY-MM-DD]]` link uses the `--date` value (defaulting to today), not the current date at execution time if they differ.

### Behavior

- **Collision check:** if the target file or folder already exists, print an error and exit non-zero. Do not prompt for overwrite — abort cleanly.
- **Confirmation:** show the resolved name, date, and target path; prompt `[y/N]` before writing anything.
- **Single/` directory:** if `Meetings/Single/` does not exist, die with a helpful error: `"Meetings/Single/ not found. Run scaffold-vault.sh first."`
- **`--help`:** print flag summary and exit 0.

### Pattern Reference

Follow the same structure as `new-meeting-series.sh`:
- Shebang, `set -euo pipefail`
- `SCRIPT_DIR` resolution
- `LIB_DIR` with in-repo / in-vault fallback
- Source `colors.sh`, `logging.sh`, `errors.sh`, `vault-select.sh`
- Argument parsing with `while [[ $# -gt 0 ]]`
- Vault validation with `$MERIDIAN_VAULT` fallback and `select_vault`
- Company resolution via `resolve_company`
- Confirmation prompt before any writes
- `_pass`, `_hint`, `_detail` for output

### Inline Usage Comment

```bash
#!/usr/bin/env bash
# new-standalone-meeting.sh — create a standalone meeting note in Meridian
#
# Usage:
#   new-standalone-meeting.sh --vault <path>
#   new-standalone-meeting.sh --vault <path> --name <name> --date <YYYY-MM-DD> [--folder]
#
# Flags:
#   --vault    Path to the Meridian vault (required, or $MERIDIAN_VAULT, or interactive)
#   --company  Company name (optional — auto-resolved from daily-notes.json or .vault-version)
#   --name     Meeting name/title (optional — prompted if omitted)
#   --date     Meeting date YYYY-MM-DD (optional — defaults to today)
#   --folder   Create a folder + index note instead of a flat file (for artifact-heavy meetings)
#
# Creates a single meeting note at:
#   Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>.md          (default)
#   Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>/<Name>.md   (--folder)
```

---

## Shell Commands Plugin Entry

The new script must be registered as a Shell Commands palette entry. In `scaffold-vault.sh`, find where the `.obsidian/shell-commands.json` (or equivalent config) is written and add an entry for **New Meeting** that invokes `new-standalone-meeting.sh`. Follow the same pattern as the existing entries for New Company, New Project, New Meeting Series, and New 1:1.

---

## Deliverables Checklist

- [ ] `src/bin/scaffold-vault.sh` — `Knowledge/References/` and `Meetings/Series/`, `Meetings/Single/`, `Meetings/1on1s/`
- [ ] `src/bin/new-meeting-series.sh` — path updated to `Meetings/Series/[Series]/`, series listing updated, inline docs updated
- [ ] `src/bin/new-1on1.sh` — path verified unchanged, inline docs updated
- [ ] `src/bin/new-standalone-meeting.sh` — new script created per spec
- [ ] Shell Commands config in `scaffold-vault.sh` — **New Meeting** entry added
- [ ] `docs/phase-1-migration-notes.md` — produced (see below)

---

## Required Output: `docs/phase-1-migration-notes.md`

Phase 1 must produce this file before handoff. Phase 3 (integration) consumes it to write the upgrade migration scripts. It must cover:

1. **Path changes** — exact before/after paths for every structural change made
2. **New paths created by scaffold** — every new folder `scaffold-vault.sh` now creates that it did not before
3. **Affected scripts** — which scripts changed and what their old vs new path logic was
4. **Wikilink assumption** — confirm that all Meridian wikilinks use shortest-path format (not full paths), and therefore moving series folders from `Meetings/[Series]/` to `Meetings/Series/[Series]/` will not break existing backlinks as long as filenames are unchanged
5. **Deviations** — any decisions made during implementation that differ from this spec, with rationale

Use this template:

```markdown
# Phase 1 Migration Notes

## Path Changes

| Type | Before | After |
|---|---|---|
| Folder | `References/` | `Knowledge/References/` |
| Folder | `Meetings/[Series]/` | `Meetings/Series/[Series]/` |
| Folder | (did not exist) | `Meetings/Single/` |

## New Scaffold Paths
...

## Wikilink Assumption
...

## Deviations from Spec
(none — or list each deviation with rationale)
```
