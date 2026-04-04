#!/usr/bin/env bash
#
# scaffold-vault.sh — Creates the Meridian vault folder structure and seed files.
#
# Usage:
#   scaffold-vault.sh [--vault <path>] [--profile personal|work] [--upgrade]
#   scaffold-vault.sh -h | --help
#
# Options:
#   --vault <path>           Path to vault root. Default: ~/Documents/Meridian
#   --profile personal|work  Scaffold profile. Default: personal
#   --upgrade                Upgrade an existing vault. Adds missing folders,
#                            templates, scripts, and MOCs (skips existing files).
#                            Always overwrites documentation in
#                            Process/Meridian Documentation/.
#
# Profiles:
#   personal  Full vault: Process, Work, Knowledge, Northstar, Life, References
#   work      Work vault: Process, Work, Knowledge only.
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

usage() {
  cat <<EOF
Usage: scaffold-vault.sh [--vault <path>] [--profile personal|work] [--upgrade]
       scaffold-vault.sh -h | --help

Creates the Meridian vault folder structure and seed files.

Options:
  --vault <path>           Path to vault root directory. Default: ~/Documents/Meridian
  --profile personal|work  Scaffold profile. Default: personal
  --upgrade                Upgrade an existing vault instead of creating a new one.

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
  scaffold-vault.sh --vault ~/Documents/MyVault --upgrade

EOF
}

# --- argument parsing ---

VAULT_ROOT="${HOME}/Documents/Meridian"
VAULT_ROOT_SET=false
PROFILE="personal"
UPGRADE=false

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

