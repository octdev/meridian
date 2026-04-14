#!/usr/bin/env bash
# migrations/v1.5.0.sh — vault changes for Meridian 1.5.0
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
#
# Changes in this release:
#   Global: References/ moved to Knowledge/References/
#   Global: new-standalone-meeting.sh deployed to .scripts/
#   Global: new-meeting-series.sh, new-1on1.sh refreshed in .scripts/
#   Per-company: Meetings restructured — Series/, Single/ created;
#                existing series folders moved into Meetings/Series/
#
# Wikilink assumption: Meridian uses shortest-path wikilinks. Series folder
# moves do not break backlinks as long as filenames are unchanged. If a user
# has non-standard full-path wikilinks, those will need manual repair.
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

# ============================================================
# Global changes (no $COMPANY)
# ============================================================

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v1.5.0 global migrations..."
  echo ""

  SCRIPTS_DIR="${VAULT_ROOT}/.scripts"

  if [[ ! -d "$SCRIPTS_DIR" ]]; then
    die "v1.5.0" ".scripts/ directory not found in vault: $VAULT_ROOT"
  fi

  # 1. Move References/ → Knowledge/References/
  SRC_REFS="${VAULT_ROOT}/References"
  DEST_REFS="${VAULT_ROOT}/Knowledge/References"

  if [[ ! -d "$SRC_REFS" ]]; then
    _warn "References/ not found — skipping (may already be migrated)"
  elif [[ -d "$DEST_REFS" ]]; then
    _warn "Knowledge/References/ already exists — skipping move"
  else
    mv "$SRC_REFS" "$DEST_REFS" || die "v1.5.0" "Could not move References/ to Knowledge/References/"
    [[ -d "$DEST_REFS" ]] || die "v1.5.0" "Move completed but destination not found: $DEST_REFS"
    _pass "Moved: References/ → Knowledge/References/"
  fi

  # 2. Deploy new-standalone-meeting.sh to .scripts/
  SRC_STANDALONE="${REPO_DIR}/src/bin/new-standalone-meeting.sh"
  DEST_STANDALONE="${SCRIPTS_DIR}/new-standalone-meeting.sh"

  if [[ ! -f "$SRC_STANDALONE" ]]; then
    die "v1.5.0" "Source not found: src/bin/new-standalone-meeting.sh"
  fi
  cp "$SRC_STANDALONE" "$DEST_STANDALONE" || die "v1.5.0" "Could not copy new-standalone-meeting.sh"
  chmod +x "$DEST_STANDALONE" 2>/dev/null || true
  _pass "Deployed: .scripts/new-standalone-meeting.sh"

  # 3. Deploy vault-select.sh to .scripts/lib/ (was missing from earlier scaffolds)
  SRC_VS="${REPO_DIR}/src/lib/vault-select.sh"
  DEST_VS="${SCRIPTS_DIR}/lib/vault-select.sh"
  if [[ ! -f "$SRC_VS" ]]; then
    _warn "Source not found, skipping: src/lib/vault-select.sh"
  else
    mkdir -p "${SCRIPTS_DIR}/lib"
    cp "$SRC_VS" "$DEST_VS" || die "v1.5.0" "Could not copy vault-select.sh"
    _pass "Deployed: .scripts/lib/vault-select.sh"
  fi

  # 4. Refresh updated scripts in .scripts/
  for script in new-meeting-series.sh new-1on1.sh; do
    SRC="${REPO_DIR}/src/bin/${script}"
    DEST="${SCRIPTS_DIR}/${script}"
    if [[ ! -f "$SRC" ]]; then
      _warn "Source not found, skipping: src/bin/${script}"
      continue
    fi
    cp "$SRC" "$DEST" || die "v1.5.0" "Could not update ${script}"
    chmod +x "$DEST" 2>/dev/null || true
    _pass "Updated:  .scripts/${script}"
  done

  echo ""
  _pass "v1.5.0 global migrations complete."
  _hint "Note: if you have full-path wikilinks pointing to series folders,"
  _hint "those may need manual repair after the per-company migration."

# ============================================================
# Per-company changes ($COMPANY is set)
# ============================================================

else
  echo "[meridian] v1.5.0 company migrations: $COMPANY..."
  echo ""

  MEETINGS_DIR="${VAULT_ROOT}/Work/${COMPANY}/Meetings"

  # 1. Create Meetings subfolders if absent
  mkdir -p "${MEETINGS_DIR}/Series"
  _pass "Verified: Meetings/Series/"
  mkdir -p "${MEETINGS_DIR}/Single"
  _pass "Verified: Meetings/Single/"

  # Verify 1on1s/ exists (should be present from scaffold)
  if [[ ! -d "${MEETINGS_DIR}/1on1s" ]]; then
    _warn "Meetings/1on1s/ not found — expected from scaffold"
  else
    _pass "Verified: Meetings/1on1s/"
  fi

  # 2. Move existing series folders into Series/
  moved=0
  for dir in "${MEETINGS_DIR}"/*/; do
    [[ -d "$dir" ]] || continue
    SERIES="$(basename "$dir")"
    # Skip the new structure folders — do not move them
    case "$SERIES" in
      "1on1s"|"Series"|"Single") continue ;;
    esac
    # Everything else is a legacy series folder
    DEST="${MEETINGS_DIR}/Series/${SERIES}"
    if [[ -d "$DEST" ]]; then
      _warn "Already exists, skipping: Meetings/Series/${SERIES}"
    else
      mv "$dir" "$DEST" || die "v1.5.0" "Could not move series: ${SERIES}"
      _pass "Moved series: ${SERIES} → Meetings/Series/${SERIES}"
      moved=$(( moved + 1 ))
    fi
  done

  if [[ "$moved" -eq 0 ]]; then
    _detail "No legacy series folders found to move."
  fi

  echo ""
  _pass "v1.5.0 company migrations complete: $COMPANY"
fi
