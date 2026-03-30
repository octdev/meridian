# SOURCED LIBRARY — do not execute directly.

[[ -n "${_C_GREEN+x}" ]] || source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

_pass()   { printf "  ${_C_GREEN}✓ %s${_C_RESET}\n" "$*"; }
_fail()   { printf "  ${_C_RED}✗ %s${_C_RESET}\n" "$*" >&2; }
_warn()   { printf "  ${_C_AMBER}⚠ %s${_C_RESET}\n" "$*"; }
_hint()   { echo "       $*"; }
_detail() { echo "       $*"; }
_cmd()    { printf "         ${_C_CYAN}%s${_C_RESET}\n" "$*" >&2; }
