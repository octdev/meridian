#!/usr/bin/env bash
#
# scaffold-vault.sh — Creates the Meridian vault folder structure and seed files.
#
# Usage:
#   scaffold-vault.sh [--vault <path>] [--profile personal|work] [--upgrade]
#   scaffold-vault.sh --version
#   scaffold-vault.sh -h | --help
#
# Options:
#   --vault <path>           Path to vault root. Default: ~/Documents/Meridian
#   --profile personal|work  Scaffold profile. Default: personal
#   --upgrade                Upgrade an existing vault. Adds missing folders,
#                            templates, scripts, and MOCs (skips existing files).
#                            Always overwrites documentation in
#                            Process/Meridian Documentation/.
#   --version                Print the Meridian project version and the installed
#                            vault version, then exit. Uses --vault <path> if
#                            supplied, otherwise the first registered vault.
#
# Profiles:
#   personal  Full vault: Process, Work, Knowledge, Northstar, Life, References
#   work      Work vault: Process and Work/ only. Knowledge lives at
#             Work/<Company>/Knowledge/ — no top-level Knowledge/ folder.
#             Northstar, Life, and References are intentionally omitted so
#             personal content never exists on a work machine.
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
source "$REPO_DIR/src/lib/vault-select.sh"

usage() {
  cat <<EOF
Usage: scaffold-vault.sh [--vault <path>] [--profile personal|work] [--upgrade]
       scaffold-vault.sh --version
       scaffold-vault.sh -h | --help

Creates the Meridian vault folder structure and seed files.

Options:
  --vault <path>           Path to vault root directory. Default: ~/Documents/Meridian
  --profile personal|work  Scaffold profile. Default: personal
  --upgrade                Upgrade an existing vault instead of creating a new one.
  --version                Print the Meridian project version and the installed
                           vault version, then exit. Accepts --vault <path>;
                           defaults to the first registered vault.

Profiles:
  personal  Full vault including Northstar, Life, and References.
            Use for your personal machine.

  work      Work-only vault: Process and Work/ only. Knowledge lives at
            Work/<Company>/Knowledge/ — no top-level Knowledge/ folder.
            Northstar, Life, and References are intentionally omitted.
            Use for employer-managed or work machines. Personal content
            is never created and therefore cannot be accidentally synced.

Examples:
  scaffold-vault.sh
  scaffold-vault.sh --vault ~/Documents/MyVault
  scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
  scaffold-vault.sh --vault ~/Documents/MyVault --upgrade

EOF
}

# --- version helper ---

# Reads X.Y.Z from the known Meridian version.json format.
semver_from_version_json() {
  local json_file="$1"
  local major minor patch
  major="$(grep '"major"' "$json_file" | grep -o '[0-9]*')"
  minor="$(grep '"minor"' "$json_file" | grep -o '[0-9]*')"
  patch="$(grep '"patch"' "$json_file" | grep -o '[0-9]*')"
  echo "${major}.${minor}.${patch}"
}

# --- argument parsing ---

VAULT_ROOT="${HOME}/Documents/Meridian"
VAULT_ROOT_SET=false
PROFILE="personal"
UPGRADE=false
SHOW_VERSION=false

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
    --upgrade)
      UPGRADE=true; shift ;;
    --version)
      SHOW_VERSION=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "[meridian] Error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# --- version display ---

if [[ "$SHOW_VERSION" == true ]]; then
  _meridian_version="$(semver_from_version_json "$REPO_DIR/config/base/version.json")"

  if [[ "$VAULT_ROOT_SET" == false ]]; then
    select_vault
    VAULT_ROOT_SET=true
  fi

  _vault_ver_file="$VAULT_ROOT/.scripts/.vault-version"
  if [[ -f "$_vault_ver_file" ]]; then
    # Read vault= key (new format); fall back to full file content (old plain format).
    # || true prevents grep's non-zero exit from triggering set -e when key is absent.
    _vault_version="$(grep "^vault=" "$_vault_ver_file" 2>/dev/null | cut -d= -f2)" || true
    [[ -n "$_vault_version" ]] || _vault_version="$(cat "$_vault_ver_file")"
  else
    _vault_version="unknown (pre-dates version tracking)"
  fi

  echo "Meridian: $_meridian_version"
  echo "Vault:    $_vault_version  ($VAULT_ROOT)"

  # Show per-company versions from new key=value format (*-vault= entries).
  if [[ -f "$_vault_ver_file" ]]; then
    while IFS= read -r _line; do
      _company="${_line%-vault=*}"
      _cver="${_line#*-vault=}"
      printf "  %-20s %s\n" "${_company}:" "$_cver"
    done < <(grep "\-vault=" "$_vault_ver_file" 2>/dev/null || true)
  fi

  echo ""
  exit 0
