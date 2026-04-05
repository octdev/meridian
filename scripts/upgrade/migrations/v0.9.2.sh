#!/usr/bin/env bash
# migrations/v0.9.2.sh — vault changes for Meridian 0.9.2
#
# Called by upgrade-runner.sh. Do not run directly.
#
# Arguments:
#   $1  VAULT_ROOT — absolute path to the vault
#   $2  REPO_DIR   — absolute path to the repo root
#   $3  COMPANY    — (optional) company name under Work/; if set, apply
#                    per-company changes only; if absent, apply global changes only
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

# --- helpers ---
# Defined inline so this migration is fully self-contained.
# No migration script ever sources or modifies another.

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

write_if_new() {
  local filepath="$1" content="$2"
  if [[ ! -f "$filepath" ]]; then
    printf '%s\n' "$content" > "$filepath" || die "write-file" "Could not write: $filepath"
    _pass "Created: ${filepath#$VAULT_ROOT/}"
  else
    echo "  — Skipped (exists): ${filepath#$VAULT_ROOT/}"
  fi
}

# --- global changes (no $COMPANY) ---

if [[ -z "$COMPANY" ]]; then
  echo "[meridian] v0.9.2 global migrations..."

  # Add global vault changes for this version here.
  # Examples:
  #   copy_if_new "${REPO_DIR}/src/templates/obsidian-templates/new-template.md" \
  #               "${VAULT_ROOT}/_templates/New Template.md"
  #
  #   write_if_new "${VAULT_ROOT}/Process/new-moc.md" "$(cat <<'EOF'
  #   ---
  #   title: New MOC
  #   created:
  #   modified:
  #   ---
  #   # New MOC
  #   EOF
  #   )"

  _pass "v0.9.2 global migrations complete."

# --- per-company changes ($COMPANY is set) ---

else
  echo "[meridian] v0.9.2 company migrations: $COMPANY..."

  # Add per-company vault changes for this version here.
  # COMPANY_DIR is the path to this company's folder.
  # Examples:
  #   COMPANY_DIR="${VAULT_ROOT}/Work/${COMPANY}"
  #   mkdir -p "${COMPANY_DIR}/NewFolder"
  #   copy_if_new "${REPO_DIR}/src/templates/..." "${COMPANY_DIR}/..."

  _pass "v0.9.2 company migrations complete: $COMPANY"
fi
