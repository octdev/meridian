#!/usr/bin/env bash
#
# refresh-documentation.sh — Fetches the latest documentation from origin/main
# on GitHub and copies it into the vault's Process/Meridian Documentation/
# folder, overwriting existing files.
#
# Usage:
#   refresh-documentation.sh [--vault <path>] [--from-local]
#   refresh-documentation.sh -h | --help
#
# If --vault is omitted, known vaults are listed and you are prompted to select
# one or enter a path.
#
# By default the script fetches current docs from origin/main via GitHub's raw
# content API before copying to the vault. No git objects are fetched; only the
# src/documentation/ files are modified. If GitHub is unreachable, the script
# warns and falls back to the docs bundled with the local repo.
#
# --from-local skips the network fetch entirely and copies from the local repo.
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
source "$REPO_DIR/src/lib/fetch-docs.sh"

usage() {
  cat <<EOF
Usage: refresh-documentation.sh [--vault <path>] [--from-local]
       refresh-documentation.sh -h | --help

Fetches the latest documentation from origin/main on GitHub and copies it
into the vault's Process/Meridian Documentation/ folder, overwriting existing
files. Falls back to the local repo if GitHub is unreachable.

If --vault is omitted, known vaults are listed for selection.

Options:
  --vault <path>   Path to vault root (skips interactive selection)
  --from-local     Skip the remote fetch; copy from the local repo only.

EOF
}

# --- argument parsing ---

VAULT_ROOT=""
FROM_LOCAL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --vault requires a path." >&2; usage >&2; exit 1; }
      VAULT_ROOT="$2"; shift 2 ;;
    --from-local)
      FROM_LOCAL=true; shift ;;
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

# --- remote fetch via GitHub raw API ---

if [[ "$FROM_LOCAL" == false ]]; then
  echo "  Fetching documentation from origin/main..."
fi

_from_local_flag=""
[[ "$FROM_LOCAL" == true ]] && _from_local_flag="--from-local"
fetch_docs_from_remote "$REPO_DIR" $_from_local_flag
trap '[[ "$FETCH_EFFECTIVE_REPO_DIR" != "$REPO_DIR" ]] && rm -rf "$FETCH_EFFECTIVE_REPO_DIR"' EXIT

# --- confirmation ---

echo "  Vault:       $VAULT_ROOT"
echo "  Destination: Process/Meridian Documentation/"
echo "  Source:      $FETCH_DOC_SOURCE"
echo ""
echo "  This will overwrite all existing documentation files."
echo ""
read -rp "  Proceed? [Y/n]: " _confirm
echo ""

if [[ "$_confirm" =~ ^[Nn] ]]; then
  echo "Aborted."
  echo ""
  exit 0
fi

# --- refresh ---

refresh_vault_docs "$VAULT_ROOT" "$FETCH_EFFECTIVE_REPO_DIR"

echo "[meridian] Done."
echo ""
