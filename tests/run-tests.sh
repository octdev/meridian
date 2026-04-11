#!/usr/bin/env bash
#
# run-tests.sh — Integration tests for Meridian scaffold scripts.
#
# Usage:
#   tests/run-tests.sh
#   tests/run-tests.sh --verbose
#
# Options:
#   --verbose   Print each test's output on failure (default: suppressed)
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCAFFOLD="$REPO_DIR/src/bin/scaffold-vault.sh"

VERBOSE=false
if [[ "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

# --- color setup ---
if [[ -t 1 ]]; then
  _GREEN='\033[0;32m'
  _RED='\033[0;31m'
  _AMBER='\033[0;33m'
  _CYAN='\033[0;96m'
  _RESET='\033[0m'
else
  _GREEN='' _RED='' _AMBER='' _CYAN='' _RESET=''
fi

# --- test state ---
PASS_COUNT=0
FAIL_COUNT=0
FAILURES=()

# --- helpers ---

pass() { printf "  ${_GREEN}✓${_RESET} %s\n" "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() {
  printf "  ${_RED}✗${_RESET} %s\n" "$1"
  FAILURES+=("$1")
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

section() { echo ""; printf "${_CYAN}%s${_RESET}\n" "$1"; }

# Run a command, capture output, check exit code and optional pattern.
# Usage: check <description> <expected_exit> [grep_pattern] -- <cmd...>
check() {
  local desc="$1"
  local expected_exit="$2"
  local pattern="${3:-}"
  shift 3
  # consume "--"
  [[ "$1" == "--" ]] && shift

  local output
  local actual_exit=0
  output="$("$@" 2>&1)" || actual_exit=$?

  if [[ "$actual_exit" -ne "$expected_exit" ]]; then
    fail "$desc (expected exit $expected_exit, got $actual_exit)"
    if $VERBOSE; then echo "    output: $output"; fi
    return
  fi
  if [[ -n "$pattern" ]] && ! echo "$output" | grep -qF -- "$pattern"; then
    fail "$desc (output missing: $pattern)"
    if $VERBOSE; then echo "    output: $output"; fi
    return
  fi
  pass "$desc"
}

# Assert a path exists (file or directory)
assert_exists() {
  local desc="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    pass "$desc"
  else
    fail "$desc (missing: $path)"
  fi
}

# Assert a path does NOT exist
assert_absent() {
  local desc="$1"
  local path="$2"
  if [[ ! -e "$path" ]]; then
    pass "$desc"
  else
    fail "$desc (should not exist: $path)"
  fi
}

# Assert file contains a string
assert_file_contains() {
  local desc="$1"
  local file="$2"
  local pattern="$3"
  if grep -qF -- "$pattern" "$file" 2>/dev/null; then
    pass "$desc"
  else
    fail "$desc (not found in $file: $pattern)"
  fi
}

# Assert file does NOT contain a string
assert_file_not_contains() {
  local desc="$1"
  local file="$2"
  local pattern="$3"
  if ! grep -qF -- "$pattern" "$file" 2>/dev/null; then
    pass "$desc"
  else
    fail "$desc (should not be in $file: $pattern)"
  fi
}

# --- temp dir management ---
TEST_TMPDIR="$(mktemp -d)"
cleanup() { rm -rf "$TEST_TMPDIR"; }
trap cleanup EXIT

new_vault() {
  # Return a fresh unique path under the shared temp dir
  echo "$TEST_TMPDIR/vault-$$-$RANDOM"
}

# ============================================================
# scaffold-vault.sh
# ============================================================

section "scaffold-vault.sh — help"

check "  -h exits 0" 0 "Usage:" -- "$SCAFFOLD" -h
check "  --help exits 0" 0 "Usage:" -- "$SCAFFOLD" --help

# ============================================================
section "scaffold-vault.sh — argument errors"

check "  unknown flag exits 1" 1 "unknown argument" -- "$SCAFFOLD" --unknown
check "  --vault with no value exits 1" 1 "--vault requires a path" -- "$SCAFFOLD" --vault
check "  --profile with no value exits 1" 1 "--profile requires a value" -- "$SCAFFOLD" --profile
check "  --profile invalid value exits 1" 1 "--profile must be" -- "$SCAFFOLD" --profile invalid --vault /tmp/x

# ============================================================
section "scaffold-vault.sh — personal profile"

PERSONAL_VAULT="$(new_vault)"
"$SCAFFOLD" --vault "$PERSONAL_VAULT" --profile personal > /dev/null 2>&1

# Shared folders
for d in \
  "Process/Weekly" "Process/Meridian Documentation" \
  "Work/CurrentCompany/Projects" "Work/CurrentCompany/People" "Work/CurrentCompany/Reference" \
  "Work/CurrentCompany/Incidents" "Work/CurrentCompany/Vendors" "Work/CurrentCompany/Goals" \
  "Work/CurrentCompany/Daily" "Work/CurrentCompany/Knowledge/Technical" \
  "_templates" ".scripts"; do
  assert_exists "  folder: $d" "$PERSONAL_VAULT/$d"
done

# Personal-only folders
for d in "Northstar" "Life/Projects" "Life/People" "Life/Health" \
          "Life/Finances" "Life/Social" "Life/Development" "Life/Fun" "References" \
          "Life/Daily" \
          "Knowledge/Technical" "Knowledge/Leadership" "Knowledge/Industry" "Knowledge/General"; do
  assert_exists "  personal folder: $d" "$PERSONAL_VAULT/$d"
done

# Process/Daily absent in personal vault
assert_absent "  Process/Daily absent in personal vault" "$PERSONAL_VAULT/Process/Daily"

# Templates
for f in "_templates/Daily Note.md" "_templates/Generic Note.md" "_templates/Reflection.md"; do
  assert_exists "  template: $f" "$PERSONAL_VAULT/$f"
done

# Northstar notes
for f in "Northstar/Purpose.md" "Northstar/Vision.md" "Northstar/Mission.md" \
          "Northstar/Principles.md" "Northstar/Values.md" "Northstar/Goals.md" "Northstar/Career.md"; do
  assert_exists "  northstar: $f" "$PERSONAL_VAULT/$f"
done

# Process MOCs
for f in "Process/Active Projects.md" "Process/Action Items.md" "Process/Open Loops.md" \
          "Process/Review Queue.md" "Process/Weekly Outtake.md"; do
  assert_exists "  MOC: $f" "$PERSONAL_VAULT/$f"
done

# Current Priorities seeded under Work/Goals (not Process/)
assert_exists "  Work/CurrentCompany/Goals/Current Priorities.md" \
  "$PERSONAL_VAULT/Work/CurrentCompany/Goals/Current Priorities.md"
assert_absent "  Process/Current Priorities.md absent (moved to Work/Goals/)" \
  "$PERSONAL_VAULT/Process/Current Priorities.md"

# Source tag notes
assert_exists "  source tag: Process/email.md" "$PERSONAL_VAULT/Process/email.md"
assert_exists "  source tag: Process/teams.md" "$PERSONAL_VAULT/Process/teams.md"

# Obsidian config
assert_exists "  config: .obsidian/daily-notes.json" "$PERSONAL_VAULT/.obsidian/daily-notes.json"
assert_exists "  config: .obsidian/templates.json" "$PERSONAL_VAULT/.obsidian/templates.json"

# Scripts deployed to .scripts/
assert_exists "  script: .scripts/weekly-snapshot.py" "$PERSONAL_VAULT/.scripts/weekly-snapshot.py"
assert_exists "  script: .scripts/new-company.sh" "$PERSONAL_VAULT/.scripts/new-company.sh"
assert_exists "  script: .scripts/new-project.sh" "$PERSONAL_VAULT/.scripts/new-project.sh"

# Documentation
for f in "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md" \
          "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md" "Meridian System.pdf"; do
  assert_exists "  doc: Process/Meridian Documentation/$f" "$PERSONAL_VAULT/Process/Meridian Documentation/$f"
done

# ============================================================
section "scaffold-vault.sh — personal profile frontmatter injection"

UG="$PERSONAL_VAULT/Process/Meridian Documentation/User Setup.md"
assert_file_contains "  User Setup.md has title frontmatter" "$UG" "title: User Setup"
assert_file_contains "  User Setup.md has created frontmatter" "$UG" "created:"
assert_file_contains "  User Setup.md has modified frontmatter" "$UG" "modified:"
assert_file_contains "  User Setup.md has --- delimiter" "$UG" "---"

# ============================================================
section "scaffold-vault.sh — personal profile obsidian config content"

assert_file_contains "  daily-notes.json: folder" "$PERSONAL_VAULT/.obsidian/daily-notes.json" '"folder": "Life/Daily"'
assert_file_contains "  daily-notes.json: template" "$PERSONAL_VAULT/.obsidian/daily-notes.json" '"template": "_templates/Daily Note"'
assert_file_contains "  daily-notes.json: format" "$PERSONAL_VAULT/.obsidian/daily-notes.json" '"format": "YYYY-MM-DD"'
assert_file_contains "  templates.json: folder" "$PERSONAL_VAULT/.obsidian/templates.json" '"folder": "_templates"'

# ============================================================
section "scaffold-vault.sh — work profile"

WORK_VAULT="$(new_vault)"
"$SCAFFOLD" --vault "$WORK_VAULT" --profile work > /dev/null 2>&1

# Shared folders present
for d in "Work/CurrentCompany/Projects" "Work/CurrentCompany/Daily" "Work/CurrentCompany/Goals" \
          "Work/CurrentCompany/Knowledge/Technical" "_templates" ".scripts"; do
  assert_exists "  work folder present: $d" "$WORK_VAULT/$d"
done

# Personal folders absent
for d in "Northstar" "Life" "References"; do
  assert_absent "  personal folder absent: $d" "$WORK_VAULT/$d"
done

# Northstar notes absent
assert_absent "  Northstar notes absent" "$WORK_VAULT/Northstar"

# Process/Daily and top-level Knowledge absent in work vault
assert_absent "  Process/Daily absent in work vault" "$WORK_VAULT/Process/Daily"
assert_absent "  top-level Knowledge absent in work vault" "$WORK_VAULT/Knowledge"

# Work vault daily-notes.json points to Work/CurrentCompany/Daily
assert_file_contains "  work daily-notes.json: folder" "$WORK_VAULT/.obsidian/daily-notes.json" '"folder": "Work/CurrentCompany/Daily"'

# Scripts and docs still present
assert_exists "  scripts deployed on work profile" "$WORK_VAULT/.scripts/new-company.sh"
assert_exists "  docs deployed on work profile" "$WORK_VAULT/Process/Meridian Documentation/User Setup.md"

# ============================================================
section "scaffold-vault.sh — idempotency (re-run skips existing files)"

IDEMPOTENT_VAULT="$(new_vault)"
"$SCAFFOLD" --vault "$IDEMPOTENT_VAULT" --profile personal > /dev/null 2>&1

output="$("$SCAFFOLD" --vault "$IDEMPOTENT_VAULT" --profile personal 2>&1)"

if echo "$output" | grep -q "Skipped (exists)"; then
  pass "  second run produces Skipped messages"
else
  fail "  second run produces Skipped messages"
fi
if ! echo "$output" | grep -qE "✗|Error|failed"; then
  pass "  second run has no errors"
else
  fail "  second run has no errors"
fi

# ============================================================
# new-company.sh
# ============================================================

section "new-company.sh — happy path"

COMPANY_VAULT="$(new_vault)"
"$SCAFFOLD" --vault "$COMPANY_VAULT" --profile personal > /dev/null 2>&1
COMPANY_SCRIPT="$COMPANY_VAULT/.scripts/new-company.sh"

printf "%s\n%s\n" "$COMPANY_VAULT" "Acme Corp" | bash "$COMPANY_SCRIPT" > /dev/null 2>&1

for d in "Incidents" "People" "Projects" "Reference" "Vendors" "Goals" \
          "Daily" "Knowledge/Technical" "Knowledge/Leadership" "Knowledge/Industry"; do
  assert_exists "  Work/Acme Corp/$d created" "$COMPANY_VAULT/Work/Acme Corp/$d"
done

assert_exists "  Work/Acme Corp/Goals/Current Priorities.md seeded" \
  "$COMPANY_VAULT/Work/Acme Corp/Goals/Current Priorities.md"

assert_file_contains "  daily-notes.json updated to new company" \
  "$COMPANY_VAULT/.obsidian/daily-notes.json" '"folder": "Work/Acme Corp/Daily"'

# ============================================================
section "new-company.sh — error cases"

# Collision
rc=0; output="$(printf "%s\n%s\n" "$COMPANY_VAULT" "Acme Corp" | bash "$COMPANY_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "already exists"; then
  pass "  collision exits 1 with message"
else
  fail "  collision exits 1 with message"
fi

# Empty company name
rc=0; output="$(printf "%s\n%s\n" "$COMPANY_VAULT" "" | bash "$COMPANY_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "cannot be empty"; then
  pass "  empty name exits 1"
else
  fail "  empty name exits 1"
fi

# Invalid vault path
rc=0; output="$(printf "%s\n%s\n" "/nonexistent/path" "TestCo" | bash "$COMPANY_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "does not exist"; then
  pass "  invalid vault exits 1"
else
  fail "  invalid vault exits 1"
fi

# Vault without Work/ directory
NO_WORK_VAULT="$(mktemp -d)"
rc=0; output="$(printf "%s\n%s\n" "$NO_WORK_VAULT" "TestCo" | bash "$COMPANY_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "Work/"; then
  pass "  missing Work/ exits 1"
else
  fail "  missing Work/ exits 1"
fi
rm -rf "$NO_WORK_VAULT"

# ============================================================
# new-project.sh
# ============================================================

section "new-project.sh — work project happy path"

PROJECT_VAULT="$(new_vault)"
"$SCAFFOLD" --vault "$PROJECT_VAULT" --profile personal > /dev/null 2>&1
printf "%s\n%s\n" "$PROJECT_VAULT" "Acme Corp" | bash "$PROJECT_VAULT/.scripts/new-company.sh" > /dev/null 2>&1
PROJECT_SCRIPT="$PROJECT_VAULT/.scripts/new-project.sh"

printf "%s\n%s\n%s\n" "Alpha Project" "$PROJECT_VAULT" "$PROJECT_VAULT/Work/Acme Corp/Projects" \
  | bash "$PROJECT_SCRIPT" > /dev/null 2>&1

PD="$PROJECT_VAULT/Work/Acme Corp/Projects/Alpha Project"
assert_exists "  project folder created" "$PD"
assert_exists "  project MOC created" "$PD/Alpha Project.md"
assert_exists "  Design/ created" "$PD/Design"
assert_exists "  Design/architecture.md" "$PD/Design/architecture.md"
assert_exists "  Design/design-decisions.md" "$PD/Design/design-decisions.md"
assert_exists "  Design/security.md" "$PD/Design/security.md"
assert_exists "  Requirements/ created" "$PD/Requirements"
assert_exists "  Requirements/brd.md" "$PD/Requirements/brd.md"
assert_exists "  Requirements/user-guide.md" "$PD/Requirements/user-guide.md"
assert_exists "  Requirements/roadmap.md" "$PD/Requirements/roadmap.md"
assert_exists "  Prompts/ created" "$PD/Prompts"
assert_exists "  Prompts/scratch.md" "$PD/Prompts/scratch.md"

# ============================================================
section "new-project.sh — MOC uses vault-relative paths"

MOC="$PD/Alpha Project.md"
assert_file_contains "  MOC dataview path is vault-relative" "$MOC" 'LIST FROM "Work/Acme Corp/Projects/Alpha Project"'
assert_file_contains "  MOC tasks path is vault-relative" "$MOC" 'path includes Work/Acme Corp/Projects/Alpha Project'
assert_file_not_contains "  MOC path does not use absolute filesystem path" "$MOC" "$PROJECT_VAULT"

# ============================================================
section "new-project.sh — MOC frontmatter and content"

assert_file_contains "  MOC has title frontmatter" "$MOC" "title: Alpha Project"
assert_file_contains "  MOC has created frontmatter" "$MOC" "created:"
assert_file_contains "  MOC has urgent tasks section" "$MOC" "description includes !!"
assert_file_contains "  MOC has standard tasks section" "$MOC" "description does not include !!"
assert_file_contains "  MOC has open loops section" "$MOC" "description includes ~"
assert_file_contains "  MOC has decisions dataview" "$MOC" "design-decisions"

# ============================================================
section "new-project.sh — Life project happy path"

printf "%s\n%s\n%s\n" "Home Reno" "$PROJECT_VAULT" "$PROJECT_VAULT/Life/Projects" \
  | bash "$PROJECT_SCRIPT" > /dev/null 2>&1

LPD="$PROJECT_VAULT/Life/Projects/Home Reno"
assert_exists "  Life project folder created" "$LPD"
assert_exists "  Life project MOC created" "$LPD/Home Reno.md"
assert_file_contains "  Life MOC path is vault-relative" "$LPD/Home Reno.md" 'LIST FROM "Life/Projects/Home Reno"'

# ============================================================
section "new-project.sh — error cases"

# Collision
rc=0; output="$(printf "%s\n%s\n%s\n" "Alpha Project" "$PROJECT_VAULT" "$PROJECT_VAULT/Work/Acme Corp/Projects" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "already exists"; then
  pass "  collision exits 1 with message"
else
  fail "  collision exits 1 with message"
fi

# Empty project name
rc=0; output="$(printf "%s\n%s\n%s\n" "" "$PROJECT_VAULT" "$PROJECT_VAULT/Work/Acme Corp/Projects" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "cannot be empty"; then
  pass "  empty name exits 1"
else
  fail "  empty name exits 1"
fi

# Nonexistent projects directory
rc=0; output="$(printf "%s\n%s\n%s\n" "TestProj" "$PROJECT_VAULT" "$PROJECT_VAULT/Work/Acme Corp/NoSuchDir" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "does not exist"; then
  pass "  nonexistent dir exits 1"
else
  fail "  nonexistent dir exits 1"
fi

# Invalid vault root
rc=0; output="$(printf "%s\n%s\n%s\n" "TestProj" "/no/such/vault" "/no/such/vault/Work/Acme Corp/Projects" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "does not exist"; then
  pass "  invalid vault root exits 1"
else
  fail "  invalid vault root exits 1"
fi

# ============================================================
section "new-project.sh — unexpected path: abort"

rc=0; output="$(printf "%s\n%s\n%s\nN\n" "TestProj" "$PROJECT_VAULT" "$PROJECT_VAULT/Knowledge/Technical" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 1 ]] && echo "$output" | grep -q "Unexpected" && echo "$output" | grep -q "Aborted"; then
  pass "  unexpected path + N aborts with exit 1"
else
  fail "  unexpected path + N aborts with exit 1"
fi

# ============================================================
section "new-project.sh — unexpected path: confirm and proceed"

rc=0; output="$(printf "%s\n%s\n%s\nY\n" "UnconvProj" "$PROJECT_VAULT" "$PROJECT_VAULT/Knowledge/Technical" \
  | bash "$PROJECT_SCRIPT" 2>&1)" || rc=$?
if [[ $rc -eq 0 ]] && echo "$output" | grep -q "scaffolded"; then
  pass "  unexpected path + Y proceeds with exit 0"
else
  fail "  unexpected path + Y proceeds with exit 0"
fi

# ============================================================
# Documentation alignment
# ============================================================

section "documentation — no references to nonexistent cheat-sheet.md"

assert_file_not_contains "  README.md does not reference cheat-sheet.md" \
  "$REPO_DIR/README.md" "cheat-sheet.md"
assert_file_not_contains "  User Setup.md does not reference cheat-sheet.md" \
  "$REPO_DIR/src/documentation/User Setup.md" "cheat-sheet.md"

# ============================================================
section "documentation — default vault path is correct"

assert_file_not_contains "  User Setup.md does not say default is ./vault" \
  "$REPO_DIR/src/documentation/User Setup.md" "Default path is \`./vault\`"
assert_file_contains "  User Setup.md states ~/Documents/Meridian as default" \
  "$REPO_DIR/src/documentation/User Setup.md" "~/Documents/Meridian"

# ============================================================
section "documentation — scaffold copies match what docs claim"

# Docs say these are copied to vault — verify scaffold-vault.sh actually copies them
for doc in "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md" \
            "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md"; do
  if grep -q "$doc" "$REPO_DIR/src/bin/scaffold-vault.sh"; then
    pass "  scaffold copies $doc (referenced in script)"
  else
    fail "  scaffold copies $doc (not found in scaffold-vault.sh)"
  fi
done

# Verify docs source files actually exist
for doc in "User Setup.md" "User Handbook.md" "Reference Guide.md" "Architecture.md" \
            "Design Decision.md" "Security.md" "Sync.md" "Roadmap.md"; do
  assert_exists "  src/documentation/$doc exists" "$REPO_DIR/src/documentation/$doc"
done

# Verify PDF exists
assert_exists "  Meridian System.pdf exists" "$REPO_DIR/Meridian System.pdf"

# ============================================================
# Summary
# ============================================================

echo ""
echo "────────────────────────────────────────"
if [[ "$FAIL_COUNT" -eq 0 ]]; then
  printf "${_GREEN}All $PASS_COUNT tests passed.${_RESET}\n"
else
  printf "${_RED}$FAIL_COUNT failed${_RESET}, $PASS_COUNT passed.\n"
  echo ""
  echo "Failures:"
  for f in "${FAILURES[@]}"; do
    printf "  ${_RED}✗${_RESET} %s\n" "$f"
  done
fi
echo "────────────────────────────────────────"
echo ""

[[ "$FAIL_COUNT" -eq 0 ]]
