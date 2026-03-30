#!/usr/bin/env bash
# new-company.sh — interactively scaffold a new company under Work/ in an Obsidian vault
#
# Creates the standard company folder structure:
#   Work/[Company]/
#     Finances/
#     General/
#     Goals/
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- libraries ---
# In-repo: src/bin/../lib/ = src/lib/  |  In vault: .scripts/../lib/ falls back to .scripts/lib/

LIB_DIR="${SCRIPT_DIR}/../lib"
[[ -d "$LIB_DIR" ]] || LIB_DIR="${SCRIPT_DIR}/lib"

source "$LIB_DIR/colors.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/errors.sh"

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
mkdir -p "${company_dir}/Finances"
mkdir -p "${company_dir}/General"
mkdir -p "${company_dir}/Goals"
mkdir -p "${company_dir}/Incidents"
mkdir -p "${company_dir}/People"
mkdir -p "${company_dir}/Projects"
mkdir -p "${company_dir}/Reference"
mkdir -p "${company_dir}/Vendors"

_pass "Finances/ created."
_pass "General/ created."
_pass "Goals/ created."
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
