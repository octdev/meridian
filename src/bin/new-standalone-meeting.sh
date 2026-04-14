#!/usr/bin/env bash
# new-standalone-meeting.sh — create a standalone meeting note in Meridian
#
# Usage:
#   new-standalone-meeting.sh --vault <path>
#   new-standalone-meeting.sh --vault <path> --name <name> --date <YYYY-MM-DD> [--folder]
#
# Flags:
#   --vault    Path to the Meridian vault (required, or $MERIDIAN_VAULT, or interactive)
#   --company  Company name (optional — auto-resolved from daily-notes.json or .vault-version)
#   --name     Meeting name/title (optional — prompted if omitted)
#   --date     Meeting date YYYY-MM-DD (optional — defaults to today)
#   --folder   Create a folder + index note instead of a flat file (for artifact-heavy meetings)
#
# Creates a single meeting note at:
#   Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>.md          (default)
#   Work/<Company>/Meetings/Single/YYYY-MM-DD <Name>/<Name>.md   (--folder)

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
NAME=""
DATE=""
FOLDER_MODE=false
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="${2:?--vault requires a path}";     shift 2 ;;
    --company) COMPANY="${2:?--company requires a name}"; shift 2 ;;
    --name)    NAME="${2:?--name requires a value}";      shift 2 ;;
    --date)    DATE="${2:?--date requires a value}";      shift 2 ;;
    --folder)  FOLDER_MODE=true; shift ;;
    --yes|-y)  YES=true; shift ;;
    --help|-h)
      sed -n '2,/^$/p' "$0" | grep '^#' | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

[[ "$YES" == true ]] && MERIDIAN_YES=1

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

SINGLE_DIR="$VAULT/Work/$CURRENT_COMPANY/Meetings/Single"
[[ -d "$SINGLE_DIR" ]] || die "Meetings/Single/ not found. Run scaffold-vault.sh first." ""

# ── Date ─────────────────────────────────────────────────────────────────────

[[ -z "$DATE" ]] && DATE="$(date +%Y-%m-%d)"

# ── Meeting name ──────────────────────────────────────────────────────────────

if [[ -z "$NAME" ]]; then
  echo ""
  read -rp "$(printf "${_C_CYAN}Meeting name (e.g. Design Review):${_C_RESET} ")" NAME
fi

[[ -n "$NAME" ]] || die "Meeting name cannot be empty." ""

# ── Path construction ─────────────────────────────────────────────────────────

NOW="$(date '+%Y-%m-%d %H:%M:%S')"

if [[ "$FOLDER_MODE" == true ]]; then
  TARGET_DIR="$SINGLE_DIR/$DATE $NAME"
  TARGET_FILE="$TARGET_DIR/$DATE $NAME.md"
else
  TARGET_DIR=""
  TARGET_FILE="$SINGLE_DIR/$DATE $NAME.md"
fi

# ── Collision check ───────────────────────────────────────────────────────────

if [[ "$FOLDER_MODE" == true ]]; then
  if [[ -d "$TARGET_DIR" ]]; then
    die "Already exists: $TARGET_DIR" "Aborting — no files were modified."
  fi
else
  if [[ -f "$TARGET_FILE" ]]; then
    die "Already exists: $TARGET_FILE" "Aborting — no files were modified."
  fi
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
_detail "Meeting: $NAME"
_detail "Date:    $DATE"
_detail "File:    $TARGET_FILE"
echo ""
if [[ "$YES" == false ]]; then
  read -rp "$(printf "${_C_CYAN}Create? [Y/n]:${_C_RESET} ")" CONFIRM
  [[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }
fi

# ── Write note ────────────────────────────────────────────────────────────────

NOTE_CONTENT="---
title: $DATE $NAME
created: $NOW
modified: $NOW
---
# $DATE $NAME

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
*Daily note:* [[$DATE]]"

if [[ "$FOLDER_MODE" == true ]]; then
  mkdir -p "$TARGET_DIR"
  printf '%s\n' "$NOTE_CONTENT" > "$TARGET_FILE"
  _pass "Created folder: ${TARGET_DIR#$VAULT/}"
  _pass "Created note:   ${TARGET_FILE#$VAULT/}"
else
  printf '%s\n' "$NOTE_CONTENT" > "$TARGET_FILE"
  _pass "Created: ${TARGET_FILE#$VAULT/}"
fi

echo ""
_hint "Open in Obsidian: [[$DATE $NAME]]"
_hint "Fill in Purpose and Attendees before the meeting."
