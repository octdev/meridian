#!/usr/bin/env bash
# migrations/v1.0.0.sh — vault changes for Meridian 1.0.0
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# This release contains documentation updates only. No structural vault changes
# are required. Documentation is refreshed automatically by upgrade-runner.sh
# after all migrations complete.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

readonly VAULT_ROOT="$1"
readonly REPO_DIR="$2"
readonly COMPANY="${3:-}"

source "${REPO_DIR}/src/lib/logging.sh"

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v1.0.0 global migrations..."
  echo ""
  _detail "Documentation-only release — no structural changes required."
  echo ""
  _pass "v1.0.0 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v1.0.0 company migrations: $COMPANY..."
  echo ""
  _detail "Documentation-only release — no per-company changes required."
  echo ""
  _pass "v1.0.0 company migrations complete: $COMPANY"
fi
