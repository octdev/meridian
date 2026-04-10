# Releasing Meridian

## TL;DR

```bash
bash scripts/ci/release.sh
```

That's it. The script bumps the version, commits, tags, pushes, and moves the `latest` tag.

---

## What the Script Does

1. Checks for uncommitted changes (aborts if any)
2. Reads current version from `config/base/version.json`
3. Prompts: patch / minor / major / specific
4. Updates `version.json` and the `git clone` command in `README.md`
5. Commits as `Release vX.Y.Z`
6. Creates annotated tag `vX.Y.Z`
7. Pushes the commit and the version tag
8. Force-moves the `latest` tag to the same commit and pushes it

After the script finishes, `vX.Y.Z` and `latest` both point to the release commit.

---

## Before Running a Release

- All changes committed and on `main`
- Upgrade script and migration written (see below)
- `src/documentation/` updated if anything user-visible changed

---

## Upgrade Scripts

Every release needs two files under `scripts/upgrade/`:

### 1. Entry point — `upgrade-to-X.Y.Z.sh`

Copy the previous entry point. Change the version passed to `run_upgrade_to`:

```bash
source "${SCRIPT_DIR}/upgrade-runner.sh"
run_upgrade_to "X.Y.Z" "${SCRIPT_DIR}/migrations" "$@"
```

### 2. Migration — `migrations/vX.Y.Z.sh`

Each migration receives three arguments:

| Arg | Value |
|-----|-------|
| `$1` | `VAULT_ROOT` — absolute path to the vault |
| `$2` | `REPO_DIR` — absolute path to the repo |
| `$3` | `COMPANY` — set for per-company pass; empty for global pass |

The runner calls each migration **twice** per applicable version: once without `$3` (global vault changes), then once per selected company with `$3` set (company-specific changes under `Work/<company>/`).

Structure every migration like this:

```bash
if [[ -z "$COMPANY" ]]; then
  # global vault changes (add files, rename folders, etc.)
else
  # per-company changes under Work/$COMPANY/
fi
```

If a release has no structural vault changes (docs-only), the migration can be a no-op — see `migrations/v1.0.0.sh` as a template.

The runner handles:
- Sorting and filtering migrations to the applicable semver range
- Writing `.vault-version` after each step
- Refreshing vault documentation after all migrations complete
- Bumping `version.json` in the repo

---

## Tag Strategy

| Tag | Purpose |
|-----|---------|
| `vX.Y.Z` | Permanent, immutable release marker |
| `latest` | Mutable pointer — always the most recent release |

Users clone with `--branch latest`. The `--force` push on `latest` is intentional; it is a convenience pointer, not a release artifact.
