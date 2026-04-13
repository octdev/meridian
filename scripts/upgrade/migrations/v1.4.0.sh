#!/usr/bin/env bash
# migrations/v1.4.0.sh — vault changes for Meridian 1.4.0
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
#   Global: new-1on1.sh deployed to .scripts/
#   Global: new-company.sh, new-project.sh, new-meeting-series.sh refreshed in .scripts/
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
  echo "[meridian] v1.4.0 global migrations..."
  echo ""

  SCRIPTS_DIR="${VAULT_ROOT}/.scripts"

  if [[ ! -d "$SCRIPTS_DIR" ]]; then
    die "v1.4.0" ".scripts/ directory not found in vault: $VAULT_ROOT"
  fi

  # Deploy new-1on1.sh (new in this release)
  SRC_1ON1="${REPO_DIR}/src/bin/new-1on1.sh"
  DEST_1ON1="${SCRIPTS_DIR}/new-1on1.sh"
  if [[ ! -f "$SRC_1ON1" ]]; then
    die "v1.4.0" "Source not found: src/bin/new-1on1.sh"
  fi
  cp "$SRC_1ON1" "$DEST_1ON1" || die "v1.4.0" "Could not copy new-1on1.sh"
  chmod +x "$DEST_1ON1" 2>/dev/null || true
  _pass "Deployed: .scripts/new-1on1.sh"

  # Refresh updated scripts
  for script in new-company.sh new-project.sh new-meeting-series.sh; do
    SRC="${REPO_DIR}/src/bin/${script}"
    DEST="${SCRIPTS_DIR}/${script}"
    if [[ ! -f "$SRC" ]]; then
      _warn "Source not found, skipping: src/bin/${script}"
      continue
    fi
    cp "$SRC" "$DEST" || die "v1.4.0" "Could not update ${script}"
    chmod +x "$DEST" 2>/dev/null || true
    _pass "Updated:  .scripts/${script}"
  done

  echo ""
  _pass "v1.4.0 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v1.4.0 company migrations: $COMPANY..."
  echo ""
  _detail "No per-company changes in this release."
  echo ""
  _pass "v1.4.0 company migrations complete: $COMPANY"
fi
