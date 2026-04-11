#!/usr/bin/env bash
#
# refresh-documentation.sh — Copies the latest documentation from the repo
# into the vault's Process/Meridian Documentation/ folder, overwriting existing
# files with the current versions.
#
# Usage:
#   refresh-documentation.sh [--vault <path>]
#   refresh-documentation.sh -h | --help
#
# If --vault is omitted, known vaults are listed and you are prompted to select
# one or enter a path.
#
# Exit codes:
#   0 — success (or user cancelled at confirmation prompt)
#   1 — failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- libraries ---

source "$REPO_DIR/src/lib/colors.sh"
source "$REPO_DIR/src/lib/logging.sh"
source "$REPO_DIR/src/lib/errors.sh"
source "$REPO_DIR/src/lib/vault-select.sh"
source "$REPO_DIR/src/lib/refresh-vault-docs.sh"

usage() {
  cat <<EOF
Usage: refresh-documentation.sh [--vault <path>]
       refresh-documentation.sh -h | --help

Copies the latest documentation from the repo into the vault's
Process/Meridian Documentation/ folder, overwriting existing files.

If --vault is omitted, known vaults are listed for selection.

Options:
  --vault <path>   Path to vault root (skips interactive selection)

EOF
}

# --- argument parsing ---

VAULT_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --vault requires a path." >&2; usage >&2; exit 1; }
      VAULT_ROOT="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "[meridian] Error: unknown argument: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# --- vault resolution ---

echo ""
echo "[meridian] Refresh Documentation"
echo ""

if [[ -z "$VAULT_ROOT" ]]; then
  select_vault
fi

[[ -d "$VAULT_ROOT" ]] || die "vault-not-found" "Vault directory not found: $VAULT_ROOT"

DOCS_DEST="$VAULT_ROOT/Process/Meridian Documentation"
[[ -d "$DOCS_DEST" ]] || die "docs-not-found" "Documentation directory not found: $DOCS_DEST"

# --- confirmation ---

echo "  Vault:       $VAULT_ROOT"
echo "  Destination: Process/Meridian Documentation/"
echo ""
echo "  This will overwrite all existing documentation files."
echo ""
read -rp "  Proceed? [Y/n]: " _confirm
echo ""

if [[ "$_confirm" =~ ^[Nn] ]]; then
  echo "[meridian] Cancelled."
  echo ""
  exit 0
fi

# --- refresh ---

refresh_vault_docs "$VAULT_ROOT" "$REPO_DIR"

echo "[meridian] Done."
echo ""
