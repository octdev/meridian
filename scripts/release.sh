#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
README="$REPO_DIR/README.md"

# ── Preflight checks ──────────────────────────────────────────────────────────

cd "$REPO_DIR"

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Error: uncommitted changes present. Commit or stash them before releasing."
  exit 1
fi

# ── Determine current version ─────────────────────────────────────────────────

LATEST_TAG="$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1)"

if [[ -z "$LATEST_TAG" ]]; then
  CURRENT="0.0.0"
else
  CURRENT="${LATEST_TAG#v}"
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

echo ""
echo "Current version: v$CURRENT"
echo ""
echo "Select release type:"
echo "  1) Patch  (v$MAJOR.$MINOR.$((PATCH + 1)))"
echo "  2) Minor  (v$MAJOR.$((MINOR + 1)).0)"
echo "  3) Major  (v$((MAJOR + 1)).0.0)"
echo "  4) Specific version"
echo ""
read -rp "Choice [1-4]: " CHOICE

case "$CHOICE" in
  1)
    NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
    ;;
  2)
    NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
    ;;
  3)
    NEW_VERSION="$((MAJOR + 1)).0.0"
    ;;
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
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac

NEW_TAG="v$NEW_VERSION"

# ── Confirm ───────────────────────────────────────────────────────────────────

echo ""
echo "Release: $NEW_TAG"
read -rp "Proceed? [y/N] " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# ── Update README ─────────────────────────────────────────────────────────────

# Replaces any existing clone line (with or without prior --branch flag) with
# the versioned form.
sed -i '' \
  "s|git clone\( --branch v[0-9][^ ]*\)\?\( --depth 1\)\? https://github.com/\(.*\)\.git|git clone --branch $NEW_TAG --depth 1 https://github.com/\3.git|g" \
  "$README"

echo "Updated README.md clone command to $NEW_TAG."

# ── Commit README update ──────────────────────────────────────────────────────

git add "$README"
git commit -m "Release $NEW_TAG"

# ── Tag ───────────────────────────────────────────────────────────────────────

git tag -a "$NEW_TAG" -m "Release $NEW_TAG"

echo ""
echo "Tagged $NEW_TAG on commit $(git rev-parse --short HEAD)."
echo ""
echo "To push:"
echo "  git push && git push origin $NEW_TAG"
