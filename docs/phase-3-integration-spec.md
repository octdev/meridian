# Phase 3 — Integration Spec

**Audience:** Developer writing migration scripts, test updates, and version bump.
**Depends on:** Phase 1 complete (`docs/phase-1-migration-notes.md` produced) and Phase 2 complete (documentation reflects final state).
**Feeds into:** Phase 4 (release).

---

## Context

Meridian is a personal knowledge management system built on Obsidian. See `src/documentation/Architecture.md` for system context.

The upgrade system is in `scripts/upgrade/`. Each release gets:
- One entry point: `scripts/upgrade/upgrade-to-X.Y.Z.sh`
- One migration script: `scripts/upgrade/migrations/vX.Y.Z.sh`

The runner (`scripts/upgrade/upgrade-runner.sh`) is a sourced library — do not modify it. Study `scripts/upgrade/upgrade-to-1.4.0.sh` and `scripts/upgrade/migrations/v1.4.0.sh` as the canonical pattern before writing anything.

**Before starting:** read both `docs/phase-1-migration-notes.md` and `docs/phase-2-docs-spec.md`. If Phase 1 documented deviations, your migration script must reflect the actual paths, not the spec paths.

---

## Step 1 — Bump Version

**File:** `config/base/version.json`

Current version: `1.4.0`. This release is a minor version bump — it introduces new vault structure, a new script, and breaking path changes.

New version: `1.5.0`

```json
{
  "semver": {
    "major": 1,
    "minor": 5,
    "patch": 0
  },
  "metadata": {
    "releaseDate": "<today's date>",
    "gitCommit": "pending"
  }
}
```

---

## Step 2 — Write the Upgrade Entry Point

**File:** `scripts/upgrade/upgrade-to-1.5.0.sh`

Follow the exact pattern of `scripts/upgrade/upgrade-to-1.4.0.sh`. The file is minimal — it sources the runner and delegates.

```bash
#!/usr/bin/env bash
# upgrade-to-1.5.0.sh — upgrades a Meridian vault to version 1.5.0
#
# Usage:
#   upgrade-to-1.5.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 1.5.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Changes in this release:
#   - References/ moved to Knowledge/References/
#   - Meetings restructured: Series/, Single/, 1on1s/ subfolders
#   - new-standalone-meeting.sh deployed to .scripts/
#   - new-meeting-series.sh, new-1on1.sh refreshed in .scripts/
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "1.5.0" "${SCRIPT_DIR}/migrations" "$@"
```

---

## Step 3 — Write the Migration Script

**File:** `scripts/upgrade/migrations/v1.5.0.sh`

This script handles two categories of change:
- **Global changes** (run once per vault): `References/` → `Knowledge/References/`, new `.scripts/` files
- **Per-company changes** (run once per selected company): `Meetings/[Series]/` → `Meetings/Series/[Series]/`, create `Meetings/Single/`

The runner calls the script twice per version: once without `$3` (global pass), then once per selected company with `$3` set.

### Key behavioral requirements

- All moves must be idempotent: if the destination already exists, skip and warn — do not fail.
- All moves must be verified: check the source exists before moving; if it doesn't, warn and skip (not every vault will have content in every folder).
- If a move fails partway through, exit non-zero immediately. The runner will halt the chain at the last successful version.
- After a successful global pass, `.scripts/` must contain `new-standalone-meeting.sh` and refreshed versions of `new-meeting-series.sh` and `new-1on1.sh`.
- After a successful per-company pass, `Meetings/` must have the `Series/`, `Single/`, and `1on1s/` subfolders and any existing series content must have moved.

### Global changes

```
1. Move References/ → Knowledge/References/
   - Source: $VAULT_ROOT/References/
   - Destination: $VAULT_ROOT/Knowledge/References/
   - Condition: source exists AND destination does not exist
   - If source does not exist: warn "References/ not found — skipping (may already be migrated)"
   - If destination already exists: warn "Knowledge/References/ already exists — skipping move"
   - After move: verify destination exists

2. Deploy new-standalone-meeting.sh to .scripts/
   - Source: $REPO_DIR/src/bin/new-standalone-meeting.sh
   - Destination: $VAULT_ROOT/.scripts/new-standalone-meeting.sh
   - Always overwrite (deploy, not copy-if-new)

3. Refresh updated scripts in .scripts/
   - new-meeting-series.sh
   - new-1on1.sh
   - Always overwrite
```

### Per-company changes

```
1. Create Meetings subfolders if absent
   - $VAULT_ROOT/Work/$COMPANY/Meetings/Series/   (mkdir -p, no-op if exists)
   - $VAULT_ROOT/Work/$COMPANY/Meetings/Single/   (mkdir -p, no-op if exists)
   - $VAULT_ROOT/Work/$COMPANY/Meetings/1on1s/ already exists — verify, do not recreate

2. Move existing series folders into Series/
   - Iterate: for each directory in $VAULT_ROOT/Work/$COMPANY/Meetings/
     - Skip: 1on1s/, Series/, Single/  (these are the new structure — do not move them)
     - For everything else (these are legacy series folders):
       - Source: $VAULT_ROOT/Work/$COMPANY/Meetings/[Series]/
       - Destination: $VAULT_ROOT/Work/$COMPANY/Meetings/Series/[Series]/
       - If destination already exists: warn and skip
       - Move with: mv "$SOURCE" "$DEST"
       - Log: _pass "Moved series: $SERIES → Meetings/Series/$SERIES"
```

