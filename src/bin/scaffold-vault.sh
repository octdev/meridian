#!/usr/bin/env bash
#
# scaffold-vault.sh — Creates the Meridian vault folder structure and seed files.
#
# Usage:
#   scaffold-vault.sh [--vault <path>] [--profile personal|work]
#   scaffold-vault.sh -h | --help
#
# Options:
#   --vault <path>           Path to vault root. Default: ~/Documents/Meridian
#   --profile personal|work  Scaffold profile. Default: personal
#
# Profiles:
#   personal  Full vault: Process, Work, Knowledge, Northstar, Life, References
#   work      Work vault: Process, Work, Knowledge only.
#             Northstar, Life, and References are intentionally omitted so
#             personal content never exists on a work machine.
#
# Creates a new vault only. Target directory must not already exist.
# To upgrade an existing vault, create a new vault and migrate manually.
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
Usage: scaffold-vault.sh [--vault <path>] [--profile personal|work]
       scaffold-vault.sh -h | --help

Creates the Meridian vault folder structure and seed files.

Options:
  --vault <path>           Path to vault root directory. Default: ~/Documents/Meridian
  --profile personal|work  Scaffold profile. Default: personal

Profiles:
  personal  Full vault including Northstar, Life, and References.
            Use for your personal machine.

  work      Work-only vault: Process, Work, and Knowledge only.
            Northstar, Life, and References are intentionally omitted.
            Use for employer-managed or work machines. Personal content
            is never created and therefore cannot be accidentally synced.

Examples:
  scaffold-vault.sh
  scaffold-vault.sh --vault ~/Documents/MyVault
  scaffold-vault.sh --vault ~/Documents/WorkVault --profile work

Target directory must not already exist. To upgrade an existing vault,
create a new vault and migrate manually.

EOF
}

# --- argument parsing ---

VAULT_ROOT="${HOME}/Documents/Meridian"
VAULT_ROOT_SET=false
PROFILE="personal"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --vault requires a path." >&2; usage >&2; exit 1; }
      VAULT_ROOT="$2"; VAULT_ROOT_SET=true; shift 2 ;;
    --profile)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --profile requires a value (personal or work)." >&2; usage >&2; exit 1; }
      case "$2" in
        personal|work) PROFILE="$2"; shift 2 ;;
        *) echo "[meridian] Error: --profile must be 'personal' or 'work'." >&2; usage >&2; exit 1 ;;
      esac ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "[meridian] Error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# --- write helper ---

write_if_new() {
  local filepath="$1"
  local content="$2"
  if [[ ! -f "$filepath" ]]; then
    printf '%s\n' "$content" > "$filepath" || die "write-file" "Could not write: $filepath"
    _pass "Created: ${filepath#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${filepath#$VAULT_ROOT/}"
  fi
}

copy_if_new() {
  local src="$1"
  local dest="$2"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest" || die "copy-file" "Could not copy to: $dest"
    _pass "Created: ${dest#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${dest#$VAULT_ROOT/}"
  fi
}

copy_doc_with_frontmatter() {
  local src="$1"
  local dest="$2"
  local title="$3"
  local ts="$4"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  if [[ ! -f "$dest" ]]; then
    {
      printf -- '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n\n' "$title" "$ts" "$ts"
      cat "$src"
    } > "$dest" || die "copy-doc" "Could not write: $dest"
    _pass "Created: ${dest#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${dest#$VAULT_ROOT/}"
  fi
}

copy_with_timestamps() {
  local src="$1"
  local dest="$2"
  local ts="$3"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  if [[ ! -f "$dest" ]]; then
    awk -v ts="$ts" '
      /^created:[[:space:]]*$/ { print "created: " ts; next }
      /^modified:[[:space:]]*$/ { print "modified: " ts; next }
      { print }
    ' "$src" > "$dest" || die "copy-with-timestamps" "Could not write: $dest"
    _pass "Created: ${dest#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${dest#$VAULT_ROOT/}"
  fi
}


# --- main ---

echo ""
echo "[meridian] New Vault"
echo ""

if [[ "$VAULT_ROOT_SET" == false ]]; then
  read -rp "  Vault path [~/Documents/Meridian]: " _vault_input
  if [[ -n "$_vault_input" ]]; then
    VAULT_ROOT="${_vault_input/#\~/$HOME}"
  fi
  echo ""
