#!/usr/bin/env bash
# migrations/v0.10.1.sh — vault changes for Meridian 0.10.1
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# This script supersedes v0.10.0.sh entirely. It handles two cases:
#
#   1. Vault already at 0.10.0 (ran the broken migration):
#      The per-company section of v0.10.0 incorrectly moved top-level
#      Knowledge/ content on personal vaults and deleted the folder.
#      This script restores Knowledge/{Technical,Leadership,Industry,General}/
#      on personal vaults if missing.
#
#   2. Vault at any version before 0.10.0:
#      Applies all 0.10.0 changes with the correct Knowledge/ handling:
#      - Daily notes moved to domain folders (Life/Daily/ or Work/$COMPANY/Daily/)
#      - MOC queries updated to discover /Daily/ in any domain folder
#      - Work/$COMPANY/Knowledge/ created
#      - Top-level Knowledge/ moved to Work/$COMPANY/Knowledge/ on work vaults ONLY
#
# Detection is filesystem-based, not version-based (idempotent):
#   Personal vault:          Life/ directory exists
#   Work vault:              Life/ directory does not exist
#   Knowledge needs restore: personal vault + Knowledge/ missing
#   Daily notes migrated:    Life/Daily/ exists and Process/Daily/ is empty/absent
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

write_if_new() {
  local filepath="$1" content="$2"
  if [[ ! -f "$filepath" ]]; then
    printf '%s\n' "$content" > "$filepath" || die "write-file" "Could not write: $filepath"
    _pass "Created: ${filepath#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${filepath#$VAULT_ROOT/}"
  fi
}

copy_if_new() {
  local src="$1" dest="$2"
  if [[ ! -f "$src" ]]; then
    _warn "Source not found, skipping: $(basename "$src")"
    return
  fi
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest" || die "copy-file" "Could not copy to: $dest"
    _pass "Created: ${dest#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${dest#$VAULT_ROOT/}"
  fi
}

