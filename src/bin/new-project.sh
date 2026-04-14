#!/usr/bin/env bash
# new-project.sh — scaffold a new project in a Meridian vault
# Usage: new-project.sh --vault <path> --name <name> --projects-dir <path>
#        new-project.sh            (all inputs prompted interactively)
#
# Creates the standard project folder structure under a Projects/ directory,
# seeding each file with frontmatter and starter content.
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# In-repo: src/bin/../lib/ = src/lib/  |  In vault: .scripts/../lib/ falls back to .scripts/lib/
LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -d "$LIB_DIR" ]] || LIB_DIR="${SCRIPT_DIR}/lib"

source "$LIB_DIR/colors.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/errors.sh"
source "$LIB_DIR/vault-select.sh"

# ── Write helper (aborts if file already exists) ──────────────────────────────

write_file() {
  local path="$1"
  local content="$2"
  [[ -e "$path" ]] && die "File already exists: $path" "Aborting — no files were modified."
  printf '%s\n' "$content" > "$path"
}

# ── Argument parsing ──────────────────────────────────────────────────────────

VAULT=""
PROJECT_NAME=""
PROJECTS_DIR=""
YES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)        VAULT="${2:?--vault requires a path}";              shift 2 ;;
    --name)         PROJECT_NAME="${2:?--name requires a value}";       shift 2 ;;
    --projects-dir) PROJECTS_DIR="${2:?--projects-dir requires a path}"; shift 2 ;;
    --yes|-y)       YES=true; shift ;;
    *) die "Unknown argument: $1" "" ;;
  esac
done

[[ "$YES" == true ]] && MERIDIAN_YES=1

# ── Vault validation ──────────────────────────────────────────────────────────

echo ""
echo "[meridian] New Project"
echo ""

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

# ── Project name ──────────────────────────────────────────────────────────────

if [[ -z "$PROJECT_NAME" ]]; then
  read -rp "$(printf "${_C_CYAN}Project name:${_C_RESET} ")" PROJECT_NAME
fi

