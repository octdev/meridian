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
  local vaults_file="$REPO_DIR/config/vaults.txt"
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
  local vaults_file="$REPO_DIR/config/vaults.txt"
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

# Interactively resolves a vault path and sets VAULT_ROOT.
# If known vaults exist, presents a numbered list with the first as default.
# If no known vaults exist, prompts for a path.
# Caller is responsible for validating that VAULT_ROOT exists afterward.
select_vault() {
  load_known_vaults
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
