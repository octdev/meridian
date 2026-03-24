#!/usr/bin/env bash
# new-project.sh — interactively scaffold a new project in an Obsidian vault
#
# Creates the standard project folder structure under a specified Projects/
# directory, seeding each file with correct frontmatter and content.
#
# Usage:
#   new-project.sh
#
# Exit codes:
#   0 — success
#   1 — failure (details printed above)

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

# --- helper functions ---
_pass()   { printf "  ${_C_GREEN}✓ %s${_C_RESET}\n" "$*"; }
_fail()   { printf "  ${_C_RED}✗ %s${_C_RESET}\n" "$*" >&2; }
_warn()   { printf "  ${_C_AMBER}⚠ %s${_C_RESET}\n" "$*"; }
_hint()   { echo "       $*"; }
_detail() { echo "       $*"; }
_cmd()    { printf "         ${_C_CYAN}%s${_C_RESET}\n" "$*" >&2; }

die() {
    local step="$1"
    local hint="$2"
    echo "" >&2
    _fail "Step failed: ${step}"
    _hint "${hint}"
    exit 1
}

# --- write a file, aborting if it already exists ---
write_file() {
    local path="$1"
    local content="$2"
    if [[ -e "$path" ]]; then
        die "write_file" "File already exists: ${path}"
    fi
    printf '%s\n' "$content" > "$path"
}

# --- main ---
echo ""
echo "[Meridian] New Project"
echo ""

# Prompt: project name
read -rp "  Project name: " project_name
if [[ -z "$project_name" ]]; then
    _fail "Project name cannot be empty."
    exit 1
fi
echo ""

# Prompt: vault root
echo "  Where is your vault?"
read -rp "  Vault root path: " vault_root

if [[ -z "$vault_root" ]]; then
    _fail "Vault root cannot be empty."
    exit 1
fi

# Strip trailing slash
vault_root="${vault_root%/}"

if [[ ! -d "$vault_root" ]]; then
    _fail "Vault root does not exist: ${vault_root}"
    exit 1
fi
echo ""

# Prompt: projects directory
echo "  Where should this project live?"
_hint "Expected locations:"
_cmd "${vault_root}/Work/[COMPANY]/Projects/"
_cmd "${vault_root}/Life/Projects/"
echo ""
read -rp "  Full path to Projects directory: " projects_dir

if [[ -z "$projects_dir" ]]; then
    _fail "Projects directory cannot be empty."
    exit 1
fi

# Strip trailing slash
projects_dir="${projects_dir%/}"

echo ""
echo "[Meridian] Validating location..."
echo ""

# Validate: directory must exist
if [[ ! -d "$projects_dir" ]]; then
    _fail "Directory does not exist: ${projects_dir}"
    _hint "Create it first with new-company.sh, or verify the path."
    exit 1
fi

# Warn if path does not match expected patterns
life_pattern="${vault_root}/Life/Projects"
work_pattern_re="^${vault_root}/Work/[^/]+/Projects$"

if [[ "$projects_dir" != "$life_pattern" ]] && \
   [[ ! "$projects_dir" =~ $work_pattern_re ]]; then
    _warn "Unexpected Projects path: ${projects_dir}"
    _hint "Expected: ${vault_root}/Work/[COMPANY]/Projects/ or ${vault_root}/Life/Projects/"
    echo ""
    read -rp "  Continue anyway? [y/N] " confirm
    echo ""
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "[Meridian] Aborted."
        exit 1
    fi
else
    _pass "Location is valid."
fi

echo ""
echo "[Meridian] Checking for collision..."
echo ""

project_dir="${projects_dir}/${project_name}"

if [[ -e "$project_dir" ]]; then
    _fail "Project already exists: ${project_dir}"
    _hint "Choose a different name or remove the existing project directory."
    exit 1
fi

_pass "No collision. Proceeding."

echo ""
echo "[Meridian] Scaffolding project..."
echo ""

