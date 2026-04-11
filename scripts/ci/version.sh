#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
README="$REPO_DIR/README.md"
VERSION_FILE="$REPO_DIR/config/base/version.json"

# ── Preflight checks ──────────────────────────────────────────────────────────

cd "$REPO_DIR"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: $VERSION_FILE not found."
  exit 1
fi

# ── Determine current version ─────────────────────────────────────────────────

MAJOR="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['major'])")"
MINOR="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['minor'])")"
PATCH="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['patch'])")"
BUILD="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver'].get('build',''))")"

CURRENT="$MAJOR.$MINOR.$PATCH"
[[ -n "$BUILD" ]] && CURRENT_DISPLAY="$CURRENT+$BUILD" || CURRENT_DISPLAY="$CURRENT"

echo ""
echo "Current version: v$CURRENT_DISPLAY"
echo ""
echo "Select release type:"
echo "  1) Patch  (v$MAJOR.$MINOR.$((PATCH + 1)))"
echo "  2) Minor  (v$MAJOR.$((MINOR + 1)).0)"
echo "  3) Major  (v$((MAJOR + 1)).0.0)"
echo "  4) Specific version"
echo ""
read -rp "Choice [1-4]: " CHOICE

case "$CHOICE" in
  1) NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))" ;;
  2) NEW_VERSION="$MAJOR.$((MINOR + 1)).0" ;;
  3) NEW_VERSION="$((MAJOR + 1)).0.0" ;;
  4)
    read -rp "Enter version (without leading v, e.g. 1.2.3): " INPUT
    if ! echo "$INPUT" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "Error: '$INPUT' is not a valid semver (expected X.Y.Z)."
      exit 1
    fi
    if git tag --list | grep -q "^v$INPUT$"; then
      echo "Error: tag v$INPUT already exists."
      exit 1
    fi
    NEW_VERSION="$INPUT"
    ;;
  *) echo "Invalid choice."; exit 1 ;;
esac

IFS='.' read -r NEW_MAJOR NEW_MINOR NEW_PATCH <<< "$NEW_VERSION"

if [[ -n "$BUILD" ]]; then
  NEW_BUILD="$((BUILD + 1))"
  NEW_TAG="v$NEW_VERSION+$NEW_BUILD"
else
  NEW_BUILD=""
  NEW_TAG="v$NEW_VERSION"
fi

echo ""
echo "Bumping to: $NEW_TAG"
read -rp "Proceed? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Update version.json ───────────────────────────────────────────────────────

python3 - "$VERSION_FILE" "$NEW_MAJOR" "$NEW_MINOR" "$NEW_PATCH" "$NEW_BUILD" <<'PYEOF'
import json, sys
path, major, minor, patch, build = sys.argv[1:]
with open(path) as f:
    d = json.load(f)
d['semver']['major'] = int(major)
d['semver']['minor'] = int(minor)
d['semver']['patch'] = int(patch)
if build:
    d['semver']['build'] = int(build)
elif 'build' in d['semver']:
    del d['semver']['build']
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
PYEOF

echo "Updated $VERSION_FILE to $NEW_TAG."

# ── Update README ─────────────────────────────────────────────────────────────

sed -i '' \
  "s|git clone\( --branch v[0-9][^ ]*\)\?\( --depth 1\)\? https://github.com/\(.*\)\.git|git clone --branch $NEW_TAG --depth 1 https://github.com/\3.git|g" \
  "$README"

echo "Updated README.md clone command to $NEW_TAG."

# ── Next steps ────────────────────────────────────────────────────────────────

echo ""
echo "Version bumped. Before releasing:"
echo "  1. Create scripts/upgrade/migrations/v$NEW_VERSION.sh and scripts/upgrade/upgrade-to-$NEW_VERSION.sh"
echo "     (see docs/next-release.md for pending migration notes)"
echo "  2. Test: scaffold-vault.sh --upgrade against a test vault"
echo "  3. git add all changes, then run: scripts/ci/release.sh"
echo ""