# Move all *.md files from $1 to $2, detecting conflicts.
# Prints a summary line. Sets _MOVED_COUNT and _CONFLICT_COUNT in caller scope.
_move_daily_notes() {
  local src_dir="$1" dest_dir="$2"
  _MOVED_COUNT=0
  _CONFLICT_COUNT=0
  _CONFLICT_FILES=()

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  local -a md_files=()
  while IFS= read -r -d '' f; do
    md_files+=("$f")
  done < <(find "$src_dir" -maxdepth 1 -name "*.md" -print0 2>/dev/null || true)

  if [[ ${#md_files[@]} -eq 0 ]]; then
    return 0
  fi

  mkdir -p "$dest_dir"

  for src_file in "${md_files[@]}"; do
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

# Move all files from $1/$3 to $2/$3, detecting conflicts.
# $3 is a subfolder name (e.g. Technical, Leadership, Industry).
_move_knowledge_subdir() {
  local src_parent="$1" dest_parent="$2" subdir="$3"
  local src_dir="${src_parent}/${subdir}"
  local dest_dir="${dest_parent}/${subdir}"
  local moved=0 conflicts=0

  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi

  local -a files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "$src_dir" -maxdepth 1 -type f -print0 2>/dev/null || true)

  if [[ ${#files[@]} -eq 0 ]]; then
    _detail "  Knowledge/${subdir}/ is empty — nothing to move"
    return 0
  fi

  mkdir -p "$dest_dir"

  for src_file in "${files[@]}"; do
    local fname
    fname="$(basename "$src_file")"
    local dest_file="${dest_dir}/${fname}"
    if [[ -f "$dest_file" ]]; then
      _warn "Conflict — skipping (already exists in target): Knowledge/${subdir}/${fname}"
      conflicts=$(( conflicts + 1 ))
    else
      mv "$src_file" "$dest_file" || die "move" "Could not move $src_file"
      moved=$(( moved + 1 ))
    fi
  done

  _KNOWLEDGE_MOVED=$(( _KNOWLEDGE_MOVED + moved ))
  _KNOWLEDGE_CONFLICTS=$(( _KNOWLEDGE_CONFLICTS + conflicts ))
  if [[ $moved -gt 0 ]]; then
    _pass "Moved ${moved} file(s): Knowledge/${subdir}/ → Work/${COMPANY}/Knowledge/${subdir}/"
  fi
}

# Remove a directory if it is empty (no files anywhere in the tree).
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

# Replace `path includes Process/Daily` → `path includes /Daily/` in a file.
# Silent no-op if the pattern is not found.
_update_moc_query() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if grep -q "path includes Process/Daily" "$file" 2>/dev/null; then
    sed -i.bak 's/path includes Process\/Daily/path includes \/Daily\//g' "$file" \
      && rm -f "${file}.bak"
    _pass "Updated query path: ${file#$VAULT_ROOT/}"
  fi
}

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v0.10.1 global migrations..."
  echo ""

  # --- MOC query path updates (both personal and work vaults) ---
  echo "  Updating MOC query paths..."
  _update_moc_query "${VAULT_ROOT}/Process/Action Items.md"
  _update_moc_query "${VAULT_ROOT}/Process/Open Loops.md"
  _update_moc_query "${VAULT_ROOT}/Process/Review Queue.md"
  _update_moc_query "${VAULT_ROOT}/Process/Weekly Outtake.md"
  echo ""

  # --- Personal vault migrations ---
  if [[ -d "${VAULT_ROOT}/Life" ]]; then
    echo "  Personal vault detected — migrating daily notes..."

    mkdir -p "${VAULT_ROOT}/Life/Daily"
    _pass "Ensured: Life/Daily/"

    _MOVED_COUNT=0
    _CONFLICT_COUNT=0
    _CONFLICT_FILES=()
    _move_daily_notes "${VAULT_ROOT}/Process/Daily" "${VAULT_ROOT}/Life/Daily"

    if [[ $_MOVED_COUNT -gt 0 ]]; then
      _pass "Moved ${_MOVED_COUNT} daily note(s): Process/Daily/ → Life/Daily/"
    fi
    if [[ $_CONFLICT_COUNT -gt 0 ]]; then
      _warn "${_CONFLICT_COUNT} conflict(s) skipped (files already exist in Life/Daily/):"
      for _cf in "${_CONFLICT_FILES[@]:-}"; do
        _hint "  ${_cf}"
      done
    fi

    _remove_if_empty "${VAULT_ROOT}/Process/Daily"
    echo ""

    # --- Restore (or create) top-level Knowledge/ on personal vault ---
    # This is the fix for vaults broken by v0.10.0's incorrect per-company
    # migration, which moved Knowledge/ content into Work/<Company>/Knowledge/.
    # mkdir -p is idempotent: safe to run on vaults that already have Knowledge/.
    echo "  Ensuring Knowledge/ folder structure..."
    _knowledge_was_missing=false
    if [[ ! -d "${VAULT_ROOT}/Knowledge" ]]; then
      _knowledge_was_missing=true
    fi

    mkdir -p "${VAULT_ROOT}/Knowledge/Technical"
    mkdir -p "${VAULT_ROOT}/Knowledge/Leadership"
    mkdir -p "${VAULT_ROOT}/Knowledge/Industry"
    mkdir -p "${VAULT_ROOT}/Knowledge/General"
    _pass "Ensured: Knowledge/{Technical,Leadership,Industry,General}/"

    if [[ "$_knowledge_was_missing" == true ]]; then
      echo ""
      _warn "Knowledge/ was missing on this personal vault."
      _hint "  This was likely caused by the v0.10.0 migration, which incorrectly"
      _hint "  moved personal Knowledge/ content into Work/<Company>/Knowledge/."
      _hint "  Your files are not lost — check each Work/<Company>/Knowledge/ folder"
      _hint "  and manually move transferable notes back to Knowledge/ as needed."
    fi
    echo ""

    # Update daily-notes.json → Life/Daily
    cat > "${VAULT_ROOT}/.obsidian/daily-notes.json" <<DAILY
{
  "folder": "Life/Daily",
  "template": "_templates/Daily Note",
  "format": "YYYY-MM-DD",
  "autorun": false
}
DAILY
    _pass "Updated: .obsidian/daily-notes.json → Life/Daily"
    echo ""

  else
    # Work vault — daily-notes.json will be updated in per-company section
    _detail "Work vault detected — daily notes migration deferred to per-company step."
    echo ""
  fi

  _pass "v0.10.1 global migrations complete."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v0.10.1 company migrations: $COMPANY..."
  echo ""

  COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"

  if [[ ! -d "$COMPANY_DIR" ]]; then
    _warn "Company directory not found, skipping: Work/${COMPANY}"
    exit 0
  fi

  # --- Create new directories (idempotent) ---
  mkdir -p "${COMPANY_DIR}/Daily"
  _pass "Ensured: Work/${COMPANY}/Daily/"
  mkdir -p "${COMPANY_DIR}/Knowledge/Technical"
  mkdir -p "${COMPANY_DIR}/Knowledge/Leadership"
  mkdir -p "${COMPANY_DIR}/Knowledge/Industry"
  _pass "Ensured: Work/${COMPANY}/Knowledge/{Technical,Leadership,Industry}/"
  echo ""

  # --- Work vault only: move daily notes and Knowledge content ---
  # Personal vaults (detected by presence of Life/) keep their top-level
  # Knowledge/ at the vault root. Only work vaults migrate Knowledge/ here.
  if [[ ! -d "${VAULT_ROOT}/Life" ]]; then

    # Move daily notes: Process/Daily → Work/$COMPANY/Daily
    echo "  Moving daily notes..."
    _MOVED_COUNT=0
    _CONFLICT_COUNT=0
    _CONFLICT_FILES=()
    _move_daily_notes "${VAULT_ROOT}/Process/Daily" "${COMPANY_DIR}/Daily"

    if [[ $_MOVED_COUNT -gt 0 ]]; then
      _pass "Moved ${_MOVED_COUNT} daily note(s): Process/Daily/ → Work/${COMPANY}/Daily/"
    fi
    if [[ $_CONFLICT_COUNT -gt 0 ]]; then
      _warn "${_CONFLICT_COUNT} conflict(s) skipped (files already exist in target):"
      for _cf in "${_CONFLICT_FILES[@]:-}"; do
        _hint "  ${_cf}"
      done
    fi

    _remove_if_empty "${VAULT_ROOT}/Process/Daily"
    echo ""

    # Move top-level Knowledge → Work/$COMPANY/Knowledge/
    KNOWLEDGE_DIR="${VAULT_ROOT}/Knowledge"
    if [[ -d "$KNOWLEDGE_DIR" ]]; then
      echo "  Moving work knowledge..."
      _KNOWLEDGE_MOVED=0
      _KNOWLEDGE_CONFLICTS=0
      _move_knowledge_subdir "$KNOWLEDGE_DIR" "${COMPANY_DIR}/Knowledge" "Technical"
      _move_knowledge_subdir "$KNOWLEDGE_DIR" "${COMPANY_DIR}/Knowledge" "Leadership"
      _move_knowledge_subdir "$KNOWLEDGE_DIR" "${COMPANY_DIR}/Knowledge" "Industry"
      echo ""

      # Knowledge/General/ — warn if non-empty, never delete
      if [[ -d "${KNOWLEDGE_DIR}/General" ]]; then
        local_files="$(find "${KNOWLEDGE_DIR}/General" -type f 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "$local_files" -gt 0 ]]; then
          _warn "Knowledge/General/ contains ${local_files} file(s) — not moved."
          _hint "  Review these files manually: promote to personal Knowledge/ or discard."
          _hint "  Knowledge/General/ is not created in work vaults under v0.10.1."
          echo ""
        fi
      fi

      _remove_if_empty "$KNOWLEDGE_DIR"
      echo ""
    fi

    # Update daily-notes.json → Work/$COMPANY/Daily
    cat > "${VAULT_ROOT}/.obsidian/daily-notes.json" <<DAILY
{
  "folder": "Work/${COMPANY}/Daily",
  "template": "_templates/Daily Note",
  "format": "YYYY-MM-DD",
  "autorun": false
}
DAILY
    _pass "Updated: .obsidian/daily-notes.json → Work/${COMPANY}/Daily"
    echo ""

  else
    # Personal vault — Knowledge/ was handled in global section.
    # Work/<Company>/Knowledge/ directories were already created above.
    _detail "Personal vault — Knowledge/ managed at vault root; no content migration needed."
    echo ""
  fi

  _pass "v0.10.1 company migrations complete: $COMPANY"
fi
