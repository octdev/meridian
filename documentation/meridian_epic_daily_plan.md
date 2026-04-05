# Contextual Vault Segmentation — Implementation Plan

## Context

Meridian currently places all daily notes in `Process/Daily/` and creates a top-level `Knowledge/` tree in both personal and work vaults. This conflates capture with aggregation and leaks personal knowledge into work deployments. This plan restructures the vault so daily capture lives in the domain it belongs to (`Life/Daily/` or `Work/<Company>/Daily/`), `Process/` becomes a pure aggregation layer, and work vaults scope knowledge under the company folder.

---

## Phase 1: Scaffold Structure Changes

**Goal:** Update `scaffold-vault.sh` so new vaults get the correct folder layout and daily-notes config per profile.

### 1a. Move folder declarations (`src/bin/scaffold-vault.sh` ~line 347)

- Remove `"Process/Daily"` from the shared `dirs=()` array
- Move `Knowledge/` entries (`Technical`, `Leadership`, `Industry`, `General`) into the `personal`-only block (lines 371-384)
- Add `"Life/Daily"` to the `personal`-only block
- Add `"Work/$COMPANY/Daily"` to the shared array (work already gets `Work/$COMPANY/*`)
- Add `"Work/$COMPANY/Knowledge/Technical"`, `"Work/$COMPANY/Knowledge/Leadership"`, `"Work/$COMPANY/Knowledge/Industry"` to the shared array

**After:**
```
# Shared dirs (both profiles)
dirs=(
  "Process/Weekly"
  "Process/Drafts"
  "Process/Meridian Documentation"
  "Work/$COMPANY/Projects"
  ...existing Work dirs...
  "Work/$COMPANY/Daily"
  "Work/$COMPANY/Knowledge/Technical"
  "Work/$COMPANY/Knowledge/Leadership"
  "Work/$COMPANY/Knowledge/Industry"
  "_templates"
  ".scripts"
  ".scripts/lib"
)

# Personal-only additions
if [[ "$PROFILE" == "personal" ]]; then
  dirs+=(
    "Northstar"
    "Life/Projects"
    ...existing Life dirs...
    "Life/Daily"
    "Knowledge/Technical"
    "Knowledge/Leadership"
    "Knowledge/Industry"
    "Knowledge/General"
    "References"
  )
fi
```

### 1b. Profile-conditional daily-notes.json (~line 484)

Replace the single `write_if_new` block with:
```bash
if [[ "$PROFILE" == "personal" ]]; then
  DAILY_FOLDER="Life/Daily"
else
  DAILY_FOLDER="Work/$COMPANY/Daily"
fi

write_if_new "$VAULT_ROOT/.obsidian/daily-notes.json" "{
  \"folder\": \"$DAILY_FOLDER\",
  \"template\": \"_templates/Daily Note\",
  \"format\": \"YYYY-MM-DD\",
  \"autorun\": false
}"
```

### 1c. Update tests (`tests/run-tests.sh`)

The test file has assertions that must change:

- **Line 162:** Shared folder loop includes `"Process/Daily"` — remove it, add `"Work/CurrentCompany/Daily"` and `"Work/CurrentCompany/Knowledge/Technical"`
- **Line 224:** Asserts `daily-notes.json` contains `"folder": "Process/Daily"` — change to `"folder": "Life/Daily"` for personal vault
- **Line 236:** Work vault shared folder check includes `"Process/Daily"` and `"Knowledge/Technical"` — replace `"Process/Daily"` with `"Work/CurrentCompany/Daily"`, replace `"Knowledge/Technical"` with `"Work/CurrentCompany/Knowledge/Technical"`
- Add new assertions:
  - Personal vault: `Life/Daily/` exists, `Process/Daily/` does not
  - Work vault: `Work/CurrentCompany/Daily/` exists, `Process/Daily/` does not, no top-level `Knowledge/`
  - Work vault daily-notes.json contains `"folder": "Work/CurrentCompany/Daily"`

### Verification
- Run `bash tests/run-tests.sh` — all tests pass
- Manual spot-check: scaffold both profiles to `/tmp/` and inspect folder structure + daily-notes.json

---

## Phase 2: new-company.sh Changes

**Goal:** New companies get `Daily/` and `Knowledge/` subdirectories, and `daily-notes.json` is updated to point to the new company.

### 2a. Add directories (`src/bin/new-company.sh` ~line 91)

After existing `mkdir -p` calls, add:
```bash
mkdir -p "${company_dir}/Daily"
mkdir -p "${company_dir}/Knowledge/Technical"
mkdir -p "${company_dir}/Knowledge/Leadership"
mkdir -p "${company_dir}/Knowledge/Industry"
```