# --- date for frontmatter ---
today="$(date +%Y-%m-%d)"

# --- create directories ---
mkdir -p "${project_dir}/Design"
mkdir -p "${project_dir}/Requirements"
mkdir -p "${project_dir}/Prompts"
_pass "Directories created."

# --- project index (MOC) ---
write_file "${project_dir}/${project_name}.md" "---
title: ${project_name}
created: ${today}
modified: ${today}
---

# ${project_name}

## Files

\`\`\`dataview
LIST FROM \"${projects_dir#"${vault_root}/"}/${project_name}\"
SORT file.name ASC
\`\`\`

## Action Items — Urgent

\`\`\`tasks
not done
description includes !!
path includes ${projects_dir#"${vault_root}/"}/${project_name}
sort by filename reverse
\`\`\`

## Action Items — Standard

\`\`\`tasks
not done
description includes !
description does not include !!
path includes ${projects_dir#"${vault_root}/"}/${project_name}
sort by filename reverse
\`\`\`

## Open Loops

\`\`\`tasks
not done
description includes ~
path includes ${projects_dir#"${vault_root}/"}/${project_name}
sort by filename reverse
\`\`\`

## Decisions

\`\`\`dataview
LIST FROM \"${projects_dir#"${vault_root}/"}/${project_name}\"
WHERE contains(file.name, \"design-decisions\")
\`\`\`
"
_pass "Project index (MOC) created."

# --- Design/architecture.md ---
write_file "${project_dir}/Design/architecture.md" "---
title: Architecture — ${project_name}
created: ${today}
modified: ${today}
---

# Architecture — ${project_name}

## Conceptual Model

## Repository Structure

## Runtime

## Data Flows

## Key Specifications
"
_pass "Design/architecture.md created."

# --- Design/design-decisions.md ---
write_file "${project_dir}/Design/design-decisions.md" "---
title: Design Decisions — ${project_name}
created: ${today}
modified: ${today}
---

# Design Decisions — ${project_name}

## DD-01: <Short Decision Title>

**Decision:** 

**Rationale:** 

**Tradeoff:** 
"
_pass "Design/design-decisions.md created."

# --- Design/security.md ---
write_file "${project_dir}/Design/security.md" "---
title: Security — ${project_name}
created: ${today}
modified: ${today}
---

# Security — ${project_name}

## Threat Model

## Defense Layers

## Accepted Tradeoffs

## Security Checklist

- [ ] 
"
_pass "Design/security.md created."

# --- Requirements/brd.md ---
write_file "${project_dir}/Requirements/brd.md" "---
title: BRD — ${project_name}
created: ${today}
modified: ${today}
---

# BRD — ${project_name}

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

# --- Requirements/user-guide.md ---
write_file "${project_dir}/Requirements/user-guide.md" "---
title: User Guide — ${project_name}
created: ${today}
modified: ${today}
---

# User Guide — ${project_name}

## How It Works

## Platform Requirements and Dependencies

## Initial Setup

## Core Workflow

## Daily Operation

## Maintenance Procedures
"
_pass "Requirements/user-guide.md created."

# --- Requirements/roadmap.md ---
write_file "${project_dir}/Requirements/roadmap.md" "---
title: Roadmap — ${project_name}
created: ${today}
modified: ${today}
---

# Roadmap — ${project_name}

## <Feature Name>

**Current:** 

**Future:** 

**Notes:** 
"
_pass "Requirements/roadmap.md created."

# --- Prompts/scratch.md ---
write_file "${project_dir}/Prompts/scratch.md" "---
title: Scratch — ${project_name}
created: ${today}
modified: ${today}
---

# Scratch

## ${today}

- 
"
_pass "Prompts/scratch.md created."

echo ""
printf "${_C_GREEN}[Meridian] Project scaffolded.${_C_RESET} ${project_name} is ready.\n"
echo ""
_detail "Location: ${project_dir}"
echo ""
