#!/usr/bin/env bash
# new-meeting-series.sh — scaffold a meeting series instance in Meridian
# Usage: new-meeting-series.sh --vault <path> [--company <name>] [--series <name>] [--purpose <text>] [--cadence <text>]
# Creates or updates a meeting series instance at Meetings/Series/<Series>/<Date>/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- libraries ---
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
SERIES=""
PURPOSE=""
CADENCE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="${2:?--vault requires a path}";        shift 2 ;;
    --company) COMPANY="${2:?--company requires a name}";    shift 2 ;;
    --series)  SERIES="${2:?--series requires a name}";      shift 2 ;;
    --purpose) PURPOSE="${2:?--purpose requires a value}";   shift 2 ;;
    --cadence) CADENCE="${2:?--cadence requires a value}";   shift 2 ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

# ── Vault validation ──────────────────────────────────────────────────────────

if [[ -z "$VAULT" ]]; then
  if [[ -n "${MERIDIAN_VAULT:-}" ]]; then
    VAULT="$MERIDIAN_VAULT"
  else
    if [[ -d "${SCRIPT_DIR}/../lib" ]]; then
      REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
    else
      REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
    fi
    source "$LIB_DIR/vault-select.sh"
    select_vault
    VAULT="${VAULT_ROOT:-}"
  fi
fi

VAULT="${VAULT/#\~/$HOME}"
VAULT="${VAULT%/}"
[[ -d "$VAULT" ]] || die "Vault not found: $VAULT" ""

# ── Company resolution ────────────────────────────────────────────────────────

if [[ -z "${REPO_DIR:-}" ]]; then
  if [[ -d "${SCRIPT_DIR}/../lib" ]]; then
    REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
  else
    REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
  fi
fi

if [[ -n "$COMPANY" ]]; then
  CURRENT_COMPANY="$COMPANY"
else
  resolve_company "$VAULT"
  [[ -n "$CURRENT_COMPANY" ]] || die "Could not determine active company." ""
fi

MEETINGS_DIR="$VAULT/Work/$CURRENT_COMPANY/Meetings"
[[ -d "$MEETINGS_DIR" ]] || die "Meetings directory not found: $MEETINGS_DIR" "Run scaffold-vault.sh first or create Work/$CURRENT_COMPANY/Meetings/ manually."

# ── Series name ───────────────────────────────────────────────────────────────

if [[ -z "$SERIES" ]]; then
  echo ""
  _detail "Existing series:"
  for d in "$MEETINGS_DIR/Series"/*/; do
    [[ -d "$d" ]] && _detail "  $(basename "$d")"
  done
  echo ""
  read -rp "$(printf "${_C_CYAN}Series name (e.g. Org Associates):${_C_RESET} ")" SERIES
fi

[[ -n "$SERIES" ]] || die "Series name cannot be empty." ""

# ── Path construction ─────────────────────────────────────────────────────────

DATE=$(date +%Y-%m-%d)

SERIES_DIR="$MEETINGS_DIR/Series/$SERIES"
INSTANCE_DIR="$SERIES_DIR/$DATE"
INSTANCE_FILE="$INSTANCE_DIR/$SERIES $DATE.md"
SERIES_INDEX="$SERIES_DIR/$SERIES.md"
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# ── Collision check ───────────────────────────────────────────────────────────

if [[ -d "$INSTANCE_DIR" ]]; then
  die "Instance already exists: $INSTANCE_DIR" "Aborting — no files were modified."
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
_detail "Series:   $SERIES"
_detail "Date:     $DATE"
_detail "Location: $INSTANCE_FILE"
NEW_SERIES=false
if [[ ! -f "$SERIES_INDEX" ]]; then
  _detail "Series index will be created at: $SERIES_INDEX"
  NEW_SERIES=true
fi
echo ""
read -rp "$(printf "${_C_CYAN}Create? [y/N]:${_C_RESET} ")" CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Create series index if new ────────────────────────────────────────────────

if [[ "$NEW_SERIES" == true ]]; then
  mkdir -p "$SERIES_DIR"

  SERIES_PURPOSE="$PURPOSE"
  SERIES_CADENCE="$CADENCE"
  if [[ -z "$SERIES_PURPOSE" ]]; then
    read -rp "$(printf "${_C_CYAN}Series purpose (one line, or Enter to fill in later):${_C_RESET} ")" SERIES_PURPOSE
  fi
  if [[ -z "$SERIES_CADENCE" ]]; then
    read -rp "$(printf "${_C_CYAN}Cadence (e.g. Monthly, Biweekly, or Enter to fill in later):${_C_RESET} ")" SERIES_CADENCE
  fi

  cat > "$SERIES_INDEX" <<EOF
---
title: $SERIES
created: $NOW
modified: $NOW
---
# $SERIES

## Purpose
${SERIES_PURPOSE:-}

## Cadence
${SERIES_CADENCE:-}

## Standing Attendees

## Format / Agenda Template

## Instances

- [[$SERIES $DATE]]
EOF

  _pass "Created series index: $SERIES_INDEX"
else
  # Append instance link to existing series index
  echo "- [[$SERIES $DATE]]" >> "$SERIES_INDEX"
  _pass "Appended instance link to series index: $SERIES_INDEX"
fi

# ── Create instance ───────────────────────────────────────────────────────────

mkdir -p "$INSTANCE_DIR"

cat > "$INSTANCE_FILE" <<EOF
---
title: $SERIES $DATE
created: $NOW
modified: $NOW
---
# $SERIES $DATE

## Purpose

## Attendees

## Agenda

## Key Points

## Decisions
- ?

## Action Items
- [ ] !

## Next Meeting

---
*Series:* [[$SERIES]]
*Daily note:* [[$DATE]]
EOF

_pass "Created instance: $INSTANCE_FILE"
echo ""
_hint "Add to today's daily note: Prepared for / attended [[$SERIES $DATE]]"
_hint "Open in Obsidian and fill in Purpose and Attendees before the meeting."
