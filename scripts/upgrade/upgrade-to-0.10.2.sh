#!/usr/bin/env bash
# upgrade-to-0.10.2.sh — upgrades a Meridian vault to version 0.10.2
#
# Usage:
#   upgrade-to-0.10.2.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 0.10.2 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# This release moves Drafts from Process/Drafts/ to a domain-scoped folder:
#   Personal vault (Life/ exists):  Process/Drafts/ → Life/Drafts/
#   Work vault (Life/ absent):      Process/Drafts/ → Work/<Company>/Drafts/
# .obsidian/app.json is updated to reflect the new default new note location.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.10.2" "${SCRIPT_DIR}/migrations" "$@"
