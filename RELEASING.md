# Releasing Meridian

## Overview

The release process is split into two phases with a mandatory validation gap between them:

```
version.sh  →  write & test migration scripts  →  release.sh
```

`version.sh` bumps the version and updates the README. `release.sh` commits, tags, and pushes. What gets tagged is exactly what you tested — nothing changes between validation and release.

---

## Quick Reference

```bash
# 1. Bump version
scripts/ci/version.sh

# 2. Write migration scripts (if structural vault changes exist)
#    See docs/next-release.md for accumulated notes
#    scripts/upgrade/migrations/vX.Y.Z.sh
#    scripts/upgrade/upgrade-to-X.Y.Z.sh

# 3. Validate
scripts/ci/test-vault.sh   # or manually: scaffold-vault.sh --upgrade against a test vault

# 4. Stage everything
git add config/base/version.json README.md scripts/upgrade/...  src/documentation/...

# 5. Release
scripts/ci/release.sh
```

---

## Phase 1: Bump the Version

```bash
scripts/ci/version.sh
```

Prompts for patch / minor / major / specific version, then:

- Updates `config/base/version.json` with the new semver
- Updates the `git clone --branch` command in `README.md`
- Prints next-steps guidance and exits

The working tree is intentionally left dirty. Do not commit yet.

---

## Migration Scripts

Every release that changes vault structure — new files, new folders, new templates, changed Obsidian config — requires two scripts. Docs-only and repo-only releases do not; the upgrade runner handles them automatically.

### When migration scripts are needed

| Change type | Scripts needed |
|---|---|
| New folder under vault root or `Work/<Company>/` | Yes |
| New or moved seed file in the vault | Yes |
| Changed `.obsidian/` config | Yes |
| Changed or new template in `_templates/` | Yes |
| Documentation changes only | No |
| Repo structure changes only (no vault impact) | No |

Check `docs/next-release.md` for any migration notes accumulated since the last release.

### File locations

```
scripts/upgrade/upgrade-to-X.Y.Z.sh     # entry point
scripts/upgrade/migrations/vX.Y.Z.sh    # migration logic
```

### Entry point

The entry point is always the same three-line structure. Copy the previous one and change the version in two places:

```bash
#!/usr/bin/env bash
# upgrade-to-X.Y.Z.sh — upgrades a Meridian vault to version X.Y.Z
#
# Usage:
#   upgrade-to-X.Y.Z.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and X.Y.Z in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "X.Y.Z" "${SCRIPT_DIR}/migrations" "$@"
```

### Migration script

Each migration script receives three arguments and handles two passes:

| Arg | Value |
|-----|-------|
| `$1` | `VAULT_ROOT` — absolute path to the vault |
| `$2` | `REPO_DIR` — absolute path to the repo |
| `$3` | `COMPANY` — set for per-company pass; absent for global pass |

The upgrade runner calls each migration script twice per company: once without `$3` (global vault changes), then once per selected company with `$3` set to the company name.

```bash
#!/usr/bin/env bash
# migrations/vX.Y.Z.sh — vault changes for Meridian X.Y.Z
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
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

# Define helpers inline — each migration must be self-contained.
copy_if_new() {
  local src="$1" dest="$2"
  [[ ! -f "$src" ]] && { _warn "Source not found, skipping: $(basename "$src")"; return; }
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest" || die "copy-file" "Could not copy to: $dest"
    _pass "Created: ${dest#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${dest#$VAULT_ROOT/}"
  fi
}

write_if_new() {
  local filepath="$1" content="$2"
  if [[ ! -f "$filepath" ]]; then
    printf '%s\n' "$content" > "$filepath" || die "write-file" "Could not write: $filepath"
    _pass "Created: ${filepath#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${filepath#$VAULT_ROOT/}"
  fi
}

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] vX.Y.Z global migrations..."
  echo ""

  # Apply vault-wide changes here.
  # Examples:
  #   mkdir -p "$VAULT_ROOT/NewFolder"
  #   copy_if_new "$REPO_DIR/src/templates/..." "$VAULT_ROOT/Process/..."

  _pass "vX.Y.Z global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] vX.Y.Z company migrations: $COMPANY..."
  echo ""
  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"

  # Apply changes inside Work/$COMPANY/ here.
  # Examples:
  #   mkdir -p "$COMPANY_DIR/NewSubfolder"
  #   copy_if_new "$REPO_DIR/src/templates/..." "$COMPANY_DIR/..."

  _pass "vX.Y.Z company migrations complete: $COMPANY"
fi
```

