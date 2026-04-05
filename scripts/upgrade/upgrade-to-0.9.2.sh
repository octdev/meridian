#!/usr/bin/env bash
# upgrade-to-0.9.2.sh — upgrades a Meridian vault to version 0.9.2
#
# Usage:
#   upgrade-to-0.9.2.sh [--vault <path>]
#
# Automatically chains all migrations between the vault's installed version
# and 0.9.2 in semver order. Each migration updates .scripts/.vault-version
# on success. A failure halts the chain and leaves the vault at the last
# successfully applied version.
#
# Exit codes:
#   0 — success (or already at target)
#   1 — failure

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "0.9.2" "${SCRIPT_DIR}/migrations" "$@"
