#!/usr/bin/env bash
#
# refresh-documentation.sh — Copies the latest documentation from the repo
# into the vault's Process/Meridian Documentation/ folder, overwriting existing
# files with the current versions.
#
# Usage:
#   refresh-documentation.sh [--vault <path>] [--from-remote]
#   refresh-documentation.sh -h | --help
#
# If --vault is omitted, known vaults are listed and you are prompted to select
# one or enter a path.
#
# --from-remote fetches the current documentation from origin/main on GitHub
# before copying to the vault. Useful when on the `latest` branch and docs
# have been updated between releases. No git objects are fetched; only the
# src/documentation/ files are modified.
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
Usage: refresh-documentation.sh [--vault <path>] [--from-remote]
       refresh-documentation.sh -h | --help

Copies the latest documentation from the repo into the vault's
Process/Meridian Documentation/ folder, overwriting existing files.

If --vault is omitted, known vaults are listed for selection.

Options:
  --vault <path>   Path to vault root (skips interactive selection)
  --from-remote    Fetch current docs from origin/main on GitHub before
                   copying to vault. Updates src/documentation/ in place;
                   no git objects are fetched.

EOF
}

# --- argument parsing ---

VAULT_ROOT=""
FROM_REMOTE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault)
      [[ -n "${2:-}" ]] || { echo "[meridian] Error: --vault requires a path." >&2; usage >&2; exit 1; }
      VAULT_ROOT="$2"; shift 2 ;;
    --from-remote)
      FROM_REMOTE=true; shift ;;
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

if [[ "$FROM_REMOTE" == true ]]; then
  _RAW_BASE="https://raw.githubusercontent.com/octdev/meridian/main/src/documentation"
  _API_REF="https://api.github.com/repos/octdev/meridian/git/refs/heads/main"
  _DOCS_SRC="${REPO_DIR}/src/documentation"

  echo "  Fetching documentation from origin/main..."

  # Pre-flight: verify GitHub is reachable before touching any local files.
  # A failed curl here means network is down, DNS failed, or GitHub is unavailable.
  if ! _API_RESPONSE=$(curl -sf "$_API_REF" 2>/dev/null); then
    die "remote-unavailable" "Could not reach GitHub. Check your network connection and try again."
  fi

  _COMMIT=$(echo "$_API_RESPONSE" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['object']['sha'][:7])" \
    2>/dev/null || echo "unknown")

  _DOC_FILES=(
    "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md"
    "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md" "Upgrading.md"
  )
  # Write to a temp file first; move into place only on success.
  # This prevents truncating the existing file if curl fails mid-fetch.
  _TMP=$(mktemp)
  trap 'rm -f "$_TMP"' EXIT
  _FETCH_ERRORS=0
  for _f in "${_DOC_FILES[@]}"; do
    _encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$_f")
    if curl -sf "${_RAW_BASE}/${_encoded}" > "$_TMP"; then
      mv "$_TMP" "${_DOCS_SRC}/${_f}"
    else
      _warn "Failed to fetch: $_f"
      _FETCH_ERRORS=$(( _FETCH_ERRORS + 1 ))
    fi
  done
  [[ "$_FETCH_ERRORS" -eq 0 ]] || die "fetch-failed" "$_FETCH_ERRORS file(s) could not be fetched."

  echo "  Synced to commit: $_COMMIT"
  _CHANGED=$(git -C "$REPO_DIR" diff --name-only HEAD -- src/documentation/ 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$_CHANGED" -gt 0 ]]; then
    echo "  Changed files:"
    git -C "$REPO_DIR" diff --name-only HEAD -- src/documentation/ | sed 's/^/    ~ /'
  else
    echo "  No documentation changes detected."
  fi
  echo ""
fi

# --- confirmation ---

echo "  Vault:       $VAULT_ROOT"
echo "  Destination: Process/Meridian Documentation/"
if [[ "$FROM_REMOTE" == true ]]; then
  echo "  Source:      origin/main (remote)"
fi
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