### 2b. Update daily-notes.json

After directory creation, update the daily notes config to point to the new company:
```bash
local daily_config="$vault_root/.obsidian/daily-notes.json"
cat > "$daily_config" <<DAILY
{
  "folder": "Work/$company_name/Daily",
  "template": "_templates/Daily Note",
  "format": "YYYY-MM-DD",
  "autorun": false
}
DAILY
_pass "Daily notes config updated to Work/$company_name/Daily"
```

Note: This overwrites (not `write_if_new`) because switching companies must update the active daily path.

### Verification
- Run `new-company.sh` in a test work vault — confirm `Daily/`, `Knowledge/Technical/`, `Knowledge/Leadership/`, `Knowledge/Industry/` exist under the new company
- Confirm `daily-notes.json` now points to the new company's `Daily/`

---

## Phase 3: weekly-snapshot.py Changes

**Goal:** Scan all `Daily/` directories in the vault instead of only `Process/Daily/`.

### Changes (`src/bin/weekly-snapshot.py` ~line 173)

Replace:
```python
daily_dir  = vault / "Process" / "Daily"
```

With a discovery function:
```python
def find_daily_dirs(vault: Path) -> list[Path]:
    """Discover all Daily/ directories across domain folders."""
    candidates = [
        vault / "Life" / "Daily",
        vault / "Process" / "Daily",        # legacy support
    ]
    # Work/*/Daily — one per company
    work_dir = vault / "Work"
    if work_dir.exists():
        for child in sorted(work_dir.iterdir()):
            if child.is_dir():
                d = child / "Daily"
                if d.exists():
                    candidates.append(d)
    return [d for d in candidates if d.exists()]
```

Update `main()`:
```python
daily_dirs = find_daily_dirs(vault)
if not daily_dirs:
    sys.exit(0)

# Merge tasks from all daily directories
by_day: dict = {}
for dd in daily_dirs:
    partial = extract_tasks(dd, mon, sun)
    for day, tasks in partial.items():
        by_day.setdefault(day, []).extend(tasks)
```

### Verification
- Create test daily files in `Life/Daily/` and `Work/TestCo/Daily/` — run `weekly-snapshot.py --dry-run` and confirm tasks from both locations appear
- Confirm legacy `Process/Daily/` files are still picked up if present

---

## Phase 4: MOC Query Updates

**Goal:** MOC queries find daily notes regardless of which domain folder they live in.

### Change `path includes Process/Daily` → `path includes /Daily/`

This substring matches all Daily/ folders (`Life/Daily/`, `Work/*/Daily/`, legacy `Process/Daily/`). No other vault folder uses `Daily` as a name.

**Files and occurrences:**

| File | Lines | Count |
|------|-------|-------|
| `src/templates/mocs/action-items.md` | 13, 22, 31, 41 | 4 |
| `src/templates/mocs/open-loops.md` | 12, 21 | 2 |
| `src/templates/mocs/review-queue.md` | 12, 21 | 2 |
| `src/templates/mocs/weekly-outtake.md` | 13, 25, 36, 47 | 4 |

**Total:** 12 replacements, all identical: `Process/Daily` → `/Daily/`

No changes needed:
- `active-projects.md` — queries `FROM "Work"` and `FROM "Life/Projects"`, no Daily reference
- `current-priorities.md` — no dynamic queries

### 4b. Update Weekly Outtake prose reference

`src/templates/mocs/weekly-outtake.md` line 9 contains prose: `"For permanent weekly records, see Process/Weekly/."` — this is still correct (Weekly stays in Process). No change needed.

### Verification
- Grep all MOC files for `Process/Daily` — should return zero matches
- Grep for `/Daily/` — should return 12 matches across the 4 files

---

## Phase 5: Documentation Updates

### 5a. Architecture.md
- Update personal vault diagram: replace `Process/Daily/` with `Life/Daily/`
- Update work vault diagram: add `Work/CurrentCompany/Daily/`, `Work/CurrentCompany/Knowledge/{Technical,Leadership,Industry}`; remove top-level `Knowledge/`
- Update data flow: daily note creation routes to domain folder, not Process
- Update Process description: pure aggregation layer (MOCs, Weekly, Drafts, Documentation)

