#!/usr/bin/env bash
#
# scaffold-vault.sh — Creates the Meridian vault folder structure and seed files.
#
# Usage:
#   scaffold-vault.sh [--vault <path>]
#   scaffold-vault.sh -h | --help
#
# Options:
#   --vault <path>   Path to vault root. Default: ./vault
#
# Safe to re-run: skips files that already exist.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

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
Usage: scaffold-vault.sh [--vault <path>]
       scaffold-vault.sh -h | --help

Creates the Meridian vault folder structure and seed files.

Options:
  --vault <path>   Path to vault root directory. Default: ./vault

Examples:
  scaffold-vault.sh
  scaffold-vault.sh --vault ~/Documents/MyVault
  scaffold-vault.sh --vault ~/Documents/WorkVault

Safe to re-run: existing files are skipped, new files are created.

EOF
}

# --- argument parsing ---

VAULT_ROOT="./vault"

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

# --- main ---

echo ""
echo "[meridian] Scaffolding vault at: $VAULT_ROOT"
echo ""

# --- folders ---

echo "[meridian] Creating folders..."

dirs=(
  "Northstar"
  "Process/Daily"
  "Process/Weekly"
  "Knowledge/Technical"
  "Knowledge/Leadership"
  "Knowledge/Industry"
  "Knowledge/General"
  "Work/CurrentCompany/Projects"
  "Work/CurrentCompany/People"
  "Work/CurrentCompany/Reference"
  "Work/CurrentCompany/Incidents"
  "Work/CurrentCompany/Vendors"
  "Life/Projects"
  "Life/People"
  "Life/Health"
  "Life/Finances"
  "Life/Social"
  "Life/Development"
  "Life/Fun"
  "References"
  "_templates"
  ".scripts"
)

for d in "${dirs[@]}"; do
  mkdir -p "$VAULT_ROOT/$d" || die "mkdir" "Could not create directory: $VAULT_ROOT/$d"
  _pass "Folder: $d"
done

echo ""

# --- templates ---

echo "[meridian] Writing templates..."

write_if_new "$VAULT_ROOT/_templates/Daily Note.md" "---
title:
created:
modified:
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

echo ""

# --- northstar notes ---

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

Source tag for action items originating from email."

write_if_new "$VAULT_ROOT/Process/teams.md" "---
title:
created:
modified:
---

# teams

Source tag for action items originating from Teams."

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

# --- summary ---

printf "${_C_GREEN}[meridian] Vault scaffolded successfully.${_C_RESET}\n"
echo ""
echo "Next steps:"
_hint "1. Copy the snapshot script:"
_cmd  "cp weekly-snapshot.py '$VAULT_ROOT/.scripts/weekly-snapshot.py'"
_hint "2. Open Obsidian → Open folder as vault → $VAULT_ROOT"
_hint "3. Follow documentation/user-guide.md from Step 4 (Appearance Settings)"
echo ""
_warn "Rename Work/CurrentCompany/ to your actual company name after opening the vault."
echo ""
