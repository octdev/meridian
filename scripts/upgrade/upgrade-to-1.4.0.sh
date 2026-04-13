#!/usr/bin/env bash
# upgrade-to-1.4.0.sh — upgrades a Meridian vault to version 1.4.0
#
# Usage:
#   upgrade-to-1.4.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 1.4.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Changes in this release:
#   - new-1on1.sh added to .scripts/
#   - new-company.sh, new-project.sh, new-meeting-series.sh updated in .scripts/
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "1.4.0" "${SCRIPT_DIR}/migrations" "$@"
