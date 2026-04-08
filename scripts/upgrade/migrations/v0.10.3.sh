#!/usr/bin/env bash
# migrations/v0.10.3.sh — vault changes for Meridian 0.10.3
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# This migration sets the default attachment folder in .obsidian/app.json
# to a domain-scoped location matching the vault profile:
#
#   Personal vault (Life/ exists):  attachmentFolderPath → References
#   Work vault (Life/ absent):      attachmentFolderPath → Work/$COMPANY/Reference
#
# IMPORTANT: Run this upgrade with Obsidian closed. If Obsidian is open
# when app.json is modified, it will overwrite the file with its cached
# settings on close, discarding the migration changes.
#
# Detection is filesystem-based (idempotent):
#   Personal vault:  Life/ directory exists
#   Work vault:      Life/ directory does not exist
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

# Update or insert attachmentFolderPath in .obsidian/app.json.
# If the key exists: updates it in place with sed.
# If the key is absent but the file exists: prints a manual hint.
# If the file does not exist: no-op (scaffold will create it on next run).
_update_attachment_path() {
  local app_json="${VAULT_ROOT}/.obsidian/app.json"
  local new_path="$1"

  if [[ ! -f "$app_json" ]]; then
    _hint "app.json not found — attachment path will be set on next scaffold run."
    return
  fi

  if grep -q '"attachmentFolderPath"' "$app_json" 2>/dev/null; then
    sed -i.bak "s|\"attachmentFolderPath\":.*|\"attachmentFolderPath\": \"${new_path}\"|" "$app_json" \
      && rm -f "${app_json}.bak"
    _pass "Updated: .obsidian/app.json attachmentFolderPath → $new_path"
  else
    _hint "attachmentFolderPath not set in app.json."
    _hint "  Set manually: Settings → Files & Links → Default location for new attachments"
    _hint "  → In the folder specified below → $new_path"
  fi
}

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v0.10.3 global migrations..."
  echo ""

  if [[ -d "${VAULT_ROOT}/Life" ]]; then
    # Personal vault
    echo "  Personal vault detected — updating attachment folder..."
    _update_attachment_path "References"
  else
    # Work vault — deferred to per-company section
    _detail "Work vault detected — attachment path update deferred to per-company step."
  fi

  echo ""
  _pass "v0.10.3 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v0.10.3 company migrations: $COMPANY..."
  echo ""

  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"

  if [[ ! -d "$COMPANY_DIR" ]]; then
    _warn "Company directory not found, skipping: Work/${COMPANY}"
    exit 0
  fi

  if [[ ! -d "${VAULT_ROOT}/Life" ]]; then
    # Work vault only
    echo "  Updating attachment folder..."
    _update_attachment_path "Work/${COMPANY}/Reference"
    echo ""
  else
    _detail "Personal vault — attachment path updated in global step."
    echo ""
  fi

  _pass "v0.10.3 company migrations complete: $COMPANY"
fi
