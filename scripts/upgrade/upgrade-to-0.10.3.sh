#!/usr/bin/env bash
# upgrade-to-0.10.3.sh — upgrades a Meridian vault to version 0.10.3
#
# Usage:
#   upgrade-to-0.10.3.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 0.10.3 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# This release sets the default attachment folder in .obsidian/app.json
# to a domain-scoped location:
#   Personal vault (Life/ exists):  References
#   Work vault (Life/ absent):      Work/<Company>/Reference
#
# IMPORTANT: Close Obsidian before running this upgrade. If Obsidian is
# open, it will overwrite app.json with its cached settings on close,
# discarding the migration changes.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.10.3" "${SCRIPT_DIR}/migrations" "$@"
