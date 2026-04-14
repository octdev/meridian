# Phase 4 — Release Spec

**Audience:** Developer or release engineer executing the release.
**Depends on:** Phases 1, 2, and 3 fully complete. All tests passing. `docs/validation-plan.md` exists.
**Produces:** Tagged release, upgraded vault, completed validation.

---

## Context

Meridian is a personal knowledge management system built on Obsidian. The release process tags a git commit, then tests the upgrade path on a real vault. See `src/documentation/Architecture.md` for system context and `scripts/upgrade/` for the upgrade system.

**Before starting:** confirm all three prior phases are complete:
- Phase 1: `docs/phase-1-migration-notes.md` exists with no unresolved deviations
- Phase 2: all documentation files updated; audit complete
- Phase 3: tests passing, `docs/validation-plan.md` exists, version bumped to `1.5.0`

---

## Step 1 — Pre-flight Tests

Run the full test suite against a freshly scaffolded vault. All tests must pass before tagging.

```bash
cd /path/to/meridian
tests/run-tests.sh
```

If any test fails: stop. Do not proceed to release. Fix the failure and re-run until clean.

Optional verbose output for diagnosing failures:
```bash
tests/run-tests.sh --verbose
```

**Expected:** all tests pass, exit code 0.

---

## Step 2 — Create the Release

The release script tags the current commit and optionally updates the README. Study `scripts/ci/release.sh` before running.

```bash
bash scripts/ci/release.sh
```

Follow the prompts. When asked for the version, enter `1.5.0`.

After the script completes:
- Verify the `v1.5.0` tag exists: `git tag | grep 1.5.0`
- Verify `config/base/version.json` reflects `1.5.0` and today's date
- Verify `gitCommit` in `version.json` has been updated from `"pending"` to the actual SHA

---

## Step 3 — Run the Upgrade

Run the upgrade against a real vault that was previously on `1.4.0` (or earlier). This vault must have real content — at least one meeting series and files in `References/` — to exercise the migration paths.

**Close Obsidian before running the upgrade.**

```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --upgrade
```

The script prompts for vault selection and company selection. Select the test vault and all applicable companies.

**Watch for:**
- `References/` move: should log a pass for `Knowledge/References/`
- Series folder moves: should log a pass for each series found
- Script deployment: should log passes for `new-standalone-meeting.sh`, `new-meeting-series.sh`, `new-1on1.sh`
- No unexpected errors or aborts

If the upgrade fails partway through:
1. Note the last successful version logged
2. Check `$VAULT/.scripts/.vault-version` — it reflects the last successfully completed migration
3. Do not re-run blindly — diagnose the failure first

After the upgrade completes, verify `.vault-version` now contains `vault=1.5.0`.

---

## Step 4 — Post-upgrade Tests

Run the test suite against the just-upgraded vault:

```bash
tests/run-tests.sh
```

**Expected:** all tests pass. If any test fails, the upgrade has a defect — do not proceed to validation.

---

## Step 5 — Review and Execute the Validation Plan

Open `docs/validation-plan.md`. Work through every item in order. Open the upgraded vault in Obsidian first.

For each item:
- Execute the described action
- Mark the checkbox if the behavior is correct
- If a check fails: note the failure inline in the validation plan and stop

**All items must pass before the release is considered complete.**

If a validation item fails, triage it:
- Is it a documentation error (wrong path described)? → Fix in `src/documentation/` and re-tag
- Is it a migration defect (files in wrong place)? → Fix in `scripts/upgrade/migrations/v1.5.0.sh`, re-run upgrade, re-validate
- Is it a script defect (new-standalone-meeting.sh misbehaves)? → Fix in `src/bin/`, re-deploy via upgrade, re-validate

---

## Step 6 — Run Final Tests

After validation is complete and all items pass:

```bash
tests/run-tests.sh
```

This is the final gate. Exit code 0 closes the release.

---

## Deliverables Checklist

- [ ] Pre-flight tests passed (`tests/run-tests.sh` exit 0)
- [ ] Release tagged `v1.5.0` with correct SHA in `version.json`
- [ ] Upgrade executed on real vault without errors
- [ ] `.vault-version` updated to `vault=1.5.0` in upgraded vault
- [ ] Post-upgrade tests passed
- [ ] All items in `docs/validation-plan.md` checked and passing
- [ ] Final test run passed
