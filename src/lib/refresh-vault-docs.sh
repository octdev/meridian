# SOURCED LIBRARY — do not execute directly.
#
# Provides refresh_vault_docs() for copying the latest documentation
# from the repo into a vault's Process/Meridian Documentation/ folder.
#
# Always overwrites existing documentation files with the latest source,
# and removes any files in the directory that are not part of the current
# documentation set. The directory is entirely Meridian-managed.
#
# Requires:
#   logging.sh   — sourced before this library (_pass, _warn)
#   fetch-docs.sh — sourced before this library (_MERIDIAN_DOC_FILES, _MERIDIAN_DOC_TITLES)

_refresh_vault_docs_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_refresh_vault_docs_lib_dir}/fetch-docs.sh"

# Copies all documentation source files into the vault's documentation folder,
# overwriting any existing files and removing any stale ones. Soft-skips if
# the destination folder is absent (callers that require it should validate
# before calling).
#
# Usage: refresh_vault_docs <vault_root> <repo_dir>
refresh_vault_docs() {
  local vault_root="$1" repo_dir="$2"
  local docs_src="${repo_dir}/src/documentation"
  local docs_dest="${vault_root}/Process/Meridian Documentation"
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"

  if [[ ! -d "$docs_dest" ]]; then
    _warn "Documentation directory not found, skipping refresh."
    return
  fi

  _overwrite_doc() {
    local src="$1" dest="$2" title="$3"
    if [[ ! -f "$src" ]]; then
      _warn "Source not found, skipping: $(basename "$src")"
      return
    fi
    { printf -- '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n' "$title" "$ts" "$ts"
      cat "$src"
    } > "$dest"
    _pass "Updated: ${dest#$vault_root/}"
  }

  echo "[meridian] Refreshing documentation..."
  echo ""

  local i
  for (( i = 0; i < ${#_MERIDIAN_DOC_FILES[@]}; i++ )); do
    local _fname="${_MERIDIAN_DOC_FILES[$i]}"
    local _title="${_MERIDIAN_DOC_TITLES[$i]}"
    _overwrite_doc "${docs_src}/${_fname}" "${docs_dest}/${_fname}" "$_title"
  done

  if [[ -f "${repo_dir}/Meridian System.pdf" ]]; then
    cp "${repo_dir}/Meridian System.pdf" "$docs_dest/Meridian System.pdf"
    _pass "Updated: Process/Meridian Documentation/Meridian System.pdf"
  fi

  # Remove any files not in the current documentation set.
  # Process/Meridian Documentation/ is entirely Meridian-managed, so stale
  # files from renamed or removed docs should not persist across refreshes.
  while IFS= read -r -d '' _f; do
    local _base _known
    _base="$(basename "$_f")"
    _known=false
    for _cf in "${_MERIDIAN_DOC_FILES[@]}" "Meridian System.pdf"; do
      [[ "$_base" == "$_cf" ]] && _known=true && break
    done
    if [[ "$_known" == false ]]; then
      rm "$_f"
      _pass "Removed stale: ${_f#$vault_root/}"
    fi
  done < <(find "$docs_dest" -maxdepth 1 -type f -print0)

  echo ""
}
