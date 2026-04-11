# SOURCED LIBRARY — do not execute directly.
#
# Provides refresh_vault_docs() for copying the latest documentation
# from the repo into a vault's Process/Meridian Documentation/ folder.
#
# Always overwrites existing documentation files with the latest source.
#
# Requires:
#   logging.sh — sourced before this library (_pass, _warn)

# Copies all documentation source files into the vault's documentation folder,
# overwriting any existing files. Soft-skips if the destination folder is absent
# (callers that require it should validate before calling).
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
  _overwrite_doc "$docs_src/User Setup.md"      "$docs_dest/User Setup.md"      "User Setup"
  _overwrite_doc "$docs_src/User Handbook.md"   "$docs_dest/User Handbook.md"   "User Handbook"
  _overwrite_doc "$docs_src/Reference Guide.md" "$docs_dest/Reference Guide.md" "Reference Guide"
  _overwrite_doc "$docs_src/Architecture.md"    "$docs_dest/Architecture.md"    "Architecture"
  _overwrite_doc "$docs_src/Design Decision.md" "$docs_dest/Design Decision.md" "Design Decision"
  _overwrite_doc "$docs_src/Security.md"        "$docs_dest/Security.md"        "Security"
  _overwrite_doc "$docs_src/Sync.md"            "$docs_dest/Sync.md"            "Sync"
  _overwrite_doc "$docs_src/Roadmap.md"         "$docs_dest/Roadmap.md"         "Roadmap"
  _overwrite_doc "$docs_src/Upgrades.md"        "$docs_dest/Upgrades.md"        "Upgrades"
  if [[ -f "${repo_dir}/Meridian System.pdf" ]]; then
    cp "${repo_dir}/Meridian System.pdf" "$docs_dest/Meridian System.pdf"
    _pass "Updated: Process/Meridian Documentation/Meridian System.pdf"
  fi
  echo ""
}