### Wikilink assumption (document in script header)

All Meridian wikilinks use shortest-path format (`[[Series Name]]`, not `[[Meetings/Series Name/Series Name]]`). Moving series folders from `Meetings/[Series]/` to `Meetings/Series/[Series]/` does not break existing backlinks as long as filenames are unchanged. If a user has non-standard full-path links, those will need manual repair — note this in the migration output.

### Script template

```bash
#!/usr/bin/env bash
# migrations/v1.5.0.sh — vault changes for Meridian 1.5.0
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/
#
# Changes in this release:
#   Global: References/ moved to Knowledge/References/
#   Global: new-standalone-meeting.sh deployed to .scripts/
#   Global: new-meeting-series.sh, new-1on1.sh refreshed in .scripts/
#   Per-company: Meetings restructured — Series/, Single/ created;
#                existing series folders moved into Meetings/Series/
#
# Wikilink assumption: Meridian uses shortest-path wikilinks. Series folder
# moves do not break backlinks as long as filenames are unchanged.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

readonly VAULT_ROOT="$1"
readonly REPO_DIR="$2"
readonly COMPANY="${3:-}"

source "${REPO_DIR}/src/lib/logging.sh"
source "${REPO_DIR}/src/lib/errors.sh"

# ... [implement global and per-company blocks as specified above]
```

---

## Step 4 — Update Test Scripts

**File:** `tests/run-tests.sh`

Read the existing test file in full before making changes. The test suite uses `check`, `assert_exists`, `assert_absent`, `pass`, `fail`, and `section` helpers. Follow existing patterns exactly.

### New test coverage required

Add tests for each of the following. Insert them in a logical section grouping (after the existing scaffold tests, before or alongside the existing script tests):

#### Scaffold — personal vault structure

```
assert_exists  "personal vault: Knowledge/References/ exists"
               $VAULT/Knowledge/References/

assert_absent  "personal vault: References/ does not exist at root"
               $VAULT/References/

assert_exists  "personal vault: Meetings/1on1s/ exists"
               $VAULT/Work/CurrentCompany/Meetings/1on1s/

assert_exists  "personal vault: Meetings/Series/ exists"
               $VAULT/Work/CurrentCompany/Meetings/Series/

assert_exists  "personal vault: Meetings/Single/ exists"
               $VAULT/Work/CurrentCompany/Meetings/Single/
```

#### Scaffold — work vault structure

```
assert_absent  "work vault: References/ does not exist at root"
               $WORK_VAULT/References/

assert_absent  "work vault: Knowledge/ does not exist at root"
               $WORK_VAULT/Knowledge/

assert_exists  "work vault: Meetings/1on1s/ exists"
               $WORK_VAULT/Work/CurrentCompany/Meetings/1on1s/

assert_exists  "work vault: Meetings/Series/ exists"
               $WORK_VAULT/Work/CurrentCompany/Meetings/Series/

assert_exists  "work vault: Meetings/Single/ exists"
               $WORK_VAULT/Work/CurrentCompany/Meetings/Single/
```

#### new-meeting-series.sh — path validation

```
check  "new-meeting-series creates series at Meetings/Series/[Series]/"
       exit 0 "Meetings/Series/"
       -- bash $REPO/src/bin/new-meeting-series.sh --vault $VAULT \
            --company CurrentCompany --series "Test Series" \
            --purpose "Test" --cadence "Weekly" <<< "y"

assert_exists  "series index at Meetings/Series/Test Series/Test Series.md"
               $VAULT/Work/CurrentCompany/Meetings/Series/Test Series/Test Series.md

assert_exists  "instance note at Meetings/Series/Test Series/<DATE>/"
               $VAULT/Work/CurrentCompany/Meetings/Series/Test Series/<DATE>/
```

#### new-standalone-meeting.sh — basic creation

```
check  "new-standalone-meeting creates note in Meetings/Single/"
       exit 0 "Meetings/Single/"
       -- bash $REPO/src/bin/new-standalone-meeting.sh --vault $VAULT \
            --company CurrentCompany --name "Test Meeting" <<< "y"

assert_exists  "standalone note at Meetings/Single/YYYY-MM-DD Test Meeting.md"
               $VAULT/Work/CurrentCompany/Meetings/Single/<DATE> Test Meeting.md
```

#### new-standalone-meeting.sh — folder mode

```
check  "new-standalone-meeting --folder creates folder + index note"
       exit 0 ""
       -- bash $REPO/src/bin/new-standalone-meeting.sh --vault $VAULT \
            --company CurrentCompany --name "Folder Meeting" --folder <<< "y"

assert_exists  "folder created at Meetings/Single/YYYY-MM-DD Folder Meeting/"
               $VAULT/Work/CurrentCompany/Meetings/Single/<DATE> Folder Meeting/

assert_exists  "index note inside folder"
               $VAULT/Work/CurrentCompany/Meetings/Single/<DATE> Folder Meeting/<DATE> Folder Meeting.md
```

