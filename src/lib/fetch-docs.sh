# SOURCED LIBRARY — do not execute directly.
#
# Canonical documentation file list and remote fetch helper for Meridian scripts.
#
# Requires:
#   logging.sh — sourced before this library (_warn)

# Canonical list of Meridian documentation markdown filenames.
# Used by fetch_docs_from_remote(), refresh_vault_docs(), and scaffold-vault.sh.
_MERIDIAN_DOC_FILES=(
  "User Setup.md"
  "User Handbook.md"
  "Reference Guide.md"
  "Architecture.md"
  "Design Decision.md"
  "Security.md"
  "Sync.md"
  "Roadmap.md"
  "Upgrading.md"
)

# Vault titles corresponding to _MERIDIAN_DOC_FILES (same order).
_MERIDIAN_DOC_TITLES=(
  "User Setup"
  "User Handbook"
  "Reference Guide"
  "Architecture"
  "Design Decision"
  "Security"
  "Sync"
  "Roadmap"
  "Upgrading"
)

# Fetches the current documentation from origin/main via the GitHub raw API
# into a temp directory and sets two variables for the caller:
#
#   FETCH_EFFECTIVE_REPO_DIR — path containing fetched src/documentation/
#                              (temp dir on success, repo_dir on skip/failure)
#   FETCH_DOC_SOURCE         — human-readable source label for display
#
# If FETCH_EFFECTIVE_REPO_DIR differs from repo_dir, the caller is responsible
# for cleanup (rm -rf "$FETCH_EFFECTIVE_REPO_DIR").
#
# Usage: fetch_docs_from_remote <repo_dir> [--from-local]
#   --from-local  Skip the network fetch; use the local repo directly.
fetch_docs_from_remote() {
  local repo_dir="$1"
  local from_local=false
  [[ "${2:-}" == "--from-local" ]] && from_local=true

  FETCH_EFFECTIVE_REPO_DIR="$repo_dir"
  FETCH_DOC_SOURCE="local"

  if [[ "$from_local" == true ]]; then
    return 0
  fi

  local _raw_base="https://raw.githubusercontent.com/octdev/meridian/main/src/documentation"
  local _api_ref="https://api.github.com/repos/octdev/meridian/git/refs/heads/main"

  local _api_response=""
  if ! _api_response=$(curl -sf "$_api_ref" 2>/dev/null); then
    _warn "Could not reach GitHub — falling back to local documentation."
    return 0
  fi

  local _fetch_dir _tmp
  _fetch_dir="$(mktemp -d)"
  mkdir -p "${_fetch_dir}/src/documentation"
  _tmp=$(mktemp)
  trap 'rm -f "$_tmp"; rm -rf "$_fetch_dir"' EXIT

  local _fetch_errors=0
  for _f in "${_MERIDIAN_DOC_FILES[@]}"; do
    local _encoded
    _encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$_f")
    if curl -sf "${_raw_base}/${_encoded}" > "$_tmp"; then
      mv "$_tmp" "${_fetch_dir}/src/documentation/${_f}"
    else
      if [[ -f "${repo_dir}/src/documentation/${_f}" ]]; then
        cp "${repo_dir}/src/documentation/${_f}" "${_fetch_dir}/src/documentation/${_f}"
      fi
      _warn "Failed to fetch: $_f (using local copy)"
      _fetch_errors=$(( _fetch_errors + 1 ))
    fi
  done

  FETCH_EFFECTIVE_REPO_DIR="$_fetch_dir"

  if [[ "$_fetch_errors" -eq 0 ]]; then
    FETCH_DOC_SOURCE="origin/main"
  else
    FETCH_DOC_SOURCE="origin/main (some files fell back to local)"
  fi
}
