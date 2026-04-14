#!/usr/bin/env bash
# new-1on1.sh — create or update a 1:1 note in Meridian
# Usage: new-1on1.sh --vault <path> [--company <name>] [--name <name>]
# Creates a new 1:1 rolling note or appends a dated entry to an existing one.
# Notes are created at Meetings/1on1s/<Name> 1on1s.md

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
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)   VAULT="${2:?--vault requires a path}";   shift 2 ;;
    --company) COMPANY="${2:?--company requires a name}"; shift 2 ;;
    --name)    NAME="${2:?--name requires a value}";    shift 2 ;;
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

ONEONS_DIR="$VAULT/Work/$CURRENT_COMPANY/Meetings/1on1s"
[[ -d "$ONEONS_DIR" ]] || die "1on1s directory not found: $ONEONS_DIR" "Run scaffold-vault.sh first or create Work/$CURRENT_COMPANY/Meetings/1on1s/ manually."

# ── Person name ───────────────────────────────────────────────────────────────

if [[ -z "$NAME" ]]; then
  echo ""

  shopt -s nullglob
  declare -a _1on1_files=("$ONEONS_DIR"/*.md)
  shopt -u nullglob

  # Build list sorted by frontmatter `modified` timestamp, most recent first.
  # Display names have " 1on1s" stripped so they can be used directly as input.
  declare -a _1on1_names=()
  if [[ ${#_1on1_files[@]} -gt 0 ]]; then
    declare -a _1on1_pairs=()
    for _f in "${_1on1_files[@]}"; do
      _base="$(basename "${_f%.md}")"
      _person="${_base% 1on1s}"
      _ts="$(grep -m1 '^modified:' "$_f" 2>/dev/null | sed 's/^modified:[[:space:]]*//' || true)"
      [[ -z "$_ts" ]] && _ts="0000-00-00 00:00:00"
      _1on1_pairs+=("${_ts}|${_person}")
    done
    while IFS='|' read -r _ _person; do
      _1on1_names+=("$_person")
    done < <(printf '%s\n' "${_1on1_pairs[@]}" | sort -r)
  fi

  _1on1_total=${#_1on1_names[@]}
  _1on1_page=14

  _print_1on1_list() {
    local limit=$1
    local i
    for (( i=0; i<limit && i<_1on1_total; i++ )); do
      printf "  %2d) %s\n" $(( i+1 )) "${_1on1_names[$i]}"
    done
    if (( _1on1_total > _1on1_page && limit <= _1on1_page )); then
      printf "  15) List more...\n"
    fi
  }

  if (( _1on1_total > 0 )); then
    _detail "Existing 1:1 notes:"
    _print_1on1_list "$_1on1_page"
    echo ""
    read -rp "$(printf "${_C_CYAN}Select a number or enter a name:${_C_RESET} ")" _sel

    # Expand the list if the user chose "List more..."
    if [[ "$_sel" == "15" ]] && (( _1on1_total > _1on1_page )); then
      echo ""
      _detail "All 1:1 notes:"
      _print_1on1_list "$_1on1_total"
      echo ""
      read -rp "$(printf "${_C_CYAN}Select a number or enter a name:${_C_RESET} ")" _sel
    fi

    if [[ "$_sel" =~ ^[0-9]+$ ]] && (( _sel >= 1 && _sel <= _1on1_total )); then
      NAME="${_1on1_names[$(( _sel - 1 ))]}"
    else
      NAME="$_sel"
    fi
  else
    read -rp "$(printf "${_C_CYAN}Person name (e.g. Jane Doe):${_C_RESET} ")" NAME
  fi
fi

[[ -n "$NAME" ]] || die "Name cannot be empty." ""

# ── Path construction ─────────────────────────────────────────────────────────

DATE=$(date +%Y-%m-%d)

NOTE_FILE="$ONEONS_DIR/$NAME 1on1s.md"
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
read -rp "$(printf "${_C_CYAN}Continue? [Y/n]:${_C_RESET} ")" CONFIRM
[[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }

# ── Create or append ──────────────────────────────────────────────────────────

NEW_ENTRY="## $DATE
**Agenda:**

**Notes:**
"

if [[ "$NOTE_EXISTS" == false ]]; then
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
