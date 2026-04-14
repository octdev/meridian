# SOURCED LIBRARY — do not execute directly.
#
# Provides run_upgrade_to() for upgrade entry point scripts.
#
# Caller usage:
#   source "${SCRIPT_DIR}/upgrade-runner.sh"
#   run_upgrade_to "1.4.5" "${SCRIPT_DIR}/migrations" "$@"
#
# The entry point passes its own target version, the path to the migrations/
# directory, and the original "$@" for --vault parsing.
#
# Migration scripts in migrations/ must be named vX.Y.Z.sh and accept:
#   $1 = VAULT_ROOT
#   $2 = REPO_DIR
#   $3 = COMPANY  (optional — omit for global changes, provide for per-company changes)
#
# The runner calls each applicable migration twice per version:
#   once without $3 (global), then once per selected company with $3 set.
#
# .vault-version format (key=value):
#   vault=0.9.2
#   AcmeCorp-vault=0.9.2
#   OtherCorp-vault=0.9.1
#
# Backward compatible: plain version strings are migrated to key=value on first read.

# --- semver helpers ---

# Returns 0 (true) if $1 < $2
_semver_lt() {
  local a="$1" b="$2"
  local a_major a_minor a_patch b_major b_minor b_patch
  IFS='.' read -r a_major a_minor a_patch <<< "$a"
  IFS='.' read -r b_major b_minor b_patch <<< "$b"
  if   (( a_major < b_major )); then return 0
  elif (( a_major > b_major )); then return 1
  elif (( a_minor < b_minor )); then return 0
  elif (( a_minor > b_minor )); then return 1
  elif (( a_patch < b_patch )); then return 0
  else return 1
  fi
}

# Returns 0 (true) if $1 <= $2
_semver_lte() {
  [[ "$1" == "$2" ]] || _semver_lt "$1" "$2"
}

# Reads X.Y.Z from the known Meridian version.json format.
_semver_from_version_json() {
  local json_file="$1"
  local major minor patch
  major="$(grep '"major"' "$json_file" | grep -o '[0-9]*')"
  minor="$(grep '"minor"' "$json_file" | grep -o '[0-9]*')"
  patch="$(grep '"patch"' "$json_file" | grep -o '[0-9]*')"
  echo "${major}.${minor}.${patch}"
}

# Sorts vX.Y.Z.sh basenames by semver order, one per line on stdout.
_sort_migration_scripts() {
  printf '%s\n' "$@" \
    | sed 's/^v//; s/\.sh$//' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | sed 's/^/v/; s/$/.sh/'
}


# --- vault version file helpers ---

# Read a single key from .vault-version (key=value format). Prints value.
# Always exits 0 — callers check for empty output when a key is absent.
_read_version_key() {
  local file="$1" key="$2"
  grep "^${key}=" "$file" 2>/dev/null | cut -d= -f2 || true
}

