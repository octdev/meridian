# DRY Audit — Scripts and Libraries

This document catalogs all duplicated logic across `src/bin/scaffold-vault.sh`,
`scripts/upgrade/upgrade-runner.sh`, and `scripts/local/refresh-documentation.sh`,
and prescribes the refactors needed to eliminate the duplication.

The motivating bug: `upgrade-runner.sh` duplicated the remote doc fetch logic
from `refresh-documentation.sh` and dropped the temp-directory indirection.
This caused it to overwrite `src/documentation/` in the local working tree during
an upgrade run, silently destroying uncommitted documentation changes. A patched
workaround is already in place (commit ad0eb10 + the bug fix commit), but the
duplication still exists.

---

## Findings

### Finding 1 — Remote doc fetch logic (HIGH — caused the bug)

**Where duplicated:**
- `scripts/local/refresh-documentation.sh` lines 98–148
- `scripts/upgrade/upgrade-runner.sh` lines 401–431

**What they share:**
Both scripts hit the same GitHub API endpoint, fetch the same list of documentation
files via `curl`, stage them into a directory, and fall back to the local repo on
failure. The only difference is that `refresh-documentation.sh` correctly fetches
into a temp dir and never touches the local repo; `upgrade-runner.sh` originally
wrote directly to `src/documentation/` (the bug), and the current fix replicates
the temp-dir pattern inline.

**Fix:**
Extract to a new library function `fetch_docs_from_remote()` in `src/lib/fetch-docs.sh`.

```
# Usage: fetch_docs_from_remote <repo_dir>
# Sets:
#   FETCH_EFFECTIVE_REPO_DIR — temp dir containing fetched docs (or repo_dir on skip)
#   FETCH_DOC_SOURCE         — human-readable source label for display
# Caller is responsible for cleanup of FETCH_EFFECTIVE_REPO_DIR if it differs from repo_dir.
```

Both callers replace their inline fetch blocks with a single call:

```bash
source "$REPO_DIR/src/lib/fetch-docs.sh"
fetch_docs_from_remote "$REPO_DIR"
refresh_vault_docs "$vault_root" "$FETCH_EFFECTIVE_REPO_DIR"
echo "  Documentation: $FETCH_DOC_SOURCE"
```

---

### Finding 2 — Doc file list (MEDIUM — maintenance surface)

**Where duplicated:**
- `scripts/local/refresh-documentation.sh`: `_DOC_FILES` array (same 9 files)
- `scripts/upgrade/upgrade-runner.sh`: `_UPGRADE_DOC_FILES` array (same 9 files)
- `src/lib/refresh-vault-docs.sh`: explicit per-file calls (lines 45–53) and `_current`
  stale-removal array (lines 62–65)
- `src/bin/scaffold-vault.sh`: explicit per-file calls (lines 504–512)

Every time a documentation file is added, renamed, or removed, all four locations
must be updated. This has already caused a stale-removal inconsistency: the `_current`
array in `refresh-vault-docs.sh` could drift from the actual call list above it in
the same file.

**Fix:**
Define a single canonical array `_MERIDIAN_DOC_FILES` in `src/lib/fetch-docs.sh`
(same library as Finding 1). `refresh-vault-docs.sh` and both calling scripts read
from this array instead of maintaining their own lists. The `refresh_vault_docs()`
function iterates `_MERIDIAN_DOC_FILES` for both the copy loop and the stale-removal
check.

---

### Finding 3 — `semver_from_version_json` / `_semver_from_version_json` (LOW)

**Where duplicated:**
- `src/bin/scaffold-vault.sh` defines `semver_from_version_json()` (line 88)
- `scripts/upgrade/upgrade-runner.sh` defines `_semver_from_version_json()` (line 50)
  — same implementation, different name, private underscore prefix

The upgrade runner also defines `_semver_lt`, `_semver_lte`, and `_write_version_json`.
None of these are in any shared library.

