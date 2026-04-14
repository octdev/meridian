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

_RAW_BASE="https://raw.githubusercontent.com/octdev/meridian/main/src/documentation"
_API_REF="https://api.github.com/repos/octdev/meridian/git/refs/heads/main"
_DOC_SOURCE="local"
_EFFECTIVE_REPO_DIR="$REPO_DIR"
_FETCH_DIR=""

if [[ "$FROM_LOCAL" == false ]]; then
  echo "  Fetching documentation from origin/main..."

  _API_RESPONSE=""
  if ! _API_RESPONSE=$(curl -sf "$_API_REF" 2>/dev/null); then
    _warn "Could not reach GitHub — falling back to local documentation."
    echo ""
  else
    _COMMIT=$(echo "$_API_RESPONSE" \
      | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['object']['sha'][:7])" \
      2>/dev/null || echo "unknown")

    _DOC_FILES=(
      "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md"
      "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md" "Upgrading.md"
    )

    # Fetch into a temp directory so the local repo is never modified.
    _FETCH_DIR="$(mktemp -d)"
    mkdir -p "$_FETCH_DIR/src/documentation"
    _EFFECTIVE_REPO_DIR="$_FETCH_DIR"

    # Write each file to a temp file first; move into place only on success.
    # This prevents truncating an existing file if curl fails mid-fetch.
    _TMP=$(mktemp)
    trap 'rm -f "$_TMP"; [[ -n "$_FETCH_DIR" ]] && rm -rf "$_FETCH_DIR"' EXIT
    _FETCH_ERRORS=0
    for _f in "${_DOC_FILES[@]}"; do
      _encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$_f")
      if curl -sf "${_RAW_BASE}/${_encoded}" > "$_TMP"; then
        mv "$_TMP" "${_FETCH_DIR}/src/documentation/${_f}"
      else
        # Fall back to local copy for this file
        if [[ -f "${REPO_DIR}/src/documentation/${_f}" ]]; then
          cp "${REPO_DIR}/src/documentation/${_f}" "${_FETCH_DIR}/src/documentation/${_f}"
        fi
        _warn "Failed to fetch: $_f (using local copy)"
        _FETCH_ERRORS=$(( _FETCH_ERRORS + 1 ))
      fi
    done

    if [[ "$_FETCH_ERRORS" -eq 0 ]]; then
      _DOC_SOURCE="origin/main @ ${_COMMIT}"
    else
      _DOC_SOURCE="origin/main @ ${_COMMIT} (${_FETCH_ERRORS} file(s) fell back to local)"
    fi

    echo "  Synced to commit: $_COMMIT"
    echo ""
  fi
fi

# --- confirmation ---

echo "  Vault:       $VAULT_ROOT"
echo "  Destination: Process/Meridian Documentation/"
echo "  Source:      $_DOC_SOURCE"
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

refresh_vault_docs "$VAULT_ROOT" "$_EFFECTIVE_REPO_DIR"

echo "[meridian] Done."
echo ""