fi

# --- upgrade delegation ---

if [[ "$UPGRADE" == true ]]; then
  if [[ "$VAULT_ROOT_SET" == false ]]; then
    select_vault
  fi
  _target="$(semver_from_version_json "$REPO_DIR/config/base/version.json")"
  _upgrade_script="$REPO_DIR/scripts/upgrade/upgrade-to-${_target}.sh"
  if [[ -f "$_upgrade_script" ]]; then
    exec bash "$_upgrade_script" --vault "$VAULT_ROOT"
  else
    # No version-specific entry point — invoke the runner directly.
    # This is normal for releases with no structural vault changes (docs-only, etc.).
    source "$REPO_DIR/scripts/upgrade/upgrade-runner.sh"
    run_upgrade_to "$_target" "$REPO_DIR/scripts/upgrade/migrations" --vault "$VAULT_ROOT"
    exit 0
  fi
fi

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
      printf -- '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n' "$title" "$ts" "$ts"
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
  echo ""
  [[ -n "$_vault_input" ]] && VAULT_ROOT="${_vault_input/#\~/$HOME}"
fi

echo "[meridian] Scaffolding vault at: $VAULT_ROOT (profile: $PROFILE)"
echo ""

# Fresh scaffold always uses CurrentCompany; user renames after opening in Obsidian.
COMPANY="CurrentCompany"

# --- folders ---

echo "[meridian] Creating folders..."

dirs=(
  "Process/Weekly"
  "Process/Meridian Documentation"
  "Work/$COMPANY/Projects"
  "Work/$COMPANY/People"
  "Work/$COMPANY/Reference"
  "Work/$COMPANY/Incidents"
  "Work/$COMPANY/Vendors"
  "Work/$COMPANY/Goals"
  "Work/$COMPANY/Finances"
  "Work/$COMPANY/General"
  "Work/$COMPANY/Meetings"
  "Work/$COMPANY/Meetings/1on1s"
  "Work/$COMPANY/Daily"
  "Work/$COMPANY/Drafts"
  "Work/$COMPANY/Knowledge/Technical"
  "Work/$COMPANY/Knowledge/Leadership"
  "Work/$COMPANY/Knowledge/Industry"
  "_templates"
  ".scripts"
  ".scripts/lib"
)

if [[ "$PROFILE" == "personal" ]]; then
  dirs+=(
    "Northstar"
    "Life/Drafts"
    "Life/Projects"
    "Life/People"
    "Life/Health"
    "Life/Finances"
    "Life/Social"
    "Life/Development"
    "Life/Fun"
    "Life/General"
    "Life/Daily"
    "Knowledge/Technical"
    "Knowledge/Leadership"
    "Knowledge/Industry"
    "Knowledge/General"
    "References"
  )
fi

for d in "${dirs[@]}"; do
  if [[ ! -d "$VAULT_ROOT/$d" ]]; then
    mkdir -p "$VAULT_ROOT/$d" || die "mkdir" "Could not create directory: $VAULT_ROOT/$d"
    _pass "Folder: $d"
  else
    echo "  — Skipped (exists): $d"
  fi
done

echo ""

# --- timestamp ---

_now="$(date '+%Y-%m-%d %H:%M:%S')"

# --- templates ---

echo "[meridian] Writing templates..."

copy_if_new "$REPO_DIR/src/templates/obsidian-templates/daily-note.md"       "$VAULT_ROOT/_templates/Daily Note.md"

copy_if_new "$REPO_DIR/src/templates/obsidian-templates/generic-note.md"     "$VAULT_ROOT/_templates/Generic Note.md"
copy_if_new "$REPO_DIR/src/templates/obsidian-templates/reflection.md"       "$VAULT_ROOT/_templates/Reflection.md"
copy_if_new "$REPO_DIR/src/templates/obsidian-templates/meeting-instance.md" "$VAULT_ROOT/_templates/Meeting Instance.md"
copy_if_new "$REPO_DIR/src/templates/obsidian-templates/meeting-series.md"   "$VAULT_ROOT/_templates/Meeting Series.md"
copy_if_new "$REPO_DIR/src/templates/obsidian-templates/1on1.md"             "$VAULT_ROOT/_templates/1on1.md"

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
copy_with_timestamps "$REPO_DIR/src/templates/mocs/current-priorities.md" "$VAULT_ROOT/Work/$COMPANY/Goals/Current Priorities.md"  "$_now"
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