[[ -n "$PROJECT_NAME" ]]           || die "Project name cannot be empty." ""
[[ "$PROJECT_NAME" != */* ]]       || die "Project name may not contain /." ""
[[ "$PROJECT_NAME" != *'"'* ]]     || die 'Project name may not contain ".' ""

# ── Projects directory ────────────────────────────────────────────────────────

if [[ -z "$PROJECTS_DIR" ]]; then
  # Determine a sensible default:
  # 1. Active/default company from daily-notes.json or DefaultCompany in .vault-version
  # 2. Life/Projects (if it exists)
  # 3. Exactly one Work/*/Projects directory
  _DEFAULT_PROJECTS_DIR=""
  _resolved_company=""

  detect_current_company "$VAULT"
  if [[ -n "$CURRENT_COMPANY" && "$CURRENT_COMPANY" != "CurrentCompany" ]]; then
    _resolved_company="$CURRENT_COMPANY"
  else
    get_default_company "$VAULT"
    if [[ -n "$DEFAULT_COMPANY" && "$DEFAULT_COMPANY" != "CurrentCompany" ]]; then
      _resolved_company="$DEFAULT_COMPANY"
    fi
  fi

  if [[ -n "$_resolved_company" && -d "$VAULT/Work/$_resolved_company/Projects" ]]; then
    _DEFAULT_PROJECTS_DIR="$VAULT/Work/$_resolved_company/Projects"
  elif [[ -d "$VAULT/Life/Projects" ]]; then
    _DEFAULT_PROJECTS_DIR="$VAULT/Life/Projects"
  else
    _work_matches=()
    for _d in "$VAULT/Work"/*/Projects; do
      [[ -d "$_d" ]] && _work_matches+=("$_d")
    done
    [[ ${#_work_matches[@]} -eq 1 ]] && _DEFAULT_PROJECTS_DIR="${_work_matches[0]}"
    unset _work_matches _d
  fi
  unset _resolved_company

  echo ""
  _detail "Expected locations:"
  _detail "  $VAULT/Work/[Company]/Projects/"
  _detail "  $VAULT/Life/Projects/"
  echo ""
  if [[ -n "$_DEFAULT_PROJECTS_DIR" ]]; then
    read -rp "$(printf "${_C_CYAN}Full path to Projects directory [${_DEFAULT_PROJECTS_DIR}]:${_C_RESET} ")" PROJECTS_DIR
    PROJECTS_DIR="${PROJECTS_DIR:-$_DEFAULT_PROJECTS_DIR}"
  else
    read -rp "$(printf "${_C_CYAN}Full path to Projects directory:${_C_RESET} ")" PROJECTS_DIR
  fi
  unset _DEFAULT_PROJECTS_DIR
fi

PROJECTS_DIR="${PROJECTS_DIR/#\~/$HOME}"
PROJECTS_DIR="${PROJECTS_DIR%/}"

[[ -n "$PROJECTS_DIR" ]] || die "Projects directory cannot be empty." ""
[[ -d "$PROJECTS_DIR" ]] || die "Projects directory not found: $PROJECTS_DIR" "Create it first with 'New Company', or verify the path."

# ── Validate location ─────────────────────────────────────────────────────────

LIFE_PATTERN="$VAULT/Life/Projects"
VAULT_ROOT_RE=$(printf '%s\n' "$VAULT" | sed 's/[.[\*^$()+?{}|]/\\&/g')
WORK_PATTERN_RE="^${VAULT_ROOT_RE}/Work/[^/]+/Projects$"

if [[ "$PROJECTS_DIR" != "$LIFE_PATTERN" ]] && \
   [[ ! "$PROJECTS_DIR" =~ $WORK_PATTERN_RE ]]; then
  _warn "Unexpected Projects path: $PROJECTS_DIR"
  _hint "Expected: $VAULT/Work/[Company]/Projects/ or $VAULT/Life/Projects/"
  echo ""
  if [[ "$YES" == false ]]; then
    read -rp "$(printf "${_C_CYAN}Continue anyway? [Y/n]:${_C_RESET} ")" _override
    [[ "$_override" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 1; }
  fi
fi

# ── Collision check ───────────────────────────────────────────────────────────

PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

if [[ -e "$PROJECT_DIR" ]]; then
  die "Project already exists: $PROJECT_DIR" "Choose a different name or remove the existing directory."
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
_detail "Project:  $PROJECT_NAME"
_detail "Location: $PROJECT_DIR"
echo ""
if [[ "$YES" == false ]]; then
  read -rp "$(printf "${_C_CYAN}Create? [Y/n]:${_C_RESET} ")" CONFIRM
  [[ "$CONFIRM" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }
fi

# ── Scaffold ──────────────────────────────────────────────────────────────────

echo ""

TODAY="$(date +%Y-%m-%d)"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
PROJ_REL="${PROJECTS_DIR#"${VAULT}/"}"  # vault-relative path for Dataview/Tasks queries

mkdir -p "$PROJECT_DIR/Design"
mkdir -p "$PROJECT_DIR/Requirements"
mkdir -p "$PROJECT_DIR/Prompts"
_pass "Directories created."

# Project index (MOC)
write_file "$PROJECT_DIR/$PROJECT_NAME.md" "---
title: $PROJECT_NAME
created: $NOW
modified: $NOW
---
# $PROJECT_NAME

## Files

\`\`\`dataview
LIST FROM \"$PROJ_REL/$PROJECT_NAME\"
SORT file.name ASC
\`\`\`

## Action Items — Urgent

\`\`\`tasks
not done
description includes !!
path includes $PROJ_REL/$PROJECT_NAME
sort by filename reverse
\`\`\`

## Action Items — Standard

\`\`\`tasks
not done
description includes !
description does not include !!
path includes $PROJ_REL/$PROJECT_NAME
sort by filename reverse
\`\`\`

## Open Loops

\`\`\`tasks
not done
description includes ~
path includes $PROJ_REL/$PROJECT_NAME
sort by filename reverse
\`\`\`

## Decisions

\`\`\`dataview
LIST FROM \"$PROJ_REL/$PROJECT_NAME\"
WHERE contains(file.name, \"design-decisions\")
\`\`\`
"
_pass "Project index (MOC) created."

# Design/architecture.md
write_file "$PROJECT_DIR/Design/architecture.md" "---
title: \"Architecture — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# Architecture — $PROJECT_NAME

## Conceptual Model

## Repository Structure

## Runtime

## Data Flows

## Key Specifications
"
_pass "Design/architecture.md created."

# Design/design-decisions.md
write_file "$PROJECT_DIR/Design/design-decisions.md" "---
title: \"Design Decisions — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# Design Decisions — $PROJECT_NAME

## DD-01: <Short Decision Title>

**Decision:**

**Rationale:**

**Tradeoff:**
"
_pass "Design/design-decisions.md created."

# Design/security.md
write_file "$PROJECT_DIR/Design/security.md" "---
title: \"Security — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# Security — $PROJECT_NAME

## Threat Model

## Defense Layers

## Accepted Tradeoffs

## Security Checklist

- [ ]
"
_pass "Design/security.md created."

# Requirements/brd.md
write_file "$PROJECT_DIR/Requirements/brd.md" "---
title: \"BRD — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# BRD — $PROJECT_NAME

## Overview

## Problem Statement

## Goals

1.

## Non-Goals

-

## Personas

## Functional Requirements

### FR-01:

## Constraints

## Success Criteria
"
_pass "Requirements/brd.md created."

# Requirements/user-guide.md
write_file "$PROJECT_DIR/Requirements/user-guide.md" "---
title: \"User Guide — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# User Guide — $PROJECT_NAME

## How It Works

## Platform Requirements and Dependencies

## Initial Setup

## Core Workflow

## Daily Operation

## Maintenance Procedures
"
_pass "Requirements/user-guide.md created."

# Requirements/roadmap.md
write_file "$PROJECT_DIR/Requirements/roadmap.md" "---
title: \"Roadmap — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# Roadmap — $PROJECT_NAME

## <Feature Name>

**Current:**

**Future:**

**Notes:**
"
_pass "Requirements/roadmap.md created."

# Prompts/scratch.md
write_file "$PROJECT_DIR/Prompts/scratch.md" "---
title: \"Scratch — $PROJECT_NAME\"
created: $NOW
modified: $NOW
---
# Scratch

## $TODAY

-
"
_pass "Prompts/scratch.md created."

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
printf "${_C_GREEN}[meridian] Project scaffolded.${_C_RESET}\n"
echo ""
_detail "Location: $PROJECT_DIR"
echo ""
