# SOURCED LIBRARY — do not execute directly.
#
# Vault registry and interactive selection helpers.
#
# Requires:
#   REPO_DIR   — absolute path to the repo root (set by the calling script)
#   logging.sh — sourced before this library (provides _hint, _warn, _detail)
#   colors.sh  — sourced before this library (provides _C_CYAN, _C_RESET)

# Writes vault_path to the top of config/vaults.txt, deduplicating in place.
register_vault() {
  local vault_path="$1"
  local vaults_file="${MERIDIAN_CONFIG_DIR:-$REPO_DIR/config}/vaults.txt"
  local lines=()

  if [[ -f "$vaults_file" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" && "$line" != "$vault_path" ]] && lines+=("$line")
    done < "$vaults_file"
  fi

  mkdir -p "$(dirname "$vaults_file")"
  {
    echo "$vault_path"
    if [[ ${#lines[@]} -gt 0 ]]; then
      printf '%s\n' "${lines[@]}"
    fi
  } > "$vaults_file"
}

# Populates KNOWN_VAULTS array with valid vault paths from config/vaults.txt.
# Silently removes stale entries (directories that no longer exist).
load_known_vaults() {
  KNOWN_VAULTS=()
  local vaults_file="${MERIDIAN_CONFIG_DIR:-$REPO_DIR/config}/vaults.txt"
  if [[ ! -f "$vaults_file" ]]; then
    return 0
  fi

  local valid=() stale=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ -d "$line" ]]; then
      valid+=("$line")
    else
      stale+=("$line")
    fi
  done < "$vaults_file"

  if [[ ${#stale[@]} -gt 0 ]]; then
    if [[ ${#valid[@]} -gt 0 ]]; then
      printf '%s\n' "${valid[@]}" > "$vaults_file"
    else
      > "$vaults_file"
    fi
    local _n=${#stale[@]}
    _warn "Removed $_n stale vault $([ "$_n" -eq 1 ] && echo entry || echo entries) ($([ "$_n" -eq 1 ] && echo directory || echo directories) no longer exist)."
    echo ""
  fi

  if [[ ${#valid[@]} -gt 0 ]]; then
    KNOWN_VAULTS=("${valid[@]}")
  fi
  return 0
}

# Detects company names under $vault_root/Work/ and populates DETECTED_COMPANIES.
# Usage: detect_companies <vault_root>
detect_companies() {
  local vault_root="$1"
  DETECTED_COMPANIES=()
  if [[ -d "${vault_root}/Work" ]]; then
    for _d in "${vault_root}/Work"/*/; do
      [[ -d "$_d" ]] && DETECTED_COMPANIES+=("$(basename "$_d")")
    done
  fi
}

# Reads the active company from .obsidian/daily-notes.json and sets CURRENT_COMPANY.
# The folder field is expected to be "Work/<Company>/Daily".
# Leaves CURRENT_COMPANY empty if the file is absent or unparseable.
# Usage: detect_current_company <vault_root>
detect_current_company() {
  local vault_root="$1"
  CURRENT_COMPANY=""
  local config="${vault_root}/.obsidian/daily-notes.json"
  if [[ -f "$config" ]]; then
    local folder
    folder=$(grep '"folder"' "$config" \
      | sed 's/.*"folder"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [[ "$folder" =~ ^Work/(.+)/Daily$ ]]; then
      CURRENT_COMPANY="${BASH_REMATCH[1]}"
    fi
  fi
}

# Reads DefaultCompany= from .vault-version and sets DEFAULT_COMPANY.
# Leaves DEFAULT_COMPANY empty if the file is absent or the key is missing.
# Usage: get_default_company <vault_root>
get_default_company() {
  local vault_root="$1"
  DEFAULT_COMPANY=""
  local vf="${vault_root}/.scripts/.vault-version"
  [[ -f "$vf" ]] || return 0
  local val
  val="$(grep "^DefaultCompany=" "$vf" 2>/dev/null | cut -d= -f2)" || true
  DEFAULT_COMPANY="${val:-}"
}

# Writes or updates the DefaultCompany= key in .vault-version.
# Inserts the key after the vault= line if it does not yet exist.
# Silently warns and returns 0 if .vault-version is absent.
# Usage: set_default_company <vault_root> <company>
set_default_company() {
  local vault_root="$1"
  local company="$2"
  local vf="${vault_root}/.scripts/.vault-version"

  if [[ ! -f "$vf" ]]; then
    _warn "No .vault-version found; DefaultCompany not set."
    return 0
  fi

  if grep -q "^DefaultCompany=" "$vf" 2>/dev/null; then
    sed -i.bak "s|^DefaultCompany=.*|DefaultCompany=${company}|" "$vf"
    rm -f "${vf}.bak"
  else
    local tmp
    tmp="$(mktemp)"
    local inserted=0
    while IFS= read -r line; do
      printf '%s\n' "$line" >> "$tmp"
      if [[ "$line" =~ ^vault= && "$inserted" -eq 0 ]]; then
        printf 'DefaultCompany=%s\n' "$company" >> "$tmp"
        inserted=1
      fi
    done < "$vf"
    if [[ "$inserted" -eq 0 ]]; then
      printf 'DefaultCompany=%s\n' "$company" >> "$tmp"
    fi
    mv "$tmp" "$vf"
  fi
}

# Resolves the active company name and sets CURRENT_COMPANY.
# 1. Reads .obsidian/daily-notes.json for the current company.
# 2. If the result is missing or still "CurrentCompany", checks DefaultCompany in .vault-version.
# 3. If still unresolved, lists Work/ directories and prompts the user to select or enter one.
# Caller should validate that the chosen company directory exists afterward.
# Usage: resolve_company <vault_root>
resolve_company() {
  local vault_root="$1"
  detect_current_company "$vault_root"

  if [[ -n "$CURRENT_COMPANY" && "$CURRENT_COMPANY" != "CurrentCompany" ]]; then
    return 0
  fi

  # Try DefaultCompany from .vault-version
  get_default_company "$vault_root"
  if [[ -n "$DEFAULT_COMPANY" && "$DEFAULT_COMPANY" != "CurrentCompany" ]]; then
    CURRENT_COMPANY="$DEFAULT_COMPANY"
    return 0
  fi

  # Fall back to listing Work/ directories
  detect_companies "$vault_root"
  if [[ "${MERIDIAN_YES:-}" == "1" ]]; then
    # Headless mode: auto-select the first detected company, or leave empty for caller to die.
    [[ ${#DETECTED_COMPANIES[@]} -gt 0 ]] && CURRENT_COMPANY="${DETECTED_COMPANIES[0]}"
    return 0
  fi
  if [[ ${#DETECTED_COMPANIES[@]} -gt 0 ]]; then
    echo "  Known companies:"
    for _i in "${!DETECTED_COMPANIES[@]}"; do
      _hint "    $((_i+1)). ${DETECTED_COMPANIES[$_i]}"
    done
    echo ""
    read -rp "  Select company [1] or enter name: " _co_input
    echo ""
    if [[ -z "$_co_input" || "$_co_input" == "1" ]]; then
      CURRENT_COMPANY="${DETECTED_COMPANIES[0]}"
    elif [[ "$_co_input" =~ ^[0-9]+$ ]] && \
         [[ "$_co_input" -ge 1 && "$_co_input" -le ${#DETECTED_COMPANIES[@]} ]]; then
      CURRENT_COMPANY="${DETECTED_COMPANIES[$((_co_input-1))]}"
    else
      CURRENT_COMPANY="$_co_input"
    fi
  else
    read -rp "  Company name: " _co_input
    echo ""
    CURRENT_COMPANY="$_co_input"
  fi
}

# Interactively resolves a vault path and sets VAULT_ROOT.
# If known vaults exist, presents a numbered list with the first as default.
# If no known vaults exist, prompts for a path.
# Caller is responsible for validating that VAULT_ROOT exists afterward.
select_vault() {
  load_known_vaults
  if [[ "${MERIDIAN_YES:-}" == "1" ]]; then
    # Headless mode: auto-select the first known vault, or leave empty for caller to die.
    [[ ${#KNOWN_VAULTS[@]} -gt 0 ]] && VAULT_ROOT="${KNOWN_VAULTS[0]}"
    return 0
  fi
  if [[ ${#KNOWN_VAULTS[@]} -gt 0 ]]; then
    echo "  Known vaults:"
    for _i in "${!KNOWN_VAULTS[@]}"; do
      if [[ $_i -eq 0 ]]; then
        _hint "    $((_i+1)). ${KNOWN_VAULTS[$_i]}  (default)"
      else
        _hint "    $((_i+1)). ${KNOWN_VAULTS[$_i]}"
      fi
    done
    echo ""
    read -rp "  Select vault [1] or enter path: " _vault_input
    echo ""
    if [[ -z "$_vault_input" || "$_vault_input" == "1" ]]; then
      VAULT_ROOT="${KNOWN_VAULTS[0]}"
    elif [[ "$_vault_input" =~ ^[0-9]+$ ]] && \
         [[ "$_vault_input" -ge 1 && "$_vault_input" -le ${#KNOWN_VAULTS[@]} ]]; then
      VAULT_ROOT="${KNOWN_VAULTS[$((_vault_input-1))]}"
    else
      VAULT_ROOT="${_vault_input/#\~/$HOME}"
    fi
  else
    read -rp "  Vault path: " _vault_input
    echo ""
    [[ -n "$_vault_input" ]] && VAULT_ROOT="${_vault_input/#\~/$HOME}"
  fi
}