write_doc_with_frontmatter() {
  # Like copy_doc_with_frontmatter but always overwrites — used by --upgrade for docs.
  local src="$1"
  local dest="$2"
  local title="$3"
  local ts="$4"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  {
    printf -- '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n\n' "$title" "$ts" "$ts"
    cat "$src"
  } > "$dest" || die "write-doc" "Could not write: $dest"
  _pass "Updated: ${dest#$VAULT_ROOT/}"
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


# --- vault registry ---

register_vault() {
  local vault_path="$1"
  local vaults_file="$REPO_DIR/config/vaults.txt"
  local lines=()

  if [[ -f "$vaults_file" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" && "$line" != "$vault_path" ]] && lines+=("$line")
    done < "$vaults_file"
  fi

  mkdir -p "$(dirname "$vaults_file")"
  {
    echo "$vault_path"
    if [[ ${#lines[@]} -gt 0 ]]; then
      printf '%s\n' "${lines[@]}"
    fi
  } > "$vaults_file"
}

load_known_vaults() {
  KNOWN_VAULTS=()
  local vaults_file="$REPO_DIR/config/vaults.txt"
  if [[ ! -f "$vaults_file" ]]; then
    return 0
  fi

  local valid=() stale=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ -d "$line" ]]; then
      valid+=("$line")
    else
      stale+=("$line")
    fi
  done < "$vaults_file"

  if [[ ${#stale[@]} -gt 0 ]]; then
    if [[ ${#valid[@]} -gt 0 ]]; then
      printf '%s\n' "${valid[@]}" > "$vaults_file"
    else
      > "$vaults_file"
    fi
    local _n=${#stale[@]}
    _warn "Removed $_n stale vault $([ "$_n" -eq 1 ] && echo entry || echo entries) ($([ "$_n" -eq 1 ] && echo directory || echo directories) no longer exist)."
    echo ""
  fi

  if [[ ${#valid[@]} -gt 0 ]]; then
    KNOWN_VAULTS=("${valid[@]}")
  fi
  return 0
}

# --- main ---

echo ""
if [[ "$UPGRADE" == true ]]; then
  echo "[meridian] Upgrade Vault"
else
  echo "[meridian] New Vault"
fi
echo ""

if [[ "$VAULT_ROOT_SET" == false ]]; then
  if [[ "$UPGRADE" == true ]]; then
    load_known_vaults
    if [[ ${#KNOWN_VAULTS[@]} -gt 0 ]]; then
      echo "  Known vaults:"
      for _i in "${!KNOWN_VAULTS[@]}"; do
        if [[ $_i -eq 0 ]]; then
          _hint "    $((_i+1)). ${KNOWN_VAULTS[$_i]}  (default)"
        else
          _hint "    $((_i+1)). ${KNOWN_VAULTS[$_i]}"
        fi
      done
      echo ""
      read -rp "  Select vault [1] or enter path: " _vault_input
      echo ""
      if [[ -z "$_vault_input" || "$_vault_input" == "1" ]]; then
        VAULT_ROOT="${KNOWN_VAULTS[0]}"
      elif [[ "$_vault_input" =~ ^[0-9]+$ ]] && \
           [[ "$_vault_input" -ge 1 && "$_vault_input" -le ${#KNOWN_VAULTS[@]} ]]; then
        VAULT_ROOT="${KNOWN_VAULTS[$((_vault_input-1))]}"
      else
        VAULT_ROOT="${_vault_input/#\~/$HOME}"
      fi
    else
      read -rp "  Vault path: " _vault_input
      echo ""
      [[ -n "$_vault_input" ]] && VAULT_ROOT="${_vault_input/#\~/$HOME}"
    fi
  else
    read -rp "  Vault path [~/Documents/Meridian]: " _vault_input
    echo ""
    [[ -n "$_vault_input" ]] && VAULT_ROOT="${_vault_input/#\~/$HOME}"
  fi
fi

if [[ "$UPGRADE" == true ]]; then
  echo "[meridian] Upgrading vault at: $VAULT_ROOT (profile: $PROFILE)"
  echo ""
  if [[ ! -d "$VAULT_ROOT" ]]; then
    printf "${_C_RED}[meridian] ✗ Vault not found: %s${_C_RESET}\n" "$VAULT_ROOT" >&2
    echo "" >&2
    echo "  --upgrade requires an existing vault. Run without --upgrade to create a new one." >&2
    echo "" >&2
    exit 1
  fi
else
  echo "[meridian] Scaffolding vault at: $VAULT_ROOT (profile: $PROFILE)"
  echo ""
  if [[ -d "$VAULT_ROOT" ]]; then
    printf "${_C_RED}[meridian] ✗ Target directory already exists: %s${_C_RESET}\n" "$VAULT_ROOT" >&2
    echo "" >&2
    echo "  To upgrade an existing vault, re-run with --upgrade." >&2
    echo "" >&2
    exit 1
  fi
fi

# --- company name ---
# Upgrade mode: detect from Work/ and confirm with user.
# Fresh scaffold: use the placeholder; user renames after opening in Obsidian.

if [[ "$UPGRADE" == true ]]; then
  _companies=()
  if [[ -d "$VAULT_ROOT/Work" ]]; then
    for _d in "$VAULT_ROOT/Work"/*/; do
      [[ -d "$_d" ]] && _companies+=("$(basename "$_d")")
    done
  fi

  if [[ ${#_companies[@]} -eq 1 ]]; then
    _detected="${_companies[0]}"
    echo ""
    read -rp "$(printf "${_C_CYAN}Company name [${_detected}]:${_C_RESET} ")" COMPANY
    COMPANY="${COMPANY:-$_detected}"
  elif [[ ${#_companies[@]} -gt 1 ]]; then
    echo ""
    _detail "Multiple companies found under Work/:"
    for _c in "${_companies[@]}"; do _detail "  $_c"; done
    echo ""
    read -rp "$(printf "${_C_CYAN}Company name to upgrade:${_C_RESET} ")" COMPANY
  else
    echo ""
    read -rp "$(printf "${_C_CYAN}Company name:${_C_RESET} ")" COMPANY
  fi

  [[ -n "$COMPANY" ]] || die "Company name cannot be empty." ""
  [[ -d "$VAULT_ROOT/Work/$COMPANY" ]] || \
    die "Company directory not found: Work/$COMPANY" "Check the name and try again."

  echo ""
  _detail "Company: $COMPANY"
  echo ""
else
  COMPANY="CurrentCompany"
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

# --- documentation ---

echo "[meridian] Copying documentation..."

DOCS_SRC="$REPO_DIR/documentation"
DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"

if [[ "$UPGRADE" == true ]]; then
  # Upgrade: always overwrite documentation so vault copies stay current.
  write_doc_with_frontmatter "$DOCS_SRC/User Setup.md"      "$DOCS_DEST/User Setup.md"      "User Setup"        "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/User Handbook.md"   "$DOCS_DEST/User Handbook.md"   "User Handbook"     "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Reference Guide.md" "$DOCS_DEST/Reference Guide.md" "Reference Guide"   "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Architecture.md"    "$DOCS_DEST/Architecture.md"    "Architecture"      "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Design Decision.md" "$DOCS_DEST/Design Decision.md" "Design Decision"   "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Security.md"        "$DOCS_DEST/Security.md"        "Security"          "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Sync.md"            "$DOCS_DEST/Sync.md"            "Sync"              "$_now"
  write_doc_with_frontmatter "$DOCS_SRC/Roadmap.md"         "$DOCS_DEST/Roadmap.md"         "Roadmap"           "$_now"
  if [[ -f "$REPO_DIR/Meridian System.pdf" ]]; then
    cp "$REPO_DIR/Meridian System.pdf" "$DOCS_DEST/Meridian System.pdf"
    _pass "Updated: Meridian System.pdf"
  else
    _warn "Source not found, skipping: Meridian System.pdf"
  fi
else
  # Fresh scaffold: skip-if-exists.
  copy_doc_with_frontmatter "$DOCS_SRC/User Setup.md"      "$DOCS_DEST/User Setup.md"      "User Setup"        "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/User Handbook.md"   "$DOCS_DEST/User Handbook.md"   "User Handbook"     "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Reference Guide.md" "$DOCS_DEST/Reference Guide.md" "Reference Guide"   "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Architecture.md"    "$DOCS_DEST/Architecture.md"    "Architecture"      "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Design Decision.md" "$DOCS_DEST/Design Decision.md" "Design Decision"   "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Security.md"        "$DOCS_DEST/Security.md"        "Security"          "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Sync.md"            "$DOCS_DEST/Sync.md"            "Sync"              "$_now"
  copy_doc_with_frontmatter "$DOCS_SRC/Roadmap.md"         "$DOCS_DEST/Roadmap.md"         "Roadmap"           "$_now"
  copy_if_new "$REPO_DIR/Meridian System.pdf" "$DOCS_DEST/Meridian System.pdf"
fi

echo ""

# --- summary ---

if [[ "$UPGRADE" == true ]]; then
  printf "${_C_GREEN}[meridian] Vault upgraded successfully.${_C_RESET}\n"
  echo ""
  if [[ "$PROFILE" == "work" ]]; then
    _warn "Work profile: Northstar/, Life/, and References/ were not created."
    _hint "These folders are intentionally absent — never add them to Syncthing on this machine."
    echo ""
  fi
  _hint "Documentation in Process/Meridian Documentation/ has been refreshed."
  _hint "Any missing folders, templates, and scripts have been added."
  echo ""
else
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
fi

register_vault "$VAULT_ROOT"