**Fix:**
Move all semver helpers into a new `src/lib/semver.sh` library:
- `semver_from_version_json()`
- `semver_lt()`
- `semver_lte()`
- `write_version_json()`

`scaffold-vault.sh` sources `semver.sh` and removes its inline definition.
`upgrade-runner.sh` sources `semver.sh` and removes its inline definitions.
Names should drop the underscore prefix (these are library-level, not internal).

---

### Finding 4 — `copy_doc_with_frontmatter` / `_overwrite_doc` (LOW)

**Where duplicated:**
- `src/bin/scaffold-vault.sh` defines `copy_doc_with_frontmatter()` (lines 224–242):
  skip-if-dest-exists semantics, takes a `ts` argument
- `src/lib/refresh-vault-docs.sh` defines `_overwrite_doc()` (lines 31–41): always
  overwrites, derives `ts` from an outer-scope variable

The frontmatter injection `printf '---\ntitle: %s\ncreated: %s\nmodified: %s\n---\n'`
is identical in both.

These legitimately differ in skip vs. overwrite semantics, so they should remain
separate functions. However, the frontmatter formatting line is a shared detail worth
isolating to avoid future drift (e.g., adding a new frontmatter field in one but
not the other).

**Fix:**
Add a helper `write_doc_with_frontmatter <src> <dest> <title> <ts>` to
`src/lib/refresh-vault-docs.sh` that always overwrites (used by `_overwrite_doc`
and available to scaffold's upgrade path). `scaffold-vault.sh` retains its own
`copy_doc_with_frontmatter` for the skip-if-exists initial scaffold case, but
delegates the actual write to the shared helper to share the formatting logic.

This is the lowest-priority finding — the formats have been stable and the risk
of drift is low.

---

## Files to Create

| File | Purpose |
|------|---------|
| `src/lib/fetch-docs.sh` | `fetch_docs_from_remote()` + `_MERIDIAN_DOC_FILES` array |
| `src/lib/semver.sh` | `semver_from_version_json()`, `semver_lt()`, `semver_lte()`, `write_version_json()` |

---

## Files to Modify

| File | Change |
|------|--------|
| `scripts/upgrade/upgrade-runner.sh` | Source `fetch-docs.sh` and `semver.sh`; remove inline fetch block and semver helpers; call `fetch_docs_from_remote()` |
| `scripts/local/refresh-documentation.sh` | Source `fetch-docs.sh`; remove inline fetch block; call `fetch_docs_from_remote()` |
| `src/lib/refresh-vault-docs.sh` | Drive copy and stale-removal loops from `_MERIDIAN_DOC_FILES`; expose `write_doc_with_frontmatter()` helper |
| `src/bin/scaffold-vault.sh` | Source `semver.sh`; remove inline `semver_from_version_json`; optionally delegate write step of `copy_doc_with_frontmatter` to library helper |

---

## Implementation Order

1. **`src/lib/semver.sh`** — no dependencies, lowest risk. Update `scaffold-vault.sh`
   and `upgrade-runner.sh` to source it. Verify `--version` and upgrade version checks
   still work.

2. **`src/lib/fetch-docs.sh`** — define `_MERIDIAN_DOC_FILES` and
   `fetch_docs_from_remote()`. Update `refresh-vault-docs.sh` to iterate from the
   array. Update both callers. Run the existing refresh-documentation tests to verify.

3. **Finding 4 (optional)** — low risk, low value. Do only if a new frontmatter field
   is being added and both implementations need updating anyway.

---

## Out of Scope

- `copy_if_new` and `write_if_new` in `scaffold-vault.sh` — scaffold-only helpers
  with no other callers. Not worth extracting.
- `_offer_shell_exports` in `src/lib/shell-exports.sh` — already in a library,
  already used by both scaffold and upgrade runner. No action needed.
- `vault-select.sh` — already shared across all scripts. No action needed.
