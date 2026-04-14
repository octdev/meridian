# SOURCED LIBRARY — do not execute directly.
#
# Semver comparison helpers and version.json reader for Meridian scripts.

# Reads X.Y.Z from the known Meridian version.json format.
semver_from_version_json() {
  local json_file="$1"
  local major minor patch
  major="$(grep '"major"' "$json_file" | grep -o '[0-9]*')"
  minor="$(grep '"minor"' "$json_file" | grep -o '[0-9]*')"
  patch="$(grep '"patch"' "$json_file" | grep -o '[0-9]*')"
  echo "${major}.${minor}.${patch}"
}

# Returns 0 (true) if $1 < $2
semver_lt() {
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
semver_lte() {
  [[ "$1" == "$2" ]] || semver_lt "$1" "$2"
}
