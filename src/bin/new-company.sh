#!/usr/bin/env bash
# new-company.sh — scaffold a new company under Work/ in a Meridian vault
# Usage: new-company.sh --vault <path> --company <name>
#        new-company.sh            (all inputs prompted interactively)
#
# Creates the standard company folder structure and seeds Current Priorities.
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
echo "[meridian] New Company"
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

# ── Company name ──────────────────────────────────────────────────────────────

if [[ -z "$COMPANY" ]]; then
  echo ""
  _detail "Existing companies:"
  shopt -s nullglob
  for d in "$VAULT/Work"/*/; do
    [[ -d "$d" ]] && _detail "  $(basename "$d")"
  done
  shopt -u nullglob
  echo ""
  read -rp "$(printf "${_C_CYAN}Company name (case-sensitive, used as folder name):${_C_RESET} ")" COMPANY
fi

[[ -n "$COMPANY" ]] || die "Company name cannot be empty." ""

# ── Collision check ───────────────────────────────────────────────────────────

COMPANY_DIR="$VAULT/Work/$COMPANY"

if [[ -e "$COMPANY_DIR" ]]; then
  die "Company already exists: $COMPANY_DIR" "Choose a different name or verify you are not duplicating an existing company."
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
_detail "Company:  $COMPANY"
_detail "Location: $COMPANY_DIR"
echo ""
read -rp "$(printf "${_C_CYAN}Create? [Y/n]:${_C_RESET} ")" CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }

# ── Create folder structure ───────────────────────────────────────────────────

echo ""
mkdir -p "$COMPANY_DIR/Daily"
mkdir -p "$COMPANY_DIR/Drafts"
mkdir -p "$COMPANY_DIR/Finances"
mkdir -p "$COMPANY_DIR/General"
mkdir -p "$COMPANY_DIR/Goals"
mkdir -p "$COMPANY_DIR/Incidents"
mkdir -p "$COMPANY_DIR/Knowledge/Technical"
mkdir -p "$COMPANY_DIR/Knowledge/Leadership"
mkdir -p "$COMPANY_DIR/Knowledge/Industry"
mkdir -p "$COMPANY_DIR/Meetings"
mkdir -p "$COMPANY_DIR/Meetings/1on1s"
mkdir -p "$COMPANY_DIR/Meetings/Series"
mkdir -p "$COMPANY_DIR/Meetings/Single"
mkdir -p "$COMPANY_DIR/People"
mkdir -p "$COMPANY_DIR/Projects"
mkdir -p "$COMPANY_DIR/Reference"
mkdir -p "$COMPANY_DIR/Vendors"

_pass "Folder structure created."

# ── Seed Current Priorities ───────────────────────────────────────────────────

NOW=$(date "+%Y-%m-%d %H:%M:%S")
PRIORITIES_FILE="$COMPANY_DIR/Goals/Current Priorities.md"

cat > "$PRIORITIES_FILE" <<EOF
---
title: Current Priorities
created: $NOW
modified: $NOW
---
# Current Priorities

## Annual
-

## Quarter
-

## Month
-

## Week
-
EOF

_pass "Goals/Current Priorities.md created."

# ── Update daily-notes.json ───────────────────────────────────────────────────

DAILY_CONFIG="$VAULT/.obsidian/daily-notes.json"
cat > "$DAILY_CONFIG" <<EOF
{
  "folder": "Work/$COMPANY/Daily",
  "template": "_templates/Daily Note",
  "format": "YYYY-MM-DD",
  "autorun": false
}
EOF

_pass "Daily notes config updated → Work/$COMPANY/Daily"

# ── Register company in .vault-version ───────────────────────────────────────

VAULT_VERSION_FILE="$VAULT/.scripts/.vault-version"
if [[ -f "$VAULT_VERSION_FILE" ]]; then
  VAULT_VER="$(grep "^vault=" "$VAULT_VERSION_FILE" 2>/dev/null | cut -d= -f2)" || true
  if [[ -n "$VAULT_VER" ]]; then
    echo "${COMPANY}-vault=${VAULT_VER}" >> "$VAULT_VERSION_FILE"
    _pass ".vault-version updated: $COMPANY registered at $VAULT_VER"
  fi
fi

# ── Set as default company ────────────────────────────────────────────────────

set_default_company "$VAULT" "$COMPANY"
_pass "Default company set to: $COMPANY"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
printf "${_C_GREEN}[meridian] Company scaffolded.${_C_RESET}\n"
echo ""
_detail "Location: $COMPANY_DIR"
_hint "Run 'New Project' to add a project under $COMPANY/Projects/"
_hint "Rename the active company in .obsidian/daily-notes.json if needed."
echo ""
