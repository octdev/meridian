# SOURCED LIBRARY — do not execute directly.

if [[ -t 1 ]]; then
  _C_GREEN='\033[0;32m'
  _C_RED='\033[0;31m'
  _C_AMBER='\033[0;33m'
  _C_CYAN='\033[0;96m'
  _C_RESET='\033[0m'
else
  _C_GREEN='' _C_RED='' _C_AMBER='' _C_CYAN='' _C_RESET=''
fi
