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
# Safe to re-run: skips files that already exist.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- color setup ---

if [[ -t 1 ]]; then
  _C_GREEN='\033[0;32m'
  _C_RED='\033[0;31m'
  _C_AMBER='\033[0;33m'
  _C_CYAN='\033[0;96m'
  _C_RESET='\033[0m'
else
  _C_GREEN='' _C_RED='' _C_AMBER='' _C_CYAN='' _C_RESET=''
fi

# --- helpers ---

_pass()   { printf "  ${_C_GREEN}✓ %s${_C_RESET}\n" "$*"; }
_fail()   { printf "  ${_C_RED}✗ %s${_C_RESET}\n" "$*" >&2; }
_warn()   { printf "  ${_C_AMBER}⚠ %s${_C_RESET}\n" "$*"; }
_hint()   { echo "       $*"; }
_cmd()    { printf "         ${_C_CYAN}%s${_C_RESET}\n" "$*" >&2; }

die() {
  local step="$1" hint="$2"
  echo "" >&2
  printf "${_C_RED}[meridian] ✗ Step failed: %s${_C_RESET}\n" "$step" >&2
  echo "  $hint" >&2
  exit 1
}

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

Safe to re-run: existing files are skipped, new files are created.

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
  local today_date="$4"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  if [[ ! -f "$dest" ]]; then
    {
      printf -- '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n\n' "$title" "$today_date" "$today_date"
      cat "$src"
    } > "$dest" || die "copy-doc" "Could not write: $dest"
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
  "_templates"
  ".scripts"
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
    "References"
  )
fi

for d in "${dirs[@]}"; do
  mkdir -p "$VAULT_ROOT/$d" || die "mkdir" "Could not create directory: $VAULT_ROOT/$d"
  _pass "Folder: $d"
done

echo ""

# --- templates ---

echo "[meridian] Writing templates..."

write_if_new "$VAULT_ROOT/_templates/Daily Note.md" "---
title: {{date:YYYY-MM-DD}}
created: {{date:YYYY-MM-DD HH:mm:ss}}
modified: {{date:YYYY-MM-DD HH:mm:ss}}
---

# {{date:YYYY-MM-DD}}

## Top 3 Goals
1.
2.
3.

## Log
"

write_if_new "$VAULT_ROOT/_templates/Generic Note.md" "---
title:
created:
modified:
---

# "

write_if_new "$VAULT_ROOT/_templates/Reflection.md" "## Reflection

**What went well today?**


**What was hard or draining?**


**What would I do differently?**


**Anything worth carrying forward?**
"

echo ""

# --- northstar notes (personal profile only) ---

if [[ "$PROFILE" == "personal" ]]; then

echo "[meridian] Writing Northstar notes..."

write_if_new "$VAULT_ROOT/Northstar/Purpose.md" "---
title:
created:
modified:
---

# Purpose

Why I do what I do — the underlying reason behind the work and the life."

write_if_new "$VAULT_ROOT/Northstar/Vision.md" "---
title:
created:
modified:
---

# Vision

The future state I'm building toward — what the world looks like when I'm succeeding."

write_if_new "$VAULT_ROOT/Northstar/Mission.md" "---
title:
created:
modified:
---

# Mission

The work I'm doing right now to move toward the vision."

write_if_new "$VAULT_ROOT/Northstar/Principles.md" "---
title:
created:
modified:
---

# Principles

Rules I operate by — the non-negotiables that guide decisions.

- "

write_if_new "$VAULT_ROOT/Northstar/Values.md" "---
title:
created:
modified:
---

# Values

What I optimize for — the qualities that matter most.

- "

write_if_new "$VAULT_ROOT/Northstar/Goals.md" "---
title:
created:
modified:
---

# Goals

Concrete targets with timelines, flowing from the mission.

## 12-Month

-

## 3-Year

- "

write_if_new "$VAULT_ROOT/Northstar/Career.md" "---
title:
created:
modified:
---

# Career

Career trajectory, positioning, and professional development notes."

echo ""

fi  # end personal-only Northstar section

# --- process MOCs ---

echo "[meridian] Writing Process MOCs..."

write_if_new "$VAULT_ROOT/Process/Active Projects.md" "---
title:
created:
modified:
---

# Active Projects