if [[ "$PROFILE" == "personal" ]]; then
  DAILY_FOLDER="Life/Daily"
  DRAFTS_FOLDER="Life/Drafts"
  ATTACHMENTS_FOLDER="References"
else
  DAILY_FOLDER="Work/$COMPANY/Daily"
  DRAFTS_FOLDER="Work/$COMPANY/Drafts"
  ATTACHMENTS_FOLDER="Work/$COMPANY/Reference"
fi

write_if_new "$VAULT_ROOT/.obsidian/daily-notes.json" "{
  \"folder\": \"$DAILY_FOLDER\",
  \"template\": \"_templates/Daily Note\",
  \"format\": \"YYYY-MM-DD\",
  \"autorun\": false
}"

write_if_new "$VAULT_ROOT/.obsidian/app.json" "{
  \"newFileLocation\": \"folder\",
  \"newFileFolderPath\": \"$DRAFTS_FOLDER\",
  \"attachmentFolderPath\": \"$ATTACHMENTS_FOLDER\"
}"

write_if_new "$VAULT_ROOT/.obsidian/templates.json" '{
  "folder": "_templates",
  "dateFormat": "YYYY-MM-DD",
  "timeFormat": "HH:mm"
}'

echo ""

# --- scripts ---

echo "[meridian] Copying scripts..."

copy_if_new "$REPO_DIR/src/bin/weekly-snapshot.py"      "$VAULT_ROOT/.scripts/weekly-snapshot.py"
copy_if_new "$REPO_DIR/src/bin/new-company.sh"          "$VAULT_ROOT/.scripts/new-company.sh"
copy_if_new "$REPO_DIR/src/bin/new-project.sh"          "$VAULT_ROOT/.scripts/new-project.sh"
copy_if_new "$REPO_DIR/src/bin/new-meeting-series.sh"   "$VAULT_ROOT/.scripts/new-meeting-series.sh"

copy_if_new "$REPO_DIR/src/lib/colors.sh"  "$VAULT_ROOT/.scripts/lib/colors.sh"
copy_if_new "$REPO_DIR/src/lib/logging.sh" "$VAULT_ROOT/.scripts/lib/logging.sh"
copy_if_new "$REPO_DIR/src/lib/errors.sh"  "$VAULT_ROOT/.scripts/lib/errors.sh"

chmod +x "$VAULT_ROOT/.scripts/new-company.sh"        2>/dev/null || true
chmod +x "$VAULT_ROOT/.scripts/new-project.sh"        2>/dev/null || true
chmod +x "$VAULT_ROOT/.scripts/new-meeting-series.sh" 2>/dev/null || true

echo ""

# --- vault version ---

_vault_version="$(semver_from_version_json "$REPO_DIR/config/base/version.json")"
if [[ ! -f "$VAULT_ROOT/.scripts/.vault-version" ]]; then
  {
    echo "vault=${_vault_version}"
    echo "${COMPANY}-vault=${_vault_version}"
  } > "$VAULT_ROOT/.scripts/.vault-version"
  _pass "Created: .scripts/.vault-version"
else
  echo "  — Skipped (exists): .scripts/.vault-version"
fi
echo ""

# --- documentation ---

echo "[meridian] Copying documentation..."

DOCS_SRC="$REPO_DIR/src/documentation"
DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"

copy_doc_with_frontmatter "$DOCS_SRC/User Setup.md"      "$DOCS_DEST/User Setup.md"      "User Setup"        "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/User Handbook.md"   "$DOCS_DEST/User Handbook.md"   "User Handbook"     "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Reference Guide.md" "$DOCS_DEST/Reference Guide.md" "Reference Guide"   "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Architecture.md"    "$DOCS_DEST/Architecture.md"    "Architecture"      "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Design Decision.md" "$DOCS_DEST/Design Decision.md" "Design Decision"   "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Security.md"        "$DOCS_DEST/Security.md"        "Security"          "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Sync.md"            "$DOCS_DEST/Sync.md"            "Sync"              "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Roadmap.md"         "$DOCS_DEST/Roadmap.md"         "Roadmap"           "$_now"
copy_doc_with_frontmatter "$DOCS_SRC/Upgrades.md"        "$DOCS_DEST/Upgrades.md"        "Upgrades"          "$_now"
copy_if_new "$REPO_DIR/Meridian System.pdf" "$DOCS_DEST/Meridian System.pdf"

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
_hint "2. Follow Process/Meridian Documentation/User Setup.md from Step 3 (Rename CurrentCompany)"
echo ""
_warn "Rename Work/CurrentCompany/ to your actual company name after opening the vault."
echo ""

register_vault "$VAULT_ROOT"
