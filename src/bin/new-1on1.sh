#!/usr/bin/env bash
# new-1on1.sh — create or update a 1:1 note in Meridian
# Usage: new-1on1.sh --vault <path> [--name <name>] [--date <YYYY-MM-DD>]
#
# If the person's 1:1 note does not exist, creates it with a full header.
# If it already exists, appends a new dated entry to the bottom.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# In-repo: src/bin/../lib/ = src/lib/  |  In vault: .scripts/../lib/ falls back to .scripts/lib/
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -d "$LIB_DIR" ]] || LIB_DIR="${SCRIPT_DIR}/lib"

source "$LIB_DIR/colors.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/errors.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────

VAULT=""
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault) VAULT="${2:?--vault requires a path}"; shift 2 ;;
    --name)  NAME="${2:?--name requires a value}";  shift 2 ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

# ── Vault validation ──────────────────────────────────────────────────────────

if [[ -z "$VAULT" ]]; then
  read -rp "$(printf "${_C_CYAN}Vault path:${_C_RESET} ")" VAULT
fi

VAULT="${VAULT%/}"
[[ -d "$VAULT" ]] || die "Vault not found: $VAULT" ""

ONEONS_DIR="$VAULT/Work/CurrentCompany/Meetings/1on1s"
[[ -d "$ONEONS_DIR" ]] || die "1on1s directory not found: $ONEONS_DIR" "Run scaffold-vault.sh first or create Work/CurrentCompany/Meetings/1on1s/ manually."

# ── Person name ───────────────────────────────────────────────────────────────

if [[ -z "$NAME" ]]; then
  echo ""
  _detail "Existing 1:1 notes:"
  shopt -s nullglob
  for d in "$ONEONS_DIR"/*/; do
    [[ -d "$d" ]] && _detail "  $(basename "$d")"
  done
  shopt -u nullglob
  echo ""
  read -rp "$(printf "${_C_CYAN}Person name (e.g. Jane Doe):${_C_RESET} ")" NAME
fi

[[ -n "$NAME" ]] || die "Name cannot be empty." ""

# ── Path construction ─────────────────────────────────────────────────────────

DATE=$(date +%Y-%m-%d)

PERSON_DIR="$ONEONS_DIR/$NAME"
NOTE_FILE="$PERSON_DIR/$NAME 1on1s.md"
NOW=$(date "+%Y-%m-%d %H:%M:%S")

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
_detail "Person:   $NAME"
_detail "Date:     $DATE"
_detail "File:     $NOTE_FILE"

NOTE_EXISTS=false
if [[ -f "$NOTE_FILE" ]]; then
  NOTE_EXISTS=true
  _detail "Action:   Append new entry to existing note"
else
  _detail "Action:   Create new 1:1 note"
fi

echo ""
read -rp "$(printf "${_C_CYAN}Continue? [y/N]:${_C_RESET} ")" CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ── Create or append ──────────────────────────────────────────────────────────

NEW_ENTRY="## $DATE
**Agenda:**

**Notes:**
"

if [[ "$NOTE_EXISTS" == false ]]; then
  mkdir -p "$PERSON_DIR"

  cat > "$NOTE_FILE" <<EOF
---
title: $NAME 1on1s
created: $NOW
modified: $NOW
---
# $NAME 1:1s

*People note:* [[$NAME]]

---

$NEW_ENTRY
EOF

  _pass "Created: $NOTE_FILE"
else
  printf '\n---\n\n%s\n' "$NEW_ENTRY" >> "$NOTE_FILE"
  _pass "Appended new entry to: $NOTE_FILE"
fi

echo ""
_hint "Open in Obsidian: [[$NAME 1on1s]]"
_hint "Add to today's daily note: 1:1 with [[$NAME]]"
