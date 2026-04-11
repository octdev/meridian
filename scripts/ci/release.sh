#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$REPO_DIR/config/base/version.json"

# ── Preflight checks ──────────────────────────────────────────────────────────

cd "$REPO_DIR"

STAGED="$(git diff --cached --name-only)"

if [[ -z "$STAGED" ]]; then
  echo "Error: no staged changes. Stage your changes with git add before releasing."
  exit 1
fi

if ! echo "$STAGED" | grep -q "^config/base/version.json$"; then
  echo "Error: config/base/version.json is not staged. Run scripts/ci/version.sh first."
  exit 1
fi

if ! echo "$STAGED" | grep -q "^README.md$"; then
  echo "Error: README.md is not staged. Run scripts/ci/version.sh first."
  exit 1
fi

# ── Read target version from version.json ────────────────────────────────────

MAJOR="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['major'])")"
MINOR="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['minor'])")"
PATCH="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver']['patch'])")"
BUILD="$(python3 -c "import json,sys; d=json.load(open('$VERSION_FILE')); print(d['semver'].get('build',''))")"

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
if [[ -n "$BUILD" ]]; then
  NEW_TAG="v$NEW_VERSION+$BUILD"
else
  NEW_TAG="v$NEW_VERSION"
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
echo "Staged files:"
echo "$STAGED" | sed 's/^/  /'
echo ""
echo "Release: $NEW_TAG"
read -rp "Proceed? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Commit and tag ────────────────────────────────────────────────────────────

git commit -m "Release $NEW_TAG"

git tag -a "$NEW_TAG" -m "Release $NEW_TAG"

echo ""
echo "Tagged $NEW_TAG on commit $(git rev-parse --short HEAD)."
echo ""

printf "Pushing commit...     "
git push origin HEAD
echo "done."

printf "Pushing $NEW_TAG...   "
git push origin "$NEW_TAG"
echo "done."

printf "Moving latest tag...  "
git tag -f latest
git push origin latest --force
echo "done."

echo ""
echo "Released $NEW_TAG — users cloning --branch latest will get this version."
