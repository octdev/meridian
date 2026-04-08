#!/usr/bin/env bash
# migrations/v0.10.2.sh — vault changes for Meridian 0.10.2
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# This migration moves Drafts from Process/Drafts/ to a domain-scoped folder
# and updates .obsidian/app.json so Obsidian's "Default location for new notes"
# points to the new location.
#
#   Personal vault (Life/ exists):  Process/Drafts/ → Life/Drafts/
#   Work vault (Life/ absent):      Process/Drafts/ → Work/$COMPANY/Drafts/
#
# Detection is filesystem-based (idempotent):
#   Personal vault:  Life/ directory exists
#   Work vault:      Life/ directory does not exist
#
# Exit codes:
#   0 — success
#   1 — failure

set -euo pipefail

readonly VAULT_ROOT="$1"
readonly REPO_DIR="$2"
readonly COMPANY="${3:-}"

source "${REPO_DIR}/src/lib/logging.sh"
source "${REPO_DIR}/src/lib/errors.sh"

# --- helpers (inline — no cross-migration imports) ---

_remove_if_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  if [[ -z "$(find "$dir" -type f 2>/dev/null | head -1)" ]]; then
    rm -rf "$dir"
    _pass "Removed empty directory: ${dir#$VAULT_ROOT/}/"
  else
    _hint "Not removed (still contains files): ${dir#$VAULT_ROOT/}/"
  fi
}

# Move all files from $1 to $2, detecting conflicts.
# Sets _MOVED_COUNT and _CONFLICT_COUNT in caller scope.
_move_drafts() {
  local src_dir="$1" dest_dir="$2"
  _MOVED_COUNT=0
  _CONFLICT_COUNT=0
  _CONFLICT_FILES=()

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  local -a files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$src_dir" -maxdepth 1 -type f -print0 2>/dev/null || true)

  if [[ ${#files[@]} -eq 0 ]]; then
    return 0
  fi

  mkdir -p "$dest_dir"

  for src_file in "${files[@]}"; do
    local fname
    fname="$(basename "$src_file")"
    local dest_file="${dest_dir}/${fname}"
    if [[ -f "$dest_file" ]]; then
      _warn "Conflict — skipping (already exists in target): $fname"
      _CONFLICT_COUNT=$(( _CONFLICT_COUNT + 1 ))
      _CONFLICT_FILES+=("$fname")
    else
      mv "$src_file" "$dest_file" || die "move" "Could not move $src_file"
      _MOVED_COUNT=$(( _MOVED_COUNT + 1 ))
    fi
  done
}

# Update .obsidian/app.json to set the new Drafts folder as the default new
# note location. Uses sed to replace an existing newFileFolderPath value, or
# writes a minimal app.json if the key is absent. Leaves other app.json
# settings untouched if using sed; writes only the two new-note keys if
# creating the file from scratch.
_update_app_json() {
  local app_json="${VAULT_ROOT}/.obsidian/app.json"
  local new_path="$1"

  if [[ ! -f "$app_json" ]]; then
    mkdir -p "${VAULT_ROOT}/.obsidian"
    printf '{\n  "newFileLocation": "folder",\n  "newFileFolderPath": "%s"\n}\n' "$new_path" > "$app_json"
    _pass "Created: .obsidian/app.json → $new_path"
    return
  fi

  if grep -q '"newFileFolderPath"' "$app_json" 2>/dev/null; then
    sed -i.bak "s|\"newFileFolderPath\":.*|\"newFileFolderPath\": \"${new_path}\"|" "$app_json" \
      && rm -f "${app_json}.bak"
    _pass "Updated: .obsidian/app.json → $new_path"
  else
    _hint "app.json exists but newFileFolderPath not set."
    _hint "  Set manually: Settings → Files & Links → Default location for new notes"
    _hint "  → In the folder specified below → $new_path"
  fi
}

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v0.10.2 global migrations..."
  echo ""

  if [[ -d "${VAULT_ROOT}/Life" ]]; then
    # Personal vault — move Drafts to Life/Drafts/
    echo "  Personal vault detected — migrating Drafts..."

    mkdir -p "${VAULT_ROOT}/Life/Drafts"
    _pass "Ensured: Life/Drafts/"

    _MOVED_COUNT=0
    _CONFLICT_COUNT=0
    _CONFLICT_FILES=()
    _move_drafts "${VAULT_ROOT}/Process/Drafts" "${VAULT_ROOT}/Life/Drafts"

    if [[ $_MOVED_COUNT -gt 0 ]]; then
      _pass "Moved ${_MOVED_COUNT} file(s): Process/Drafts/ → Life/Drafts/"
    else
      _detail "  Process/Drafts/ was empty — nothing to move."
    fi
    if [[ $_CONFLICT_COUNT -gt 0 ]]; then
      _warn "${_CONFLICT_COUNT} conflict(s) skipped (files already exist in Life/Drafts/):"
      for _cf in "${_CONFLICT_FILES[@]:-}"; do
        _hint "  ${_cf}"
      done
    fi

    _remove_if_empty "${VAULT_ROOT}/Process/Drafts"

    _update_app_json "Life/Drafts"
    echo ""

  else
    # Work vault — Drafts migration deferred to per-company section
    _detail "Work vault detected — Drafts migration deferred to per-company step."
    echo ""
  fi

  _pass "v0.10.2 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v0.10.2 company migrations: $COMPANY..."
  echo ""

  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"

  if [[ ! -d "$COMPANY_DIR" ]]; then
    _warn "Company directory not found, skipping: Work/${COMPANY}"
    exit 0
  fi

  mkdir -p "${COMPANY_DIR}/Drafts"
  _pass "Ensured: Work/${COMPANY}/Drafts/"
  echo ""

  # Work vault only — move Process/Drafts/ to Work/$COMPANY/Drafts/
  if [[ ! -d "${VAULT_ROOT}/Life" ]]; then
    echo "  Moving Drafts..."
    _MOVED_COUNT=0
    _CONFLICT_COUNT=0
    _CONFLICT_FILES=()
    _move_drafts "${VAULT_ROOT}/Process/Drafts" "${COMPANY_DIR}/Drafts"

    if [[ $_MOVED_COUNT -gt 0 ]]; then
      _pass "Moved ${_MOVED_COUNT} file(s): Process/Drafts/ → Work/${COMPANY}/Drafts/"
    else
      _detail "  Process/Drafts/ was empty — nothing to move."
    fi
    if [[ $_CONFLICT_COUNT -gt 0 ]]; then
      _warn "${_CONFLICT_COUNT} conflict(s) skipped (files already exist in target):"
      for _cf in "${_CONFLICT_FILES[@]:-}"; do
        _hint "  ${_cf}"
      done
    fi

    _remove_if_empty "${VAULT_ROOT}/Process/Drafts"

    _update_app_json "Work/${COMPANY}/Drafts"
    echo ""

  else
    # Personal vault — app.json already updated in global section
    _detail "Personal vault — app.json updated in global step; no content migration needed here."
    echo ""
  fi

  _pass "v0.10.2 company migrations complete: $COMPANY"
fi
