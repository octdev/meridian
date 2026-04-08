#!/usr/bin/env bash
# upgrade-to-0.10.1.sh — upgrades a Meridian vault to version 0.10.1
#
# Usage:
#   upgrade-to-0.10.1.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 0.10.1 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# This release supersedes 0.10.0 entirely. The v0.10.0 migration had a bug
# where the per-company section incorrectly moved top-level Knowledge/ content
# on personal vaults and deleted the folder. This upgrade fixes that, whether
# your vault ran the broken 0.10.0 migration or is upgrading from an earlier
# version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.10.1" "${SCRIPT_DIR}/migrations" "$@"