# Write or update a single key in .vault-version.
_write_version_key() {
  local file="$1" key="$2" value="$3"
  if grep -q "^${key}=" "$file" 2>/dev/null; then
    sed -i.bak "s|^${key}=.*|${key}=${value}|" "$file" && rm -f "${file}.bak"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

# Migrate a plain-text .vault-version ("0.9.1") to key=value format.
# Sets vault= and one entry per detected company, all at the old version.
# No-op if already in key=value format.
_migrate_version_file() {
  local file="$1" vault_root="$2"
  grep -q "^vault=" "$file" 2>/dev/null && return 0

  local old_version
  old_version="$(cat "$file")"
  _warn "Migrating .vault-version to key=value format..."

  echo "vault=${old_version}" > "$file"
  detect_companies "$vault_root"
  for _c in "${DETECTED_COMPANIES[@]:-}"; do
    [[ -n "$_c" ]] && echo "${_c}-vault=${old_version}" >> "$file"
  done
  _pass "Migrated .vault-version."
  echo ""
}

# --- company selection ---

# Detects eligible companies, prompts for selection, and sets:
#   _SELECTED_COMPANIES — array of companies to upgrade
#   _SKIPPED_COMPANIES  — array of eligible companies the user chose to skip
#
# Eligible = company version in .vault-version matches pre_upgrade_version.
# Ineligible companies (already behind) are reported but not offered for selection.
_select_companies() {
  local vault_root="$1" version_file="$2" pre_upgrade_version="$3" target_version="$4"

  _SELECTED_COMPANIES=()
  _SKIPPED_COMPANIES=()

  detect_companies "$vault_root"
  local -a all_companies=("${DETECTED_COMPANIES[@]:-}")

  if [[ ${#all_companies[@]} -eq 0 ]]; then
    return 0
  fi

  # Partition into eligible and ineligible
  local -a eligible=() ineligible=()
  for _c in "${all_companies[@]}"; do
    local _cv
    _cv="$(_read_version_key "$version_file" "${_c}-vault")"
    if [[ "$_cv" == "$pre_upgrade_version" ]]; then
      eligible+=("$_c")
    else
      ineligible+=("$_c")
    fi
  done

  # Report ineligible companies
  if [[ ${#ineligible[@]} -gt 0 ]]; then
    _warn "The following companies are behind and cannot be upgraded:"
    for _c in "${ineligible[@]}"; do
      local _cv
      _cv="$(_read_version_key "$version_file" "${_c}-vault")"
      _hint "  ${_c}  (at ${_cv:-unknown}, vault is at ${pre_upgrade_version})"
    done
    echo ""
  fi

  if [[ ${#eligible[@]} -eq 0 ]]; then
    return 0
  fi

  # Single eligible company — simple yes/no
  if [[ ${#eligible[@]} -eq 1 ]]; then
    echo "  Company eligible for upgrade (${pre_upgrade_version} → ${target_version}):"
    _hint "    1. ${eligible[0]}"
    echo ""
    read -rp "  Upgrade this company? [Y/n]: " _ans
    echo ""
    if [[ -z "$_ans" || "$_ans" =~ ^[Yy] ]]; then
      _SELECTED_COMPANIES=("${eligible[0]}")
    else
      _SKIPPED_COMPANIES=("${eligible[0]}")
    fi
    return 0
  fi

  # Multiple eligible companies — numbered multi-select
  echo "  Companies eligible for upgrade (${pre_upgrade_version} → ${target_version}):"
  for _i in "${!eligible[@]}"; do
    _hint "    $((_i+1)). ${eligible[$_i]}"
  done
  echo ""
  read -rp "  Select companies to upgrade [all]: " _selection
  echo ""

  _selection="${_selection:-all}"

  if [[ "$_selection" == "all" ]]; then
    _SELECTED_COMPANIES=("${eligible[@]}")
    return 0
  fi

  if [[ "$_selection" == "none" ]]; then
    _SKIPPED_COMPANIES=("${eligible[@]}")
    return 0
  fi

  # Parse comma-separated numbers
  local -a _selected_indices=()
  IFS=',' read -ra _nums <<< "$_selection"
  for _num in "${_nums[@]}"; do
    _num="${_num// /}"
    if [[ "$_num" =~ ^[0-9]+$ ]] && (( _num >= 1 && _num <= ${#eligible[@]} )); then
      _selected_indices+=("$(( _num - 1 ))")
    fi
  done

  for _i in "${!eligible[@]}"; do
    local _found=false
    for _si in "${_selected_indices[@]:-}"; do
      [[ "$_i" == "$_si" ]] && _found=true && break
    done
    if [[ "$_found" == true ]]; then
      _SELECTED_COMPANIES+=("${eligible[$_i]}")
    else
      _SKIPPED_COMPANIES+=("${eligible[$_i]}")
    fi
  done
}

# --- main entry point ---

run_upgrade_to() {
  local target_version="$1"
  local migrations_dir="$2"
  shift 2

  local _runner_dir
  _runner_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local _repo_dir
  _repo_dir="$(cd "${_runner_dir}/../.." && pwd)"

  source "${_repo_dir}/src/lib/colors.sh"
  source "${_repo_dir}/src/lib/logging.sh"
  source "${_repo_dir}/src/lib/errors.sh"
  source "${_repo_dir}/src/lib/vault-select.sh"
  source "${_repo_dir}/src/lib/refresh-vault-docs.sh"
  source "${_repo_dir}/src/lib/shell-exports.sh"

  # --- parse --vault ---
  local vault_root=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --vault)
        [[ -n "${2:-}" ]] || die "upgrade" "--vault requires a path."
        vault_root="$2"; shift 2 ;;
      -h|--help)
        echo "Usage: $(basename "$0") --vault <path>"; exit 0 ;;
      *)
        die "upgrade" "Unknown argument: $1" ;;
    esac
  done

  # --- resolve vault ---
  if [[ -z "$vault_root" ]]; then
    select_vault
    vault_root="$VAULT_ROOT"
  fi
  [[ -d "$vault_root" ]] || die "upgrade" "Vault not found: $vault_root"

  # --- read and migrate version file ---
  local version_file="${vault_root}/.scripts/.vault-version"

  if [[ ! -f "$version_file" ]]; then
    echo ""
    _warn "No .vault-version found at .scripts/.vault-version"
    _hint "This vault was scaffolded before version tracking was introduced."
    echo ""
    read -rp "  Enter the version this vault was installed from (e.g. 0.9.1): " _entered
    echo ""
    [[ -n "$_entered" ]] || die "upgrade" "Installed version cannot be empty."
    echo "vault=${_entered}" > "$version_file"
    detect_companies "$vault_root"
    for _c in "${DETECTED_COMPANIES[@]:-}"; do
      [[ -n "$_c" ]] && echo "${_c}-vault=${_entered}" >> "$version_file"
    done
  else
    _migrate_version_file "$version_file" "$vault_root"
  fi

  local installed_version
  installed_version="$(_read_version_key "$version_file" "vault")"
  [[ -n "$installed_version" ]] || die "upgrade" "Could not read vault version from .vault-version"

  echo ""
  echo "[meridian] Upgrade Vault"
  echo ""
  _detail "Vault:             $vault_root"
  _detail "Installed version: $installed_version"
  _detail "Target version:    $target_version"
  echo ""

  # --- guard: already current ---
  if [[ "$installed_version" == "$target_version" ]]; then
    _pass "Vault is already at version $target_version. Nothing to do."
    echo ""
    exit 0
  fi

  # --- guard: installed newer than target ---
  if ! _semver_lt "$installed_version" "$target_version"; then
    die "upgrade" "Installed version ($installed_version) is newer than target ($target_version)."
  fi

  # --- discover migration scripts ---
  local -a all_scripts=()
  if [[ -d "$migrations_dir" ]]; then
    for f in "$migrations_dir"/v*.sh; do
      [[ -f "$f" ]] && all_scripts+=("$(basename "$f")")
    done
  fi

  # --- sort and filter to applicable range ---
  local -a applicable=()
  if [[ ${#all_scripts[@]} -gt 0 ]]; then
    while IFS= read -r script; do
      local script_version="${script#v}"
      script_version="${script_version%.sh}"
      if _semver_lt "$installed_version" "$script_version" && \
         _semver_lte "$script_version" "$target_version"; then
        applicable+=("$script")
      fi
    done < <(_sort_migration_scripts "${all_scripts[@]}")
  fi

  # --- company selection ---
  # Capture pre-upgrade version for eligibility check before any migrations run.
  local pre_upgrade_version="$installed_version"
  _select_companies "$vault_root" "$version_file" "$pre_upgrade_version" "$target_version"

  # Warn and confirm if any eligible companies were skipped
  if [[ ${#_SKIPPED_COMPANIES[@]} -gt 0 ]]; then
    _warn "The following companies will NOT be upgraded:"
    for _c in "${_SKIPPED_COMPANIES[@]}"; do
      _hint "  ${_c}"
    done
    _hint ""
    _hint "Skipped companies will be ineligible for all future upgrades."
    _hint "See Process/Meridian Documentation/User Handbook.md for details."
    echo ""
    read -rp "  Proceed anyway? [y/N]: " _confirm
    echo ""
    [[ "$_confirm" =~ ^[Yy] ]] || { echo "  Upgrade cancelled."; echo ""; exit 0; }
  fi

  # --- run global migrations ---
  if [[ ${#applicable[@]} -gt 0 ]]; then
    echo "[meridian] Applying ${#applicable[@]} global migration(s)..."
    echo ""
    for script in "${applicable[@]}"; do
      local script_version="${script#v}"
      script_version="${script_version%.sh}"
      _detail "→ $script (global)"
      bash "${migrations_dir}/${script}" "$vault_root" "$_repo_dir" \
        || die "upgrade" "Migration failed: $script — vault remains at $installed_version"
      _write_version_key "$version_file" "vault" "$script_version"
      installed_version="$script_version"
      echo ""
    done
  fi

  # --- run per-company migrations ---
  if [[ ${#_SELECTED_COMPANIES[@]} -gt 0 && ${#applicable[@]} -gt 0 ]]; then
    for company in "${_SELECTED_COMPANIES[@]}"; do
      local company_version
      company_version="$(_read_version_key "$version_file" "${company}-vault")"
      echo "[meridian] Applying migrations for: $company..."
      echo ""
      for script in "${applicable[@]}"; do
        local script_version="${script#v}"
        script_version="${script_version%.sh}"
        _detail "→ $script ($company)"
        bash "${migrations_dir}/${script}" "$vault_root" "$_repo_dir" "$company" \
          || die "upgrade" "Migration failed: $script for $company — $company remains at $company_version"
        _write_version_key "$version_file" "${company}-vault" "$script_version"
        company_version="$script_version"
        echo ""
      done
    done
  fi

  # --- bump vault version to target (always, even if no migrations ran) ---
  _write_version_key "$version_file" "vault" "$target_version"
  for company in "${_SELECTED_COMPANIES[@]:-}"; do
    [[ -n "$company" ]] && _write_version_key "$version_file" "${company}-vault" "$target_version"
  done

  # --- refresh docs (always, after all migrations) ---
  # Attempt to fetch the latest documentation from origin/main before refreshing
  # the vault. Falls back to the bundled local docs if GitHub is unreachable or
  # any file fetch fails. No git objects are fetched.

  _RAW_BASE="https://raw.githubusercontent.com/octdev/meridian/main/src/documentation"
  _API_REF="https://api.github.com/repos/octdev/meridian/git/refs/heads/main"
  _UPGRADE_DOC_FILES=(
    "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md"
    "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md" "Upgrading.md"
  )
  _doc_source="local"
  _effective_repo_dir="$_repo_dir"
  _fetch_dir=""

  _api_response=""
  if _api_response=$(curl -sf "$_API_REF" 2>/dev/null); then
    _commit=$(echo "$_api_response" \
      | python3 -c "import sys,json; r=json.load(sys.stdin); print(r['object']['sha'][:7])" \
      2>/dev/null || echo "unknown")
    # Fetch into a temp directory so the local repo is never modified.
    _fetch_dir="$(mktemp -d)"
    mkdir -p "${_fetch_dir}/src/documentation"
    _effective_repo_dir="$_fetch_dir"
    trap 'rm -rf "$_fetch_dir"' EXIT
    _tmp=$(mktemp)
    _fetch_errors=0
    for _f in "${_UPGRADE_DOC_FILES[@]}"; do
      _encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$_f")
      if curl -sf "${_RAW_BASE}/${_encoded}" > "$_tmp"; then
        mv "$_tmp" "${_fetch_dir}/src/documentation/${_f}"
      else
        # Fall back to local copy for this file
        if [[ -f "${_repo_dir}/src/documentation/${_f}" ]]; then
          cp "${_repo_dir}/src/documentation/${_f}" "${_fetch_dir}/src/documentation/${_f}"
        fi
        _fetch_errors=$(( _fetch_errors + 1 ))
      fi
    done
    rm -f "$_tmp"
    if [[ "$_fetch_errors" -eq 0 ]]; then
      _doc_source="origin/main @ ${_commit}"
    else
      _doc_source="local (remote fetch incomplete)"
    fi
  fi

  refresh_vault_docs "$vault_root" "$_effective_repo_dir"
  _detail "Documentation: ${_doc_source}"
  echo ""

  printf "${_C_GREEN}[meridian] Vault upgraded to %s successfully.${_C_RESET}\n" "$target_version"
  echo ""
  _offer_shell_exports "$_repo_dir" "$vault_root"
}