### 5b. Design Decision.md
Add three new entries:
- **DD-18: Daily notes scoped to domain folders** — supersedes the implicit `Process/Daily` assumption. Daily capture belongs to the domain that generated it.
- **DD-19: Work-scoped knowledge under company folder** — work vaults no longer get top-level `Knowledge/`. Knowledge generated at work lives at `Work/<Company>/Knowledge/`. Promotion to personal `Knowledge/` is manual.
- **DD-20: Process/ as pure aggregation layer** — `Process/` contains only retrieval surfaces (MOCs, Weekly, Drafts, Documentation). No content originates in Process.

### 5c. User Handbook.md
- Update daily note section: personal → `Life/Daily/`, work → `Work/<Company>/Daily/`
- Update Knowledge section: describe work-scoped knowledge and the promotion workflow
- Update Work section: mention Daily/ and Knowledge/ under company folders

### 5d. User Setup.md
- Update Daily Notes plugin config: show per-profile paths
- Update Syncthing setup: remove `Knowledge/: Send Only` row, note that work knowledge syncs as part of `Work/`

### 5e. Sync.md
- Remove `Knowledge/ | Send Only` row from sync matrix
- Add note that `Work/<Company>/Knowledge/` syncs bidirectionally as part of `Work/`
- Update any references to Knowledge sync boundary

### 5f. Reference Guide.md
- Update structure diagram: `Process/Daily/` → `Life/Daily/` (personal) / `Work/<Company>/Daily/` (work)
- Update filing heuristics and morning triage references
- Update `Process/Daily/YYYY-MM-DD.md` reference (line 261)

### 5g. meridian-system.html
- Line 147: Update morning triage step from `Process/Daily/YYYY-MM-DD.md` to reflect domain-scoped location

### 5h. work-scaffold.md (internal working note)
- Line 34: Update bullet that lists `Process/Daily/` as shared between profiles — remove it, note `Work/CurrentCompany/Daily/` instead
- Line 36: Update Knowledge line to note it's now personal-only at top level, work-scoped under company

### 5i. Design Decision.md — existing entry review
- Line 97 area: DD-11 references `Process/Drafts/` and mentions `Process/Daily/` in its rationale. The rationale text describes the old layout. Add a note or ensure DD-18 explicitly supersedes this assumption.

### Verification
- Grep entire repo for `Process/Daily` — should return zero matches outside of the epic doc itself and the plan
- Grep for `Knowledge.*Send Only` — should return zero matches
- Confirm DD-18, DD-19, DD-20 exist in Design Decision.md

---

## Phase 6: Version Bump

**Goal:** Bump version from 0.9.2 to 0.10.0 to reflect the structural change.

### Changes (`config/base/version.json`)

Update semver fields:
```json
{
  "semver": {
    "major": 0,
    "minor": 10,
    "patch": 0
  },
  "metadata": {
    "releaseDate": "<commit date>",
    "gitCommit": "<commit hash>"
  }
}
```

Note: `scripts/ci/release.sh` exists for automated version bumps. Evaluate whether to use `release.sh --minor` instead of a manual edit, since it also updates the git tag and README.

### Verification
- Confirm `config/base/version.json` reads `0.10.0`
- Confirm metadata fields are current

---

## Phase 7: Upgrade Scripts

**Goal:** Create the two upgrade script files required for 0.10.0 per the conventions in `Upgrades.md`. These scripts allow existing vaults to migrate forward from 0.9.2 without re-scaffolding.

### Files to create

```
scripts/upgrade/upgrade-to-0.10.0.sh      # entry point
scripts/upgrade/migrations/v0.10.0.sh     # migration logic
```

### 7a. Entry point (`scripts/upgrade/upgrade-to-0.10.0.sh`)

Standard three-line entry point — only the version string changes:

```bash
#!/usr/bin/env bash
# upgrade-to-0.10.0.sh — upgrades a Meridian vault to version 0.10.0
#
# Usage:
#   upgrade-to-0.10.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 0.10.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.10.0" "${SCRIPT_DIR}/migrations" "$@"
```

### 7b. Migration script (`scripts/upgrade/migrations/v0.10.0.sh`)

The migration logic covers all changes identified in the **Upgrade Considerations** section. Structure:

**Global section (no `$COMPANY`):**
1. Create `Life/Daily/` directory (personal vaults)
2. Move `Process/Daily/*.md` → `Life/Daily/` (personal) or `Work/<Company>/Daily/` (work) — detect conflicts, refuse to overwrite
3. Remove `Process/Daily/` if empty after move
4. Force-overwrite `.obsidian/daily-notes.json` with the new domain-scoped path
5. In-place `sed` replacement of `path includes Process/Daily` → `path includes /Daily/` in all 4 MOC files: `Process/Action Items.md`, `Process/Open Loops.md`, `Process/Review Queue.md`, `Process/Weekly Outtake.md` — skip silently if string not found

