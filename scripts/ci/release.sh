#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
VERSION_FILE="$REPO_DIR/config/base/version.json"

# ── Preflight checks ──────────────────────────────────────────────────────────

cd "$REPO_DIR"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: $VERSION_FILE not found."
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

# Guard against re-releasing an already-tagged version.
if git tag --list | grep -q "^${NEW_TAG}$"; then
  echo "Error: tag $NEW_TAG already exists. Run scripts/ci/version.sh to bump the version."
  exit 1
fi

# ── Confirm ───────────────────────────────────────────────────────────────────

STAGED="$(git diff --cached --name-only)"

echo ""
if [[ -n "$STAGED" ]]; then
  echo "Staged files (will be included in release commit):"
  echo "$STAGED" | sed 's/^/  /'
else
  echo "No staged changes — tagging HEAD."
fi
echo ""
echo "Release: $NEW_TAG"
read -rp "Proceed? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Commit (if staged changes exist) and tag ─────────────────────────────────

if [[ -n "$STAGED" ]]; then
  git commit -m "Release $NEW_TAG"
fi

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
git branch -f latest
git push origin latest --force
echo "done."

echo ""
echo "Released $NEW_TAG — users cloning --branch latest will get this version."