fi

echo "[meridian] Scaffolding vault at: $VAULT_ROOT (profile: $PROFILE)"
echo ""

if [[ -d "$VAULT_ROOT" ]]; then
  printf "${_C_RED}[meridian] ✗ Target directory already exists: %s${_C_RESET}\n" "$VAULT_ROOT" >&2
  echo "" >&2
  echo "  To upgrade an existing vault, create a new vault and migrate manually." >&2
  echo "" >&2
  exit 1
fi

# --- folders ---

echo "[meridian] Creating folders..."

dirs=(
  "Process/Daily"
  "Process/Weekly"
  "Process/Drafts"
  "Process/Meridian Documentation"
  "Knowledge/Technical"
  "Knowledge/Leadership"
  "Knowledge/Industry"
  "Knowledge/General"
  "Work/CurrentCompany/Projects"
  "Work/CurrentCompany/People"
  "Work/CurrentCompany/Reference"
  "Work/CurrentCompany/Incidents"
  "Work/CurrentCompany/Vendors"
  "Work/CurrentCompany/Goals"
  "Work/CurrentCompany/Finances"
  "Work/CurrentCompany/General"
  "_templates"
  ".scripts"
  ".scripts/lib"
)

if [[ "$PROFILE" == "personal" ]]; then
  dirs+=(
    "Northstar"
    "Life/Projects"
    "Life/People"
    "Life/Health"
    "Life/Finances"
    "Life/Social"
    "Life/Development"
    "Life/Fun"
    "Life/General"
    "References"
  )
fi

for d in "${dirs[@]}"; do
  mkdir -p "$VAULT_ROOT/$d" || die "mkdir" "Could not create directory: $VAULT_ROOT/$d"
  _pass "Folder: $d"
done

echo ""

# --- timestamp ---

_now="$(date '+%Y-%m-%d %H:%M:%S')"

# --- templates ---

echo "[meridian] Writing templates..."

copy_if_new "$REPO_DIR/src/templates/obsidian-templates/daily-note.md" "$VAULT_ROOT/_templates/Daily Note.md"

copy_if_new "$REPO_DIR/src/templates/obsidian-templates/generic-note.md" "$VAULT_ROOT/_templates/Generic Note.md"
copy_if_new "$REPO_DIR/src/templates/obsidian-templates/reflection.md"   "$VAULT_ROOT/_templates/Reflection.md"

echo ""

# --- northstar notes (personal profile only) ---

if [[ "$PROFILE" == "personal" ]]; then

echo "[meridian] Writing Northstar notes..."

copy_with_timestamps "$REPO_DIR/src/templates/northstar/purpose.md"    "$VAULT_ROOT/Northstar/Purpose.md"    "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/vision.md"     "$VAULT_ROOT/Northstar/Vision.md"     "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/mission.md"    "$VAULT_ROOT/Northstar/Mission.md"    "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/principles.md" "$VAULT_ROOT/Northstar/Principles.md" "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/values.md"     "$VAULT_ROOT/Northstar/Values.md"     "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/goals.md"      "$VAULT_ROOT/Northstar/Goals.md"      "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/northstar/career.md"     "$VAULT_ROOT/Northstar/Career.md"     "$_now"

echo ""

fi  # end personal-only Northstar section

# --- process MOCs ---

echo "[meridian] Writing Process MOCs..."

copy_with_timestamps "$REPO_DIR/src/templates/mocs/active-projects.md"    "$VAULT_ROOT/Process/Active Projects.md"      "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/mocs/action-items.md"       "$VAULT_ROOT/Process/Action Items.md"         "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/mocs/open-loops.md"         "$VAULT_ROOT/Process/Open Loops.md"           "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/mocs/review-queue.md"       "$VAULT_ROOT/Process/Review Queue.md"         "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/mocs/current-priorities.md" "$VAULT_ROOT/Process/Current Priorities.md"  "$_now"
copy_with_timestamps "$REPO_DIR/src/templates/mocs/weekly-outtake.md"     "$VAULT_ROOT/Process/Weekly Outtake.md"       "$_now"

