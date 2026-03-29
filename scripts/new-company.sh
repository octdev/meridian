#!/usr/bin/env bash
# new-company.sh — interactively scaffold a new company under Work/ in an Obsidian vault
#
# Creates the standard company folder structure:
#   Work/[Company]/
#     Incidents/
#     People/
#     Projects/
#     Reference/
#     Vendors/
#
# Usage:
#   new-company.sh
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

# --- main ---
echo ""
echo "[Meridian] New Company"
echo ""

# Prompt: vault root
echo "  Where is your vault?"
read -rp "  Vault root path [.]: " vault_root
vault_root="${vault_root:-.}"
vault_root="${vault_root/#\~/$HOME}"

# Strip trailing slash
vault_root="${vault_root%/}"

if [[ ! -d "$vault_root" ]]; then
    _fail "Vault root does not exist: ${vault_root}"
    exit 1
fi

# Validate Work/ directory exists
if [[ ! -d "${vault_root}/Work" ]]; then
    _fail "Work/ directory does not exist in vault: ${vault_root}/Work"
    _hint "Ensure your vault was scaffolded correctly before adding a company."
    exit 1
fi

echo ""

# Prompt: company name
read -rp "  Company name (case-sensitive, used as folder name): " company_name

if [[ -z "$company_name" ]]; then
    _fail "Company name cannot be empty."
    exit 1
fi

echo ""
echo "[Meridian] Validating..."
echo ""

company_dir="${vault_root}/Work/${company_name}"

if [[ -e "$company_dir" ]]; then
    _fail "Company already exists: ${company_dir}"
    _hint "Choose a different name or verify you are not duplicating an existing company."
    exit 1
fi

_pass "No collision. Proceeding."

echo ""
echo "[Meridian] Scaffolding company..."
echo ""

# --- create directories ---
mkdir -p "${company_dir}/Incidents"
mkdir -p "${company_dir}/People"
mkdir -p "${company_dir}/Projects"
mkdir -p "${company_dir}/Reference"
mkdir -p "${company_dir}/Vendors"

_pass "Incidents/ created."
_pass "People/ created."
_pass "Projects/ created."
_pass "Reference/ created."
_pass "Vendors/ created."

echo ""
printf "${_C_GREEN}[Meridian] Company scaffolded.${_C_RESET} ${company_name} is ready.\n"
echo ""
_detail "Location: ${company_dir}"
_detail "Run new-project.sh to add a project under ${company_dir}/Projects/"
echo ""