### Docs-only releases

If the release has no structural vault changes, the migration script is a no-op. See `scripts/upgrade/migrations/v1.0.0.sh` as a reference. The upgrade runner still refreshes `Process/Meridian Documentation/` automatically — no migration logic required.

### Rules

- **Never modify a previous migration script.** Each is a sealed record. Correct mistakes in the next version's script.
- **Never overwrite user content.** Use `copy_if_new` and `write_if_new` for all vault files. The only exception is `Process/Meridian Documentation/`, which the runner always overwrites — do not replicate that in migration scripts.
- **Define helpers inline.** Each script sources only `logging.sh` and `errors.sh`. If you need `copy_if_new`, `write_if_new`, or similar, define them in the script itself.
- **Do not refresh docs or bump the version.** The runner handles both after all migrations complete.

---

## Validation

Before staging and releasing, test the upgrade against a real vault:

```bash
# Scaffold a fresh test vault
src/bin/scaffold-vault.sh --vault ~/Documents/TestVault

# Run the upgrade (version.json has already been bumped by version.sh)
src/bin/scaffold-vault.sh --upgrade --vault ~/Documents/TestVault
```

Verify that:

- All new folders and files were created
- Existing user content was not overwritten
- `Process/Meridian Documentation/` reflects the latest docs
- `.scripts/.vault-version` shows the new version

Fix any issues in the migration scripts and re-run until clean. Since the version bump and README update are already in place, your test environment is identical to what will ship.

---

## Phase 2: Commit and Tag

Once validation passes, stage everything that belongs in the release commit:

```bash
git add config/base/version.json
git add README.md
git add scripts/upgrade/migrations/vX.Y.Z.sh
git add scripts/upgrade/upgrade-to-X.Y.Z.sh
git add src/documentation/...    # any updated docs
# etc.
```

Then release:

```bash
scripts/ci/release.sh
```

`release.sh` reads the target version directly from `version.json`, shows you the staged file list, asks for confirmation, then:

1. Commits all staged changes as `Release vX.Y.Z`
2. Creates annotated tag `vX.Y.Z`
3. Pushes the commit
4. Pushes the version tag
5. Force-moves `latest` to the same commit and pushes it

After this completes, `vX.Y.Z` and `latest` both point to the release commit.

---

## Tag Strategy

| Tag | Purpose |
|-----|---------|
| `vX.Y.Z` | Permanent, immutable release marker |
| `latest` | Mutable pointer — always the most recent release |

Users clone with `--branch latest`. The `--force` push on `latest` is intentional; it is a convenience pointer, not a release artifact.

---

## Tracking Migration Work During Development

As you make structural vault changes between releases, record what the migration script will need to do in `docs/next-release.md`. Use the global / per-company sections there to mirror the migration script structure. This keeps migration intent close to the code change that requires it, and makes writing the migration script at release time mechanical rather than reconstructed from memory.

Clear `docs/next-release.md` after the release scripts are written and validated.

---

## Full Release Checklist

- [ ] `scripts/ci/version.sh` — bump version, update README
- [ ] Review `docs/next-release.md` — translate migration notes into scripts
- [ ] Create `scripts/upgrade/migrations/vX.Y.Z.sh`
- [ ] Create `scripts/upgrade/upgrade-to-X.Y.Z.sh`
- [ ] Update `src/documentation/` for any user-visible changes
- [ ] Update `src/documentation/Architecture.md` if files or folders changed
- [ ] Validate: `scaffold-vault.sh --upgrade` against a test vault
- [ ] `git add` all release files
- [ ] `scripts/ci/release.sh` — commit, tag, push
- [ ] Clear `docs/next-release.md`