echo ""

# --- source tag notes ---

echo "[meridian] Writing source tag notes..."

write_if_new "$VAULT_ROOT/Process/email.md" "---
title:
created: $_now
modified: $_now
---

# email


*Source tag for action items originating from email.*

Tag a task with \`— [[email]]\` in your daily note to link it here. Open this file and check Backlinks to see all email-sourced items across your vault."

write_if_new "$VAULT_ROOT/Process/teams.md" "---
title:
created: $_now
modified: $_now
---

# teams


*Source tag for action items originating from Teams.*

Tag a task with \`— [[teams]]\` in your daily note to link it here. Open this file and check Backlinks to see all Teams-sourced items across your vault."

echo ""

# --- obsidian config ---

echo "[meridian] Writing Obsidian config..."

mkdir -p "$VAULT_ROOT/.obsidian"

write_if_new "$VAULT_ROOT/.obsidian/daily-notes.json" '{
  "folder": "Process/Daily",
  "template": "_templates/Daily Note",
  "format": "YYYY-MM-DD",
  "autorun": false
}'

write_if_new "$VAULT_ROOT/.obsidian/templates.json" '{
  "folder": "_templates",
  "dateFormat": "YYYY-MM-DD",
  "timeFormat": "HH:mm"
}'

echo ""

# --- scripts ---

echo "[meridian] Copying scripts..."

copy_if_new "$REPO_DIR/src/bin/weekly-snapshot.py" "$VAULT_ROOT/.scripts/weekly-snapshot.py"
copy_if_new "$REPO_DIR/src/bin/new-company.sh"     "$VAULT_ROOT/.scripts/new-company.sh"
copy_if_new "$REPO_DIR/src/bin/new-project.sh"     "$VAULT_ROOT/.scripts/new-project.sh"

copy_if_new "$REPO_DIR/src/lib/colors.sh"  "$VAULT_ROOT/.scripts/lib/colors.sh"
copy_if_new "$REPO_DIR/src/lib/logging.sh" "$VAULT_ROOT/.scripts/lib/logging.sh"
copy_if_new "$REPO_DIR/src/lib/errors.sh"  "$VAULT_ROOT/.scripts/lib/errors.sh"

chmod +x "$VAULT_ROOT/.scripts/new-company.sh" 2>/dev/null || true
chmod +x "$VAULT_ROOT/.scripts/new-project.sh" 2>/dev/null || true

echo ""

# --- documentation ---

echo "[meridian] Copying documentation..."

DOCS_SRC="$REPO_DIR/documentation"
DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"

copy_doc_with_frontmatter "$DOCS_SRC/user-setup.md"      "$DOCS_DEST/user-setup.md"      "User Setup"        "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/user-handbook.md"   "$DOCS_DEST/user-handbook.md"   "User Handbook"     "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/reference-guide.md"  "$DOCS_DEST/reference-guide.md"  "Reference Guide"  "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/architecture.md"     "$DOCS_DEST/architecture.md"     "Architecture"     "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/design-decisions.md" "$DOCS_DEST/design-decisions.md" "Design Decisions" "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/security.md"         "$DOCS_DEST/security.md"         "Security"         "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/sync.md"             "$DOCS_DEST/sync.md"             "Sync Architecture" "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/roadmap.md"          "$DOCS_DEST/roadmap.md"          "Roadmap"          "$_now"
copy_if_new "$REPO_DIR/Meridian System.pdf"   "$DOCS_DEST/Meridian System.pdf"

echo ""

# --- summary ---

printf "${_C_GREEN}[meridian] Vault scaffolded successfully.${_C_RESET}\n"
echo ""

if [[ "$PROFILE" == "work" ]]; then
  _warn "Work profile: Northstar/, Life/, and References/ were not created."
  _hint "These folders are intentionally absent — never add them to Syncthing on this machine."
  echo ""
fi

echo "Next steps:"
_hint "1. Open Obsidian → Open folder as vault → $VAULT_ROOT"
_hint "2. Follow Process/Meridian Documentation/user-setup.md from Step 3 (Rename CurrentCompany)"
echo ""
_warn "Rename Work/CurrentCompany/ to your actual company name after opening the vault."
echo ""
