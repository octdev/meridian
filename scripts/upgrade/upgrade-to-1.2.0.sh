#!/usr/bin/env bash
# upgrade-to-1.2.0.sh — upgrades a Meridian vault to version 1.2.0
#
# Usage:
#   upgrade-to-1.2.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 1.2.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Changes in this release:
#   - Current Priorities.md moved from Process/ to Work/<Company>/Goals/
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "1.2.0" "${SCRIPT_DIR}/migrations" "$@"