**Per-company section (`$COMPANY` set):**
1. Create `Work/$COMPANY/Daily/`
2. Create `Work/$COMPANY/Knowledge/Technical/`, `…/Leadership/`, `…/Industry/`
3. Move `Knowledge/Technical/*`, `…/Leadership/*`, `…/Industry/*` → corresponding `Work/$COMPANY/Knowledge/` paths — conflict detection; refuse to overwrite
4. Check `Knowledge/General/` — if it contains files, warn the user and skip (do not delete)
5. Remove top-level `Knowledge/` if empty after moves
6. Update `.obsidian/daily-notes.json` to point to `Work/$COMPANY/Daily` (overwrite, not `write_if_new`)

**Reporting:** After all actions, print a summary: files moved, any skipped conflicts, `Knowledge/General/` warnings, and confirmation that `daily-notes.json` and MOC queries were updated.

**Helpers:** Define `copy_if_new`, `write_if_new`, and any move/conflict helpers inline — do not import from other migration scripts.

### 7c. Checklist

- [ ] Create `scripts/upgrade/migrations/v0.10.0.sh` with global and per-company sections
- [ ] Create `scripts/upgrade/upgrade-to-0.10.0.sh` entry point
- [ ] Verify `scripts/upgrade/upgrade-runner.sh` does not need changes for this version
- [ ] Manual test: scaffold a personal vault at 0.9.2, run upgrade, confirm `Life/Daily/` exists and daily-notes.json updated
- [ ] Manual test: scaffold a work vault at 0.9.2, run upgrade, confirm `Work/Co/Daily/` and `Work/Co/Knowledge/` exist
- [ ] Manual test: conflict detection — pre-place a file in target location, confirm upgrade refuses and reports it
- [ ] Manual test: `Knowledge/General/` warning fires when files present

### Verification

- Run `./src/bin/scaffold-vault.sh --version` before and after — version reads `0.10.0` after
- Grep `.vault-version` in the upgraded test vault — confirms `vault=0.10.0`
- Confirm `Process/Daily/` no longer exists in either test vault (if it was empty)
- Confirm all 4 MOC files no longer contain `Process/Daily`

---

## Execution Order

```
Phase 1 (scaffold-vault.sh + tests)
    ↓
Phase 2 (new-company.sh)  — depends on Phase 1 patterns
    ↓
Phases 3, 4, 5, 7 — independent of each other, can be done in parallel
    ↓
Phase 6 (version bump)  — after all changes are complete
```

Note: Phase 7 (upgrade scripts) can be written in parallel with Phases 3–5 since it depends only on knowing the final vault structure (Phase 1) and the company folder patterns (Phase 2).

## Upgrade Considerations

An upgrade of an existing vault must account for the following. This section documents what the upgrade logic needs to detect and handle — not the implementation.

### 1. Determine vault profile

The upgrade must know whether the vault is personal or work. The current `--upgrade` path already accepts `--profile`. This determines which daily folder to create and where to point `daily-notes.json`.

### 2. Determine the active company name (work vaults)

The current upgrade path already detects companies from `Work/*/` subdirectories and prompts the user to confirm. The resolved company name determines the target paths for daily notes and knowledge folders.

### 3. Move existing daily notes

`Process/Daily/*.md` files need to move to the correct domain folder:
- Personal vault: `Process/Daily/*.md` → `Life/Daily/`
- Work vault: `Process/Daily/*.md` → `Work/<Company>/Daily/`

Considerations:
- Files may have been modified by the user (custom content, extra sections). Move must preserve content exactly.
- Obsidian wiki-links (`[[2025-01-15]]`) are name-based, not path-based — they resolve by filename regardless of folder. Moving files does not break these links.
- If the vault has daily notes in `Process/Daily/` and the target folder already has files (e.g., a partial manual migration), the script must detect conflicts (same filename in both locations) and refuse to overwrite.
- `Process/Daily/` should be removed after migration if empty.

### 4. Move work knowledge (work vaults only)

Top-level `Knowledge/` content moves under the company folder:
- `Knowledge/Technical/*` → `Work/<Company>/Knowledge/Technical/`
- `Knowledge/Leadership/*` → `Work/<Company>/Knowledge/Leadership/`
- `Knowledge/Industry/*` → `Work/<Company>/Knowledge/Industry/`

Considerations:
- `Knowledge/General/` is dropped from work vaults entirely. If it contains files, the script must warn the user and skip (not silently delete content). The user decides whether to promote those files to the personal vault or discard them.
- Same conflict detection as daily notes — refuse to overwrite if target files already exist.
- `Knowledge/` should be removed from the work vault after migration if empty.
- Personal vaults: no Knowledge changes. The script must not touch `Knowledge/` on personal vaults.

