# SOURCED LIBRARY — do not execute directly.

[[ -n "${_C_RED+x}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

die() {
  local step="$1" hint="$2"
  echo "" >&2
  printf "${_C_RED}[meridian] ✗ Step failed: %s${_C_RESET}\n" "$step" >&2
  echo "  $hint" >&2
  exit 1
}
