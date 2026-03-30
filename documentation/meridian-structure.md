# Project Structure

Migration plan from current Meridian layout to OctDev Scaffolding Standard alignment.

**Version:** 2.0.0
**Last Updated:** March 2026
**Status:** Complete — all phases implemented 2026-03-30
**Parent Documents:** [Scaffolding Standard](scaffolding-standard.md), [Scaffolding Bash Tools](scaffolding-bash-tools.md), [CLI Style Guide](cli-style-guide.md)

---

## Table of Contents

1. [Current State](#current-state)
2. [Target Structure](#target-structure)
3. [Change Summary](#change-summary)
4. [Implementation Plan](#implementation-plan)
5. [Out of Scope](#out-of-scope)

---

## Current State

```
meridian/
├── scaffold-vault.sh          # product binary — lives at root
├── scripts/
│   ├── release.sh             # CI/CD script — mixed with product scripts
│   ├── new-company.sh         # vault-delivered script
│   ├── new-project.sh         # vault-delivered script
│   └── weekly-snapshot.py     # vault-delivered script
├── vault-files/
│   ├── templates/
│   │   ├── Daily Note.md
│   │   ├── Generic Note.md
│   │   └── Reflection.md
│   ├── mocs/
│   │   ├── Action Items.md
│   │   ├── Active Projects.md
│   │   ├── Open Loops.md
│   │   ├── Review Queue.md
│   │   ├── Weekly Outtake.md
│   │   └── Current Priorities.md
│   └── northstar/
│       ├── Purpose.md
│       ├── Vision.md
│       ├── Mission.md
│       ├── Principles.md
│       ├── Values.md
│       ├── Goals.md
│       └── Career.md
├── tests/
├── documentation/
├── .github/workflows/
├── .gitignore
├── .gitattributes
├── LICENSE
├── meridian-system.html
├── Meridian System.pdf
└── README.md
```

### Problems

1. **`scaffold-vault.sh` at repo root** — Product binary belongs in `src/bin/`.
2. **CI and product scripts co-located** — `release.sh` (CI/CD) shares `scripts/` with vault-delivered product scripts (`new-company.sh`, `new-project.sh`, `weekly-snapshot.py`). These serve different purposes and audiences.
3. **No shared libraries** — Color setup, output helpers (`_pass`, `_fail`, `_warn`, etc.), and error handling are defined inline in `scaffold-vault.sh`. Per the CLI Style Guide, these belong in `src/lib/` as sourced libraries shared across all `src/bin/` scripts.
4. **`vault-files/` naming** — Does not follow the standard `src/templates/` taxonomy.
5. **No `config/base/version.json`** — Version is derived at release time from git tags rather than stored as a source-of-truth file.
6. **Release tags use bare semver** — Tags use `v0.5.0` format. The standard allows bare semver when the optional `build` key is omitted from `version.json`.
7. **`.gitattributes` incomplete** — Missing `eol=lf` enforcement on `.sh` files and executable permissions on product scripts.

---

## Target Structure

```
meridian/
├── src/
│   ├── bin/
│   │   ├── scaffold-vault.sh
│   │   ├── new-company.sh
│   │   ├── new-project.sh
│   │   └── weekly-snapshot.py
│   ├── lib/
│   │   ├── colors.sh
│   │   ├── logging.sh
│   │   └── errors.sh
│   └── templates/
│       ├── obsidian-templates/
│       │   ├── daily-note.md
│       │   ├── generic-note.md
│       │   └── reflection.md
│       ├── mocs/
│       │   ├── action-items.md
│       │   ├── active-projects.md
│       │   ├── open-loops.md
│       │   ├── review-queue.md
│       │   ├── weekly-outtake.md
│       │   └── current-priorities.md
│       └── northstar/
│           ├── purpose.md
│           ├── vision.md
│           ├── mission.md
│           ├── principles.md
│           ├── values.md
│           ├── goals.md
│           └── career.md
├── tests/
│   └── (existing tests, unchanged)
├── scripts/
│   ├── local/
│   └── ci/
│       └── release.sh
├── config/
│   └── base/
│       └── version.json
├── documentation/
│   └── (existing documentation, unchanged)
├── .github/workflows/
│   └── (existing workflows, unchanged)
├── .gitignore
├── .gitattributes
├── LICENSE
├── meridian-system.html
├── Meridian System.pdf
└── README.md
```

---

## Change Summary

### File moves

| Current location | Target location | Reason |
|---|---|---|
| `scaffold-vault.sh` | `src/bin/scaffold-vault.sh` | Product binary; belongs with delivered scripts |
| `scripts/new-company.sh` | `src/bin/new-company.sh` | Vault-delivered product script |
| `scripts/new-project.sh` | `src/bin/new-project.sh` | Vault-delivered product script |
| `scripts/weekly-snapshot.py` | `src/bin/weekly-snapshot.py` | Vault-delivered product script |
| `scripts/release.sh` | `scripts/ci/release.sh` | CI/CD tooling; not part of product delivery |
| `vault-files/templates/*` | `src/templates/obsidian-templates/*` | Standard templates taxonomy; kebab-case rename |
| `vault-files/mocs/*` | `src/templates/mocs/*` | Standard templates taxonomy; kebab-case rename |
| `vault-files/northstar/*` | `src/templates/northstar/*` | Standard templates taxonomy; kebab-case rename |

### New files

| File | Purpose |
|---|---|
| `src/lib/colors.sh` | TTY-aware color variable definitions per CLI Style Guide |
| `src/lib/logging.sh` | Output helpers: `_pass`, `_fail`, `_warn`, `_hint`, `_detail`, `_cmd` |
| `src/lib/errors.sh` | `die` function and shared error handling |
| `config/base/version.json` | Version source of truth |

### Removed directories

| Directory | Reason |
|---|---|
| `scripts/` (old root-level) | Empty after moves; replaced by new `scripts/ci/` |
| `vault-files/` | Empty after moves; replaced by `src/templates/` |

### Template file renames (kebab-case)

| Current filename | Target filename |
|---|---|
| `Daily Note.md` | `daily-note.md` |
| `Generic Note.md` | `generic-note.md` |
| `Reflection.md` | `reflection.md` |
| `Action Items.md` | `action-items.md` |
| `Active Projects.md` | `active-projects.md` |
| `Open Loops.md` | `open-loops.md` |
| `Review Queue.md` | `review-queue.md` |
| `Weekly Outtake.md` | `weekly-outtake.md` |
| `Current Priorities.md` | `current-priorities.md` |
| `Purpose.md` | `purpose.md` |
| `Vision.md` | `vision.md` |
| `Mission.md` | `mission.md` |
| `Principles.md` | `principles.md` |
| `Values.md` | `values.md` |
| `Goals.md` | `goals.md` |
| `Career.md` | `career.md` |

---

## Implementation Plan

### Phase 1 — Create directory skeleton

Create empty directories:

- `src/bin/`
- `src/lib/`
- `src/templates/obsidian-templates/`
- `src/templates/mocs/`
- `src/templates/northstar/`
- `scripts/local/`
- `scripts/ci/`
- `config/base/`

Add `.gitkeep` to `scripts/local/` only (it is the only directory that will remain empty after all moves are complete).

### Phase 2 — Move product scripts into `src/bin/`

- Move `scaffold-vault.sh` from repo root → `src/bin/scaffold-vault.sh`
- Move `scripts/new-company.sh` → `src/bin/new-company.sh`
- Move `scripts/new-project.sh` → `src/bin/new-project.sh`
- Move `scripts/weekly-snapshot.py` → `src/bin/weekly-snapshot.py`

Do not update internal path references yet — that happens in Phase 6.

### Phase 3 — Move CI script into `scripts/ci/`

- Move `scripts/release.sh` → `scripts/ci/release.sh`
- Delete the now-empty old `scripts/` directory

### Phase 4 — Relocate `vault-files/` to `src/templates/`

- Move `vault-files/templates/*` → `src/templates/obsidian-templates/` with kebab-case renaming
- Move `vault-files/mocs/*` → `src/templates/mocs/` with kebab-case renaming
- Move `vault-files/northstar/*` → `src/templates/northstar/` with kebab-case renaming
- Remove `vault-files/`

### Phase 5 — Extract shared libraries to `src/lib/`

Extract from `scaffold-vault.sh` (and any other scripts defining these inline):

**`src/lib/colors.sh`** — TTY-aware color variable block per CLI Style Guide. Defines `_C_GREEN`, `_C_RED`, `_C_AMBER`, `_C_CYAN`, `_C_RESET` with `[[ -t 1 ]]` guard.

**`src/lib/logging.sh`** — Output helper functions: `_pass`, `_fail`, `_warn`, `_hint`, `_detail`, `_cmd`. Sources `colors.sh` if color variables are not already defined.

**`src/lib/errors.sh`** — `die` function and shared error-handling patterns.

All three files:

- Include `# SOURCED LIBRARY — do not execute directly.` guard
- Use `_mer_` as the project-specific prefix for any private functions
- Do not include `set -euo pipefail` (caller's settings apply)

Update all `src/bin/` scripts to source these libraries instead of defining functions inline.

### Phase 6 — Update all internal path references

Full audit of every script for path correctness after the restructure:

**`src/bin/scaffold-vault.sh`:**

- Add `REPO_DIR` variable resolving to the repository root
- Replace `$SCRIPT_DIR/scripts/` references with `$REPO_DIR/src/bin/` paths
- Update `vault-files/` references to `$REPO_DIR/src/templates/obsidian-templates/`, `$REPO_DIR/src/templates/mocs/`, `$REPO_DIR/src/templates/northstar/`
- Update library sourcing to `$REPO_DIR/src/lib/`
- Update the copy logic that deploys scripts into the vault's `.scripts/` directory

**`src/bin/new-company.sh`:**

- Audit for any path references back to the repo structure

**`src/bin/new-project.sh`:**

- Audit for any path references back to the repo structure

**`src/bin/weekly-snapshot.py`:**

- Audit for any path references back to the repo structure (operates on the vault, likely no changes needed)

**`scripts/ci/release.sh`:**

- Update to read/write version from `config/base/version.json`
- Handle `build` key as optional: if present, increment and include in tag (`vMAJOR.MINOR.PATCH+BUILD`); if absent, use bare semver tags (`vMAJOR.MINOR.PATCH`)
- Update any path references to scripts or config that moved

### Phase 7 — Functional testing

Every script must be tested end-to-end after the restructure:

| Script | Test procedure |
|---|---|
| `scaffold-vault.sh --profile personal` | Verify full personal vault scaffolds correctly: all obsidian-templates, MOCs, northstar files present; scripts copied to vault `.scripts/`; documentation injected into `Process/Meridian Documentation/` |
| `scaffold-vault.sh --profile work` | Verify work vault scaffolds correctly: reduced folder set; no `Northstar/`, `Life/`, or `References/` directories created |
| `new-company.sh` | Run inside a scaffolded vault; verify directory creation under `Work/` |
| `new-project.sh` | Run inside a scaffolded vault; verify directory creation under target `Projects/` folder |
| `weekly-snapshot.py` | Run against a vault with daily notes; verify snapshot output in `Process/Weekly/` |
| `scripts/ci/release.sh` | Verify reads from `version.json`; increments correctly; produces correct tag format; handles optional `build` key |
| All library sourcing | Verify no "file not found" errors on `source` calls from any `src/bin/` script |
| Color and helpers | Verify `_pass`, `_fail`, `_warn`, `_hint`, `_detail`, `_cmd` render correctly in TTY and non-TTY (piped) contexts |

### Phase 8 — Add `config/base/version.json`

Create `version.json` with the current version derived from the latest git tag:

```json
{
  "semver": {
    "major": 0,
    "minor": 5,
    "patch": 0
  },
  "metadata": {
    "releaseDate": "YYYY-MM-DD",
    "gitCommit": "abc1234"
  }
}
```

The `build` key is optional. When omitted, `release.sh` produces bare semver tags (`v0.5.0`). When present, `release.sh` increments it and appends to the tag (`v0.5.0+1`).

### Phase 9 — Update `.gitattributes`

- Add `*.sh text eol=lf` for line ending consistency
- Set executable permissions on `src/bin/*.sh`

### Phase 10 — Update documentation

- **`README.md`** — Update directory layout, usage paths (e.g., `src/bin/scaffold-vault.sh` instead of `./scaffold-vault.sh`), clone instructions, and tag format documentation
- **`architecture.md`** — Update the Repository Structure section to reflect the new layout
- **`structure.md`** — Retire or mark as complete; migration plan is fulfilled

---

## Out of Scope

These items are intentionally omitted — the standard recommends them but does not require them for projects that do not use them:

| Item | Reason |
|---|---|
| `scripts/deploy/` | Meridian has no deployment pipeline; it scaffolds local vaults |
| `Makefile` | Not needed for this project |
| `config/local/`, `config/ci/` | No environment variable configuration needed |
| `scripts/local/dev-setup.sh` | No meaningful dev setup steps to automate; directory stubbed with `.gitkeep` |
| Test framework overhead | Existing tests in `tests/` retained as-is |
| GitHub Actions workflow changes | Existing workflows are fine |
| `meridian-system.html`, `Meridian System.pdf` | Remain at repo root, untouched |
| Agent guide (`agents/CLAUDE.bash.md`) | Lives at the project root level per the scaffolding standard, outside this repo |

---

## Changelog

| Version | Date | Changes |
|---|---|---|
| 1.0.0 | 2026-03-28 | Initial structure migration plan |
| 2.0.0 | 2026-03-30 | Full rewrite: corrected `scripts/ci/` path; added `src/lib/` extraction plan; corrected `vault-files/` → `src/templates/` mapping with `obsidian-templates/` subdirectory; added `version.json` with optional `build` key; added `.gitattributes` update; added functional testing phase; removed unnecessary stubs and framework overhead; documented out-of-scope items |
