#!/usr/bin/env bash
# migrations/v1.2.0.sh — vault changes for Meridian 1.2.0
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# Changes in this release:
#   Per-company: Current Priorities.md moved from Process/ to Work/<Company>/Goals/
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

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v1.2.0 global migrations..."
  echo ""
  _detail "No global vault changes in this release."
  echo ""
  _pass "v1.2.0 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v1.2.0 company migrations: $COMPANY..."
  echo ""

  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"

  if [[ ! -d "$COMPANY_DIR" ]]; then
    _warn "Company directory not found, skipping: Work/${COMPANY}"
    exit 0
  fi

  SRC="${VAULT_ROOT}/Process/Current Priorities.md"
  DEST_DIR="${COMPANY_DIR}/Goals"
  DEST="${DEST_DIR}/Current Priorities.md"

  # Ensure Goals/ exists (should already, but guard for older vaults)
  if [[ ! -d "$DEST_DIR" ]]; then
    mkdir -p "$DEST_DIR" || die "mkdir" "Could not create: Work/${COMPANY}/Goals"
    _pass "Created: Work/${COMPANY}/Goals/"
  fi

  if [[ -f "$SRC" ]]; then
    if [[ -f "$DEST" ]]; then
      echo "  — Skipped (destination exists): Work/${COMPANY}/Goals/Current Priorities.md"
      _hint "Review and remove Process/Current Priorities.md manually if no longer needed."
    else
      mv "$SRC" "$DEST" || die "mv" "Could not move Current Priorities.md"
      _pass "Moved: Process/Current Priorities.md → Work/${COMPANY}/Goals/Current Priorities.md"
      _hint "Review the file — your existing priorities have been preserved."
    fi
  else
    _detail "Process/Current Priorities.md not found — nothing to move."
  fi

  echo ""
  _pass "v1.2.0 company migrations complete: $COMPANY"
fi