### 5. Update `.obsidian/daily-notes.json`

This file is created with `write_if_new`, so it is never overwritten during a normal scaffold run. The upgrade must **force-overwrite** this file to point to the new daily location:
- Personal: `"folder": "Life/Daily"`
- Work: `"folder": "Work/<Company>/Daily"`

### 6. Update MOC files in the vault

MOCs are deployed with `copy_with_timestamps`, which skips existing files. Existing vaults will retain MOCs with `path includes Process/Daily` queries that no longer match. The upgrade must update these query paths in-place:
- Replace `path includes Process/Daily` with `path includes /Daily/` in all 4 MOC files:
  - `Process/Action Items.md`
  - `Process/Open Loops.md`
  - `Process/Review Queue.md`
  - `Process/Weekly Outtake.md`

Considerations:
- Users may have customized MOC files (added sections, changed sort order). The replacement must be surgical — only change the `path includes` line, not rewrite the file.
- If a MOC file doesn't contain `Process/Daily` (already updated or heavily customized), skip it silently.

### 7. Create new directories

The upgrade must create directories that didn't previously exist:
- Personal vault: `Life/Daily/` (may already exist from the move)
- Work vault: `Work/<Company>/Daily/`, `Work/<Company>/Knowledge/Technical/`, `Work/<Company>/Knowledge/Leadership/`, `Work/<Company>/Knowledge/Industry/`

The existing `mkdir -p` + skip-if-exists pattern handles this naturally.

### 8. Documentation refresh

The existing upgrade path already force-overwrites documentation via `write_doc_with_frontmatter`. No special handling needed — updated docs will be deployed automatically on upgrade.

### 9. Summary of what the user must be told

After upgrade, the script should report:
- How many daily notes were moved and to where
- How many knowledge files were moved (work vaults)
- Whether any `Knowledge/General/` files were left behind (work vaults)
- That `daily-notes.json` was updated — `Cmd+D` now routes to the new location
- That MOC query paths were updated

---

## Open Questions Resolved

| Epic question | Resolution |
|---|---|
| Shell Commands plugin entries | scaffold-vault.sh does not write Shell Commands config — no `Process/Daily` path embedded. No change needed. |
| `weekly-snapshot.py` company folder resolution | Phase 3 uses `find_daily_dirs()` to discover all `Work/*/Daily/` at runtime — no hardcoded company name needed. |
| Dataview Active Projects MOC | Confirmed: queries `FROM "Work"` and `FROM "Life/Projects"` — no Daily or Process dependency. No change needed. |
| `Reference Guide.md` | Confirmed: references `Process/Daily/` at lines 13-14, 36, 261. Added to Phase 5f. |
| `daily-note.md` template | Confirmed: uses only Obsidian template variables (`{{date:...}}`), no path references. No change needed. |

## Files Not Changed (verified)

| File | Reason |
|---|---|
| `src/templates/obsidian-templates/daily-note.md` | No path references — only Obsidian template variables |
| `src/templates/mocs/active-projects.md` | Queries `FROM "Work"` / `FROM "Life/Projects"` — no Daily dependency |
| `src/templates/mocs/current-priorities.md` | Static section headers, no queries |
| `src/bin/new-project.sh` | Out of scope per epic |
| `src/bin/new-meeting-series.sh` | Out of scope per epic |

## Files Modified

| File | Phase |
|------|-------|
| `src/bin/scaffold-vault.sh` | 1 |
| `tests/run-tests.sh` | 1 |
| `src/bin/new-company.sh` | 2 |
| `src/bin/weekly-snapshot.py` | 3 |
| `src/templates/mocs/action-items.md` | 4 |
| `src/templates/mocs/open-loops.md` | 4 |
| `src/templates/mocs/review-queue.md` | 4 |
| `src/templates/mocs/weekly-outtake.md` | 4 |
| `documentation/Architecture.md` | 5 |
| `documentation/Design Decision.md` | 5 |
| `documentation/User Handbook.md` | 5 |
| `documentation/User Setup.md` | 5 |
| `documentation/Sync.md` | 5 |
| `documentation/Reference Guide.md` | 5 |
| `documentation/work-scaffold.md` | 5 |
| `meridian-system.html` | 5 |
| `config/base/version.json` | 6 |
| `scripts/upgrade/upgrade-to-0.10.0.sh` | 7 |
| `scripts/upgrade/migrations/v0.10.0.sh` | 7 |
