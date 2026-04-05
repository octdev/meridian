# Upgrades

This document covers how to upgrade an existing Meridian vault, how work vault versioning works across multiple employers, and the technical mechanics behind the upgrade system — including enough detail for a developer to write upgrade scripts for future versions.

## Table of Contents

1. [[#Running an Upgrade]]
2. [[#Work Vaults and Version Eligibility]]
3. [[#How the Upgrade System Works]]
4. [[#Writing Upgrade Scripts (Developer Guide)]]

---

## Running an Upgrade

Upgrades are run from the Meridian repo using `scaffold-vault.sh`. This is the only command you need:

```bash
./src/bin/scaffold-vault.sh --upgrade
```

The script will:

1. **Select a vault.** If you have registered vaults, they are presented as a numbered list. Press Enter to accept the default (most recently used), enter a number to select another, or type a path directly.

2. **Show version information.** The installed vault version and the target Meridian version are displayed before anything changes.

3. **Prompt for company vault selection.** Any companies under `Work/` that are eligible for upgrade are listed. You can upgrade all of them, a subset, or none. See [[#Work Vaults and Version Eligibility]] for what eligibility means and why it matters.

4. **Apply migrations.** Version-specific changes are applied in order from your installed version to the target. Each step is confirmed before the next begins.

5. **Refresh documentation.** All files in `Process/Meridian Documentation/` are replaced with the latest versions from the repo. Your own notes are never touched.

6. **Report success.** The vault version and repo version are updated to reflect the new version.

To check your current versions at any time:

```bash
./src/bin/scaffold-vault.sh --version
```

This shows the Meridian project version, your vault's installed version, and the version of each company vault.

---

## Work Vaults and Version Eligibility

### The Version Contract

Every company folder under `Work/` has its own tracked version. When you upgrade your vault, you choose which company folders to include. A company is **eligible** for upgrade only if its recorded version matches the vault's current installed version — meaning it has been kept current through every prior upgrade.

A company folder that was skipped during any previous upgrade falls behind and **cannot be upgraded in future versions**. This is by design: migrations are written to transform a known state into the next known state. A folder that missed an intermediate step is in an unknown state and cannot be safely advanced.

### Active vs. Inactive Jobs

This constraint is intentional and reflects a practical reality: you will likely use Meridian across multiple employers over time, but you only actively work in one (or occasionally two) at a time.

**The intended pattern:**

- **Current employer:** Always upgrade. Keep the company vault in sync with every release.
- **Previous employers:** Leave them. Once you have moved on, the historical record in that folder is complete. There is no benefit to upgrading it, and no cost to leaving it behind.

When the upgrade prompt lists eligible companies, it will exclude any that have already fallen behind. If you see a company marked ineligible, it means it was skipped in a previous upgrade. That vault is a read-only historical record at this point — which is usually exactly what you want.

### If You Accidentally Skip a Current Employer

If you skip your active employer's vault during an upgrade, you will see a warning before the upgrade proceeds. Take that warning seriously. If you proceed without upgrading the active company, you will need to manually recreate any migration changes in that folder, or accept that it will not receive future upgrades.

---

## How the Upgrade System Works

### Version Tracking

Each vault contains a version tracking file at `.scripts/.vault-version`. It uses a key=value format:

```
vault=1.2.0
AcmeCorp-vault=1.2.0
PreviousJob-vault=1.1.0
```

The `vault=` key tracks the main vault version. Each `[Company]-vault=` key tracks that company folder's version independently. This file is created at scaffold time and updated after each successful migration step.

The Meridian repo tracks its current version in `config/base/version.json`. The `--version` flag reads both this file and the vault's `.vault-version` to show you where things stand.

### The Migration Chain

Upgrade scripts live in `scripts/upgrade/`. When `scaffold-vault.sh --upgrade` is run, it determines the current Meridian version and delegates to the matching entry point script:

```
scripts/upgrade/
  upgrade-runner.sh          # shared library — orchestrates everything
  upgrade-to-1.2.0.sh        # entry point for this version
  migrations/
    v1.0.1.sh
    v1.1.0.sh
    v1.2.0.sh
```

The runner discovers all migration scripts between the vault's installed version and the target version, sorts them by semantic version, and executes them **in order**. If your vault is at `1.0.0` and the target is `1.2.0`, the runner will apply `v1.0.1.sh`, `v1.1.0.sh`, and `v1.2.0.sh` in sequence. Each script brings the vault one step forward; no script assumes a starting state other than the version immediately before it.

The vault version in `.vault-version` is updated after **each individual migration step**. If a migration fails mid-chain, the vault is left at the last successfully completed version — not rolled back to the start, and not left in an ambiguous state.

### Global vs. Per-Company Migrations

Each migration script handles two categories of changes, controlled by whether a third argument is passed:

- **Global changes** (`$3` absent): Changes that apply to the vault as a whole — new templates, new MOC files, new Obsidian config, new scripts in `.scripts/`.
- **Per-company changes** (`$3` = company name): Changes that apply inside a specific `Work/[Company]/` folder — new subfolders, new seed files scoped to that employer.

The runner calls each applicable migration script twice per company: once for global changes (no `$3`), then once per selected company (with `$3` set to the company name).

### Documentation Refresh

After all migrations complete successfully, the runner **always** overwrites every file in `Process/Meridian Documentation/` with the latest version from the repo. This happens regardless of whether there were any migration scripts to run. Documentation is always current after an upgrade.

### Version Bump

As the final step, the runner updates `config/base/version.json` in the repo to the target version. This keeps the repo version in sync with what has been applied.

---

## Writing Upgrade Scripts (Developer Guide)

### When to Create an Upgrade Script

Every release that changes anything inside a vault — new files, new folders, new templates, changed configuration — requires an upgrade script. Even releases with no vault-visible changes should have a migration script (it can be a no-op stub) so the version chain stays complete.

Create an upgrade script as part of the same commit that bumps `config/base/version.json`.

### File Naming and Location

```
scripts/upgrade/upgrade-to-X.Y.Z.sh     # entry point
scripts/upgrade/migrations/vX.Y.Z.sh    # migration logic
```

Replace `X.Y.Z` with the new semantic version. Both files are required for every release.

### The Entry Point

The entry point is always three lines:

```bash
#!/usr/bin/env bash
# upgrade-to-1.3.0.sh — upgrades a Meridian vault to version 1.3.0
#
# Usage:
#   upgrade-to-1.3.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 1.3.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "1.3.0" "${SCRIPT_DIR}/migrations" "$@"
```

Change the version string in two places (the comment and the `run_upgrade_to` call) and nothing else.

### The Migration Script

```bash
#!/usr/bin/env bash
# migrations/v1.3.0.sh — vault changes for Meridian 1.3.0
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name; absent = global, set = per-company

set -euo pipefail

readonly VAULT_ROOT="$1"
readonly REPO_DIR="$2"
readonly COMPANY="${3:-}"

source "${REPO_DIR}/src/lib/logging.sh"
source "${REPO_DIR}/src/lib/errors.sh"

# Define helpers inline — each migration is self-contained.
copy_if_new() { ... }
write_if_new() { ... }

# --- global changes ---
if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v1.3.0 global migrations..."
  # Apply vault-wide changes here.
  _pass "v1.3.0 global migrations complete."

# --- per-company changes ---
else
  echo "[meridian] v1.3.0 company migrations: $COMPANY..."
  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"
  # Apply changes inside Work/$COMPANY/ here.
  _pass "v1.3.0 company migrations complete: $COMPANY"
fi
```

### Rules

- **Never touch a previous migration script.** Each script is a sealed record of what that version required. If a prior migration had a bug, write a corrective step in the next version's script.
- **Never overwrite user content.** Use `copy_if_new` and `write_if_new` (skip-if-exists) for all vault files. The only exception is documentation in `Process/Meridian Documentation/`, which the runner always overwrites automatically — do not replicate that logic in migration scripts.
- **Define helpers inline.** Each migration script sources only `logging.sh` and `errors.sh` from `src/lib/`. If you need `copy_if_new`, `write_if_new`, or similar helpers, define them in the script. This keeps every migration self-contained and prevents cross-script dependencies.
- **Do not refresh docs or bump the version.** The runner handles both of these after all migrations complete. Migration scripts apply vault changes only.
- **Global changes before per-company changes.** The runner applies global migrations first across all versions in the chain, then per-company migrations. Write each script so it behaves correctly in this order.

### Checklist for a New Release

- [ ] Create `scripts/upgrade/migrations/vX.Y.Z.sh` with global and per-company sections
- [ ] Create `scripts/upgrade/upgrade-to-X.Y.Z.sh` entry point
- [ ] Update `config/base/version.json` to `X.Y.Z`
- [ ] Add `Upgrades.md` copy call to `scaffold-vault.sh` and `_refresh_vault_docs` in `upgrade-runner.sh` if new doc files were added
- [ ] Update `documentation/Architecture.md` repo and vault structure diagrams if files or folders changed
- [ ] Commit all four changes together
