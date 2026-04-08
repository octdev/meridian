#!/usr/bin/env bash
# upgrade-to-0.10.0.sh — upgrades a Meridian vault to version 0.10.0
#
# Usage:
#   upgrade-to-0.10.0.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed
# version and 0.10.0 in order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain at the last successful version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.10.0" "${SCRIPT_DIR}/migrations" "$@"
