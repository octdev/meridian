#!/usr/bin/env bash
#
# backfill-timestamps.sh — Populates empty created: and modified: frontmatter
# fields in existing vault files.
#
# Only fills fields that are completely empty. Files that already have
# timestamps (whether from Obsidian or a previous scaffold) are left unchanged.
#
# Usage:
#   backfill-timestamps.sh --vault <path>
#   backfill-timestamps.sh -h | --help
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- libraries ---

source "$REPO_DIR/src/lib/colors.sh"
source "$REPO_DIR/src/lib/logging.sh"
source "$REPO_DIR/src/lib/errors.sh"

usage() {
  cat <<EOF
Usage: backfill-timestamps.sh --vault <path>
       backfill-timestamps.sh -h | --help

Populates empty created: and modified: frontmatter fields in existing vault
files. Only updates fields that are completely empty — existing timestamps
are left unchanged.

Options:
  --vault <path>   Path to vault root (required)

EOF
}

# --- argument parsing ---

VAULT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --vault requires a path." >&2; usage >&2; exit 1; }
      VAULT_ROOT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "[meridian] Error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -n "$VAULT_ROOT" ]] || { echo "[meridian] Error: --vault is required." >&2; usage >&2; exit 1; }
[[ -d "$VAULT_ROOT" ]] || die "vault-not-found" "Vault directory not found: $VAULT_ROOT"

# --- helpers ---

_now="$(date '+%Y-%m-%d %H:%M:%S')"
_updated=0
_skipped=0

update_timestamps() {
  local filepath="$1"
  if [[ ! -f "$filepath" ]]; then
    echo "  — Not found, skipping: ${filepath#$VAULT_ROOT/}"
    (( _skipped++ )) || true
    return
  fi
  local _datetime_re='^(created|modified): [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
  if grep -E '^(created|modified):' "$filepath" | grep -qvE "$_datetime_re"; then
    awk -v ts="$_now" '
      /^created:/  && !/^created: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/  { print "created: "  ts; next }
      /^modified:/ && !/^modified: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$/ { print "modified: " ts; next }
      { print }
    ' "$filepath" > "$filepath.tmp" && mv "$filepath.tmp" "$filepath"
    _pass "Updated:  ${filepath#$VAULT_ROOT/}"
    (( _updated++ )) || true
  else
    echo "  — Already formatted, skipping: ${filepath#$VAULT_ROOT/}"
    (( _skipped++ )) || true
  fi
}

# --- main ---

echo ""
echo "[meridian] Backfill Timestamps"
echo ""
echo "[meridian] Vault: $VAULT_ROOT"
echo "[meridian] Timestamp: $_now"
echo ""

# --- process MOCs ---

echo "[meridian] Process MOCs..."

update_timestamps "$VAULT_ROOT/Process/Active Projects.md"
update_timestamps "$VAULT_ROOT/Process/Action Items.md"
update_timestamps "$VAULT_ROOT/Process/Open Loops.md"
update_timestamps "$VAULT_ROOT/Process/Review Queue.md"
update_timestamps "$VAULT_ROOT/Process/Current Priorities.md"
update_timestamps "$VAULT_ROOT/Process/Weekly Outtake.md"

echo ""

# --- source tag notes ---

echo "[meridian] Source tag notes..."

update_timestamps "$VAULT_ROOT/Process/email.md"
update_timestamps "$VAULT_ROOT/Process/teams.md"

echo ""

# --- northstar notes ---

echo "[meridian] Northstar notes..."

update_timestamps "$VAULT_ROOT/Northstar/Purpose.md"
update_timestamps "$VAULT_ROOT/Northstar/Vision.md"
update_timestamps "$VAULT_ROOT/Northstar/Mission.md"
update_timestamps "$VAULT_ROOT/Northstar/Principles.md"
update_timestamps "$VAULT_ROOT/Northstar/Values.md"
update_timestamps "$VAULT_ROOT/Northstar/Goals.md"
update_timestamps "$VAULT_ROOT/Northstar/Career.md"

echo ""

# --- documentation ---

echo "[meridian] Meridian Documentation..."

DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"

update_timestamps "$DOCS_DEST/user-setup.md"
update_timestamps "$DOCS_DEST/user-handbook.md"
update_timestamps "$DOCS_DEST/reference-guide.md"
update_timestamps "$DOCS_DEST/architecture.md"
update_timestamps "$DOCS_DEST/design-decisions.md"
update_timestamps "$DOCS_DEST/security.md"
update_timestamps "$DOCS_DEST/sync.md"
update_timestamps "$DOCS_DEST/roadmap.md"

echo ""

# --- summary ---

printf "${_C_GREEN}[meridian] Done. %d file(s) updated, %d skipped.${_C_RESET}\n" "$_updated" "$_skipped"
echo ""
