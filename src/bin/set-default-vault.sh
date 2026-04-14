#!/usr/bin/env bash
# set-default-vault.sh — set the default vault in the Meridian registry
# Usage: set-default-vault.sh --vault <path>
#        set-default-vault.sh            (all inputs prompted interactively)
#
# Updates config/vaults.txt so the chosen vault appears first (the default).
# The first entry in vaults.txt is used as the default by select_vault.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# In-repo: src/bin/../lib/ = src/lib/  |  In vault: .scripts/../lib/ falls back to .scripts/lib/
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -d "$LIB_DIR" ]] || LIB_DIR="${SCRIPT_DIR}/lib"

source "$LIB_DIR/colors.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/errors.sh"
source "$LIB_DIR/vault-select.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────

VAULT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT="${2:?--vault requires a path}"; shift 2 ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

# ── Header ────────────────────────────────────────────────────────────────────

echo ""
echo "[meridian] Set Default Vault"
echo ""

# REPO_DIR is needed by register_vault to locate config/vaults.txt
if [[ -d "${SCRIPT_DIR}/../lib" ]]; then
  REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
else
  REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

# ── Vault selection ───────────────────────────────────────────────────────────

if [[ -z "$VAULT" ]]; then
  if [[ -n "${MERIDIAN_VAULT:-}" ]]; then
    VAULT="$MERIDIAN_VAULT"
  else
    load_known_vaults
    if [[ ${#KNOWN_VAULTS[@]} -eq 0 ]]; then
      die "No known vaults found in registry." "Run scaffold-vault.sh first."
    fi
    select_vault
    VAULT="${VAULT_ROOT:-}"
  fi
fi

VAULT="${VAULT/#\~/$HOME}"
VAULT="${VAULT%/}"
[[ -d "$VAULT" ]] || die "Vault not found: $VAULT" ""

# ── Register as default ───────────────────────────────────────────────────────

register_vault "$VAULT"
_pass "Default vault set to: $VAULT"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
printf "${_C_GREEN}[meridian] Done.${_C_RESET}\n"
echo ""