## Work Projects
\`\`\`dataview
LIST FROM \"Work\" AND \"Projects\"
SORT file.name ASC
\`\`\`

## Personal Projects
\`\`\`dataview
LIST FROM \"Life/Projects\"
SORT file.name ASC
\`\`\`"

write_if_new "$VAULT_ROOT/Process/Action Items.md" "---
title:
created:
modified:
---

# Action Items

## Urgent
\`\`\`tasks
not done
description includes !!
path includes Process/Daily
sort by filename reverse
\`\`\`

### Recently Completed — Urgent
\`\`\`tasks
done
done after 2 days ago
description includes !!
path includes Process/Daily
sort by done reverse
\`\`\`

## Standard
\`\`\`tasks
not done
description includes !
description does not include !!
path includes Process/Daily
sort by filename reverse
\`\`\`

### Recently Completed — Standard
\`\`\`tasks
done
done after 2 days ago
description includes !
description does not include !!
path includes Process/Daily
sort by done reverse
\`\`\`"

write_if_new "$VAULT_ROOT/Process/Open Loops.md" "---
title:
created:
modified:
---

# Open Loops

## Waiting
\`\`\`tasks
not done
description includes ~
path includes Process/Daily
sort by filename reverse
\`\`\`

## Recently Closed
\`\`\`tasks
done
done after 2 days ago
description includes ~
path includes Process/Daily
sort by done reverse
\`\`\`"

write_if_new "$VAULT_ROOT/Process/Review Queue.md" "---
title:
created:
modified:
---

# Review Queue

## To Process
\`\`\`tasks
not done
description includes >>
path includes Process/Daily
sort by filename reverse
\`\`\`

## Recently Processed
\`\`\`tasks
done
done after 2 days ago
description includes >>
path includes Process/Daily
sort by done reverse
\`\`\`"

write_if_new "$VAULT_ROOT/Process/Current Priorities.md" "---
title:
created:
modified:
---

# Current Priorities

## Annual
-

## Quarterly
-

## Sprint
- "

write_if_new "$VAULT_ROOT/Process/Weekly Outtake.md" "---
title:
created:
modified:
---

# Weekly Outtake

Rolling 7-day view of completed tasks. For permanent weekly records, see \`Process/Weekly/\`.

## Action Items — Urgent
\`\`\`tasks
done
done after 7 days ago
description includes !!
path includes Process/Daily
group by done
sort by done
\`\`\`

## Action Items — Standard
\`\`\`tasks
done
done after 7 days ago
description includes !
description does not include !!
path includes Process/Daily
group by done
sort by done
\`\`\`

## Open Loops Closed
\`\`\`tasks
done
done after 7 days ago
description includes ~
path includes Process/Daily
group by done
sort by done
\`\`\`

## Review Items Processed
\`\`\`tasks
done
done after 7 days ago
description includes >>
path includes Process/Daily
group by done
sort by done
\`\`\`"

echo ""

# --- source tag notes ---

echo "[meridian] Writing source tag notes..."

write_if_new "$VAULT_ROOT/Process/email.md" "---
title:
created:
modified:
---

# email


*Source tag for action items originating from email.*

Tag a task with \`— [[email]]\` in your daily note to link it here. Open this file and check Backlinks to see all email-sourced items across your vault."

write_if_new "$VAULT_ROOT/Process/teams.md" "---
title:
created:
modified:
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

copy_if_new "$SCRIPT_DIR/scripts/weekly-snapshot.py" "$VAULT_ROOT/.scripts/weekly-snapshot.py"
copy_if_new "$SCRIPT_DIR/scripts/new-company.sh"     "$VAULT_ROOT/.scripts/new-company.sh"
copy_if_new "$SCRIPT_DIR/scripts/new-project.sh"     "$VAULT_ROOT/.scripts/new-project.sh"

chmod +x "$VAULT_ROOT/.scripts/new-company.sh" 2>/dev/null || true
chmod +x "$VAULT_ROOT/.scripts/new-project.sh" 2>/dev/null || true

echo ""

# --- documentation ---

echo "[meridian] Copying documentation..."

_today="$(date +%Y-%m-%d)"
DOCS_SRC="$SCRIPT_DIR/documentation"
DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"

copy_doc_with_frontmatter "$DOCS_SRC/user-guide.md"       "$DOCS_DEST/user-guide.md"       "User Guide"       "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/reference-guide.md"  "$DOCS_DEST/reference-guide.md"  "Reference Guide"  "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/architecture.md"     "$DOCS_DEST/architecture.md"     "Architecture"     "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/design-decisions.md" "$DOCS_DEST/design-decisions.md" "Design Decisions" "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/security.md"         "$DOCS_DEST/security.md"         "Security"         "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/sync.md"             "$DOCS_DEST/sync.md"             "Sync Architecture" "$_today"
copy_doc_with_frontmatter "$DOCS_SRC/roadmap.md"          "$DOCS_DEST/roadmap.md"          "Roadmap"          "$_today"
copy_if_new "$SCRIPT_DIR/Meridian System.pdf"             "$DOCS_DEST/Meridian System.pdf"

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
_hint "2. Follow Process/Meridian Documentation/user-guide.md from Step 3 (Rename CurrentCompany)"
echo ""
_warn "Rename Work/CurrentCompany/ to your actual company name after opening the vault."
echo ""
