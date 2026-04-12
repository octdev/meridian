# SOURCED LIBRARY — do not execute directly.
#
# Provides _offer_shell_exports() for prompting the user to add MERIDIAN_PROJECT
# and MERIDIAN_VAULT to their shell profile after scaffold or upgrade.

_offer_shell_exports() {
  local project_path="$1"
  local vault_path="$2"

  local rc_file
  case "$SHELL" in
    */zsh)  rc_file="$HOME/.zshrc" ;;
    */bash) rc_file="$HOME/.bash_profile" ;;
    *)
      _hint "Shell not recognized — add these to your shell profile manually:"
      echo "  export MERIDIAN_PROJECT=\"$project_path\""
      echo "  export MERIDIAN_VAULT=\"$vault_path\""
      echo ""
      return
      ;;
  esac

  local has_project=false has_vault=false
  grep -q 'MERIDIAN_PROJECT' "$rc_file" 2>/dev/null && has_project=true
  grep -q 'MERIDIAN_VAULT'   "$rc_file" 2>/dev/null && has_vault=true

  if [[ "$has_project" == true && "$has_vault" == true ]]; then
    _warn "MERIDIAN_PROJECT and MERIDIAN_VAULT already in $rc_file — skipping."
    echo ""
    return
  fi

  echo "Shell variables:"
  [[ "$has_project" == false ]] && echo "  export MERIDIAN_PROJECT=\"$project_path\""
  [[ "$has_vault"   == false ]] && echo "  export MERIDIAN_VAULT=\"$vault_path\""
  echo ""
  read -rp "  Add to $rc_file? [Y/n]: " _answer
  echo ""

  case "${_answer:-Y}" in
    [Nn]*)
      _hint "Skipped. Add the lines above to your shell profile manually."
      echo ""
      return
      ;;
  esac

  {
    echo ""
    echo "# Meridian"
    [[ "$has_project" == false ]] && echo "export MERIDIAN_PROJECT=\"$project_path\""
    [[ "$has_vault"   == false ]] && echo "export MERIDIAN_VAULT=\"$vault_path\""
  } >> "$rc_file" || { _warn "Could not write to $rc_file"; return; }

  _pass "Added to $rc_file"
  _hint "Run: source $rc_file  (or open a new terminal)"
  echo ""
}
