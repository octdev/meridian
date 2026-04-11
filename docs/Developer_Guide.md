# Developer Guide

Reference for contributors and maintainers working on the Meridian project itself.

---

## Writing Upgrade Scripts

### When to Create an Upgrade Script

Every release that changes anything inside a vault — new files, new folders, new templates, changed configuration — requires an upgrade script. Releases with no structural vault changes (docs-only, repo reorganization) do not need an entry point or migration script; the runner handles them automatically.

Create upgrade scripts as part of the same commit that bumps `config/base/version.json`.

### File Naming and Location

```
scripts/upgrade/upgrade-to-X.Y.Z.sh     # entry point (structural releases only)
scripts/upgrade/migrations/vX.Y.Z.sh    # migration logic (structural releases only)
```

Replace `X.Y.Z` with the new semantic version.

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

- [ ] Review `docs/next-release.md` — translate accumulated migration notes into the scripts below, then clear the file
- [ ] Create `scripts/upgrade/migrations/vX.Y.Z.sh` with global and per-company sections
- [ ] Create `scripts/upgrade/upgrade-to-X.Y.Z.sh` entry point
- [ ] Update `config/base/version.json` to `X.Y.Z`
- [ ] Add `Upgrading.md` copy call to `scaffold-vault.sh` and `refresh_vault_docs` in `refresh-vault-docs.sh` if new doc files were added
- [ ] Update `src/documentation/Architecture.md` repo and vault structure diagrams if files or folders changed
- [ ] Commit all changes together
