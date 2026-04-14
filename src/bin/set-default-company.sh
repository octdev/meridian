#!/usr/bin/env bash
# set-default-company.sh — set the default company in a Meridian vault
# Usage: set-default-company.sh --vault <path> --company <name>
#        set-default-company.sh            (all inputs prompted interactively)
#
# Updates DefaultCompany= in .scripts/.vault-version. The default company is
# used by resolve_company as a fallback when daily-notes.json is absent or unset.
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
COMPANY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="${2:?--vault requires a path}";   shift 2 ;;
    --company) COMPANY="${2:?--company requires a name}"; shift 2 ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

# ── Vault validation ──────────────────────────────────────────────────────────

echo ""
echo "[meridian] Set Default Company"
echo ""

if [[ -z "$VAULT" ]]; then
  if [[ -n "${MERIDIAN_VAULT:-}" ]]; then
    VAULT="$MERIDIAN_VAULT"
  else
    if [[ -d "${SCRIPT_DIR}/../lib" ]]; then
      REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    else
      REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
    fi
    select_vault
    VAULT="${VAULT_ROOT:-}"
  fi
fi

VAULT="${VAULT/#\~/$HOME}"
VAULT="${VAULT%/}"
[[ -d "$VAULT" ]] || die "Vault not found: $VAULT" ""
[[ -d "$VAULT/Work" ]] || die "Work/ directory not found in vault: $VAULT/Work" "Run scaffold-vault.sh first."

# ── Company selection ─────────────────────────────────────────────────────────

if [[ -z "$COMPANY" ]]; then
  detect_companies "$VAULT"
  if [[ ${#DETECTED_COMPANIES[@]} -eq 0 ]]; then
    die "No companies found under $VAULT/Work" "Create one with new-company.sh first."
  fi
  echo "  Known companies:"
  for _i in "${!DETECTED_COMPANIES[@]}"; do
    _hint "    $((_i+1)). ${DETECTED_COMPANIES[$_i]}"
  done
  echo ""
  read -rp "  Select company [1] or enter name: " _co_input
  echo ""
  if [[ -z "$_co_input" || "$_co_input" == "1" ]]; then
    COMPANY="${DETECTED_COMPANIES[0]}"
  elif [[ "$_co_input" =~ ^[0-9]+$ ]] && \
       [[ "$_co_input" -ge 1 && "$_co_input" -le ${#DETECTED_COMPANIES[@]} ]]; then
    COMPANY="${DETECTED_COMPANIES[$((_co_input-1))]}"
  else
    COMPANY="$_co_input"
  fi
fi

[[ -n "$COMPANY" ]] || die "Company name cannot be empty." ""
[[ -d "$VAULT/Work/$COMPANY" ]] || die "Company not found: $VAULT/Work/$COMPANY" ""

# ── Update default ────────────────────────────────────────────────────────────

set_default_company "$VAULT" "$COMPANY"
_pass "Default company set to: $COMPANY"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
printf "${_C_GREEN}[meridian] Done.${_C_RESET}\n"
echo ""