#### new-standalone-meeting.sh — collision check

```
check  "new-standalone-meeting aborts if note already exists"
       exit 1 ""
       -- bash $REPO/src/bin/new-standalone-meeting.sh --vault $VAULT \
            --company CurrentCompany --name "Test Meeting" <<< "y"
```

#### Migration — v1.5.0 global: References/ move

```
# Setup: create a legacy References/ folder with a test file
# Run the migration global pass
# Assert source gone, destination exists with content preserved

assert_absent  "References/ removed from root after migration"
               $VAULT/References/

assert_exists  "Knowledge/References/ exists after migration"
               $VAULT/Knowledge/References/

assert_exists  "test file preserved in Knowledge/References/"
               $VAULT/Knowledge/References/test-artifact.md
```

#### Migration — v1.5.0 per-company: series move

```
# Setup: create a legacy series folder at Meetings/LegacySeries/
# Run the migration per-company pass
# Assert source gone, destination exists

assert_absent  "legacy series folder removed from Meetings/ root"
               $VAULT/Work/CurrentCompany/Meetings/LegacySeries/

assert_exists  "legacy series folder moved to Meetings/Series/"
               $VAULT/Work/CurrentCompany/Meetings/Series/LegacySeries/
```

---

## Step 5 — Create Validation Plan

**File:** `docs/validation-plan.md`

The validation plan is executed manually in Phase 4. It covers behaviors that cannot be fully automated: Obsidian UI behavior, plugin interactions, and end-to-end meeting workflows.

```markdown
# Validation Plan — Meridian 1.5.0

Execute after running the upgrade on a real vault and opening it in Obsidian.

## 1. Vault Structure

- [ ] `Knowledge/References/` exists and is accessible in file explorer
- [ ] No `References/` folder at vault root
- [ ] `Meetings/` contains exactly three subfolders: `1on1s/`, `Series/`, `Single/`
- [ ] Existing series folders (if any) are now inside `Meetings/Series/`
- [ ] `Meetings/Single/` exists and is empty (unless standalone meetings already exist)

## 2. Filing Heuristics — References

- [ ] Drop a PDF into `Knowledge/References/` — file appears in vault file explorer under Knowledge/References/
- [ ] Open an existing Knowledge note, link to the reference with `[[filename]]` — wikilink resolves

## 3. New Meeting Series

- [ ] Run `new-meeting-series.sh` for a brand new series
- [ ] Verify series index created at `Meetings/Series/[Series]/[Series].md`
- [ ] Verify instance created at `Meetings/Series/[Series]/[Date]/[Series] [Date].md`
- [ ] Run again for the same series — verify new instance created, series index updated, old instance preserved
- [ ] Open series index — verify instance link resolves

## 4. Existing Series Backlinks (upgrade only)

- [ ] Open an existing daily note that links to a series instance — verify wikilink still resolves after migration
- [ ] Open a migrated series index — verify instance links still resolve
- [ ] Open a migrated instance note — verify Series backlink and daily note backlink still resolve

## 5. New Standalone Meeting

- [ ] Run `new-standalone-meeting.sh` without `--folder`
- [ ] Verify note created at `Meetings/Single/YYYY-MM-DD <Name>.md`
- [ ] Verify note contains correct frontmatter, H1, and daily note backlink
- [ ] Run with `--folder` — verify folder + index note created
- [ ] Run for same name/date again — verify script aborts without writing

## 6. New 1:1

- [ ] Run `new-1on1.sh` for a new person — verify note at `Meetings/1on1s/[Name] 1on1s.md`
- [ ] Run again for same person — verify new dated entry appended, no duplicate header

## 7. MOCs

- [ ] Open `Process/Action Items.md` — no query errors
- [ ] Add a task in a meeting note under `Meetings/Series/` — verify it appears in Action Items MOC
- [ ] Add a task in a note under `Meetings/Single/` — verify it appears in Action Items MOC

## 8. Command Palette

- [ ] **New Meeting Series** appears in palette and runs successfully
- [ ] **New 1:1** appears in palette and runs successfully
- [ ] **New Meeting** appears in palette and runs successfully
- [ ] **New Company** appears in palette and runs successfully
- [ ] **New Project** appears in palette and runs successfully

## 9. Documentation

- [ ] Open `Process/Meridian Documentation/User Handbook.md` — renders correctly in Obsidian
- [ ] Open `Process/Meridian Documentation/Reference Guide.md` — vault structure paths are correct
- [ ] TOC links in User Handbook navigate correctly
```

---

## Deliverables Checklist

- [ ] `config/base/version.json` — bumped to `1.5.0`
- [ ] `scripts/upgrade/upgrade-to-1.5.0.sh` — entry point written
- [ ] `scripts/upgrade/migrations/v1.5.0.sh` — migration script written (global + per-company)
- [ ] `tests/run-tests.sh` — new test coverage added for all Phase 1 changes
- [ ] `docs/validation-plan.md` — manual validation plan written
