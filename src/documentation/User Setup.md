# User Setup

## Table of Contents

1. [[#How It Works]]
2. [[#Prerequisites]]
3. [[#Initial Setup]]
4. [[#Work Machine Setup]]
5. [[#Appearance Settings]]
6. [[#Files and Links]]
7. [[#Core Plugins]]
8. [[#Community Plugins]]
9. [[#Hotkey Setup]]
10. [[#Vault Updates]]
11. [[#Verification]]
12. [[#Daily Workflow]]
13. [[#Markers and Conventions]]
14. [[#MOCs]]
15. [[#Weekly Snapshots]]
16. [[#Managing Companies]]
17. [[#Managing Projects]]
18. [[#Managing Meetings]]
19. [[#Filing Heuristics]]
19. [[#Maintenance]]
20. [[#Documentation]]

---

## How It Works

Meridian is a daily-note-first capture system. Everything that happens to you during the day lands in a single dated note. Inline markers (!, !!, ~, >>, etc.) tag items for automated retrieval. Seven Maps of Content (MOCs) query those markers live across all your daily notes. A Python script generates static weekly snapshots every Monday.

Frontmatter (title, created, modified) is managed entirely by plugins — you never type it manually.

---

## Prerequisites

| Tool | Why | Install |
|------|-----|---------|
| Obsidian (desktop) | The vault host | [obsidian.md](https://obsidian.md) |
| Python 3 | Weekly snapshot script | `brew install python` |
| Bash | Scaffold script | macOS built-in |

Verify Python 3 is available:
```bash
python3 --version
```

---

## Initial Setup

### Step 1: Run the scaffold script

**Clone the repo:**
```bash
git clone --branch latest --depth 1 https://github.com/your-username/meridian.git
cd meridian
export MERIDIAN_PROJECT="$(pwd)"
```

**Personal machine:**
```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --vault ~/Documents/Meridian
export MERIDIAN_VAULT=~/Documents/Meridian
```

**Work machine:**
```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
export MERIDIAN_VAULT=~/Documents/WorkVault
```

The scaffold script prompts you to add the `export` lines to `~/.zshrc` or `~/.bash_profile` automatically. After confirming, reload your shell before using them:

```bash
source ~/.zshrc   # or ~/.bash_profile for bash
```

The variables are also set inline above for the current session. The `source` step (or opening a new terminal) is what makes them available in every future session. All the command examples in this file assume both variables are set.

The `--profile work` flag creates only the folders appropriate for an employer-managed machine — `Process/` and `Work/`. `Northstar/`, `Life/`, and the top-level `Knowledge/` are never created. See [Work Machine Setup](#work-machine-setup) for the full workflow.

Default path is `~/Documents/Meridian` if `--vault` is omitted (the script will prompt to confirm).

The scaffold script automatically copies all scripts (`weekly-snapshot.py`, `new-company.sh`, `new-project.sh`, `new-meeting-series.sh`) into `.scripts/` and copies the full documentation suite into `Process/Meridian Documentation/`, including a PDF of the quick reference.

### Upgrading an existing vault

**Close Obsidian before running an upgrade.** Some migrations update `.obsidian/app.json`. If Obsidian is open, it will overwrite that file with its cached settings when it closes, discarding the migration changes.

To upgrade an existing vault to the latest Meridian version:

```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --upgrade
```

The script will prompt you to select a vault and which company folders to upgrade. See [[Upgrading]] for the full upgrade guide.

### Step 2: Open the vault in Obsidian

Obsidian → Open folder as vault → select the vault root.

### Step 3: Rename CurrentCompany

In the file explorer, rename `Work/CurrentCompany/` to your actual company name.

---

## Work Machine Setup

Meridian is designed to run on both personal and work machines simultaneously, with the full vault on your personal machines and a subset of that vault on your work machines.  The `--profile work` flag is the starting point for work machine setup.  This allows the Meridian capture system to be used across your personal and work time, while keeping your personal knowledge management separate from your work systems and intellectual property.
### What the work profile includes

| Folder | Personal vault | Work vault |
|--------|---------------|------------|
| `Process/` | Yes | Yes |
| `Work/` | Yes | Yes |
| `Knowledge/` | Yes | **No** (lives at `Work/<Company>/Knowledge/`) |
| `_templates/` | Yes | Yes |
| `.scripts/` | Yes | Yes |
| `Northstar/` | Yes | **No** |
| `Life/` | Yes | **No** |

The two omitted folders (`Northstar/` and `Life/`) are intentionally absent — not excluded by a setting, not gitignored, not hidden. They simply do not exist on the work machine. The top-level `Knowledge/` folder is also absent from the work vault; work-generated knowledge lives at `Work/<Company>/Knowledge/`. `References/` no longer exists as a top-level folder in either profile — it lives at `Knowledge/References/` in the personal vault only. Syncthing is configured to never introduce personal folders on the work machine.

### Work machine scaffold

```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
export MERIDIAN_VAULT=~/Documents/WorkVault
```

Then follow the standard setup from [Step 1: Run the scaffold script](#initial-setup) → [Appearance Settings](#appearance-settings) onward. The plugin stack, hotkeys, and daily workflow are identical between profiles — the only difference is which folders exist.

### Syncthing configuration for the work machine

Only the active company folder syncs between the work machine and personal machine. Configure a single Syncthing share for `Work/<Company>/` — not the `Work/` parent.

| Folder | Mode |
|--------|------|
| `Work/<Company>/` | Send & Receive |
| `Life/` | Not configured |
| `Northstar/` | Not configured |

`Work/<Company>/` includes all subfolders: `Daily/`, `Knowledge/`, `Goals/`, `Projects/`, `People/`, `Meetings/`, and the rest. Everything under the company folder travels as one share. `Process/` is not synced — its contents are rebuilt locally or refreshed on upgrade. See [Sync.md](Sync.md) for full setup instructions.

---

## Appearance Settings

Configure these before enabling plugins. Order matters.

1. **Settings → Appearance → Inline title → OFF**
   The H1 heading is the visible title. Inline title duplicates it.

2. **Settings → Appearance → Show tab title bar → ON**
   Shows the tab bar for navigating open notes.

Optional User Preferences for flow:

1. **Settings → Editor → Behavior → Auto-pair Brackets → OFF**

2. **Settings → Editor → Behavior → Auto-pair Markdown Syntax → OFF**

---

## Editor Settings

1. **Settings → Editor → Default editing mode → Source mode**
   Required for frontmatter to render as raw YAML. Live Preview collapses the frontmatter block.

2. **Settings → Editor → Properties in document → Source**
   Renders frontmatter as editable YAML inline.
   **Important:** this setting must remain Source. Changing it to Visible breaks the Front Matter Timestamps → Linter chain. If frontmatter stops populating after changing this setting, revert to Source.

---

## Files and Links

Settings → Files and Links

The scaffold sets **Default location for new notes** and **Default location for new attachments** automatically in `.obsidian/app.json`. If you ran the scaffold, these are already correct — verify but do not override. If you are setting up manually, use the values below.

| Setting | Value |
|---------|-------|
| Default file to open | Daily note |
| Default location for new notes | `Life/Drafts` (personal) or `Work/<Company>/Drafts` (work) — **In the folder specified below** |
| Default location for new attachments | `Knowledge/References` (personal) or `Work/<Company>/Reference` (work) — **In the folder specified below** |
| Confirm file deletion | OFF |

---

## Core Plugins

### Daily Notes

Settings → Core Plugins → Daily Notes → ON

| Setting | Value |
|---------|-------|
| Date format | `YYYY-MM-DD` |
| New file location | `Life/Daily` (personal) or `Work/<Company>/Daily` (work) |
| Template file location | `_templates/Daily Note` |

### Templates

Settings → Core Plugins → Templates → ON

| Setting | Value |
|---------|-------|
| Template folder location | `_templates` |
| Date format | `YYYY-MM-DD` |
| Time format | `HH:mm` |

---

## Community Plugins

Settings → Community Plugins → Enable community plugins → Browse

Install in this order.

### 1. Tasks

Search "Tasks" → Install → Enable

| Setting | Value |
|---------|-------|
| Set created date on every added task | ON |
| Auto-suggest | ON |

### 2. Dataview

Search "Dataview" → Install → Enable

| Setting | Value |
|---------|-------|
| Enable JavaScript Queries | OFF |
| Enable Inline Queries | ON |

### 3. Filename Heading Sync

Search "Filename Heading Sync" → Install → Enable

| Setting | Value |
|---------|-------|
| Use File Open Hook | ON |
| Use File Save Hook | ON |
| Insert Heading If Missing | ON |
| New Heading Style | Prefix |
| Replace Heading Style | OFF |
| Rename Debounce Timeout | `1000` |
| Ignore Regex Rule | `_templates/*` |

The `_templates` exclusion is required. Without it, Filename Heading Sync renames template files to match their placeholder H1 content, corrupting them.

### 4. Linter

Search "Linter" → Install → Enable

**Settings → Linter → General tab:**

| Setting | Value |
|---------|-------|
| Lint on Save | ON |
| Lint on Focused File Change | ON |
| Display message on lint | OFF |
| Display Lint on File Change Message | OFF |
| Folders to Ignore | `_templates` |

The `_templates` exclusion is required. Without it, Linter resolves placeholder syntax in templates on save.

**Settings → Linter → YAML tab:**

| Setting | Value |
|---------|-------|
| Add Blank Line After YAML | ON |
| Insert YAML Attributes | ON |
| Text to insert | `title: `<br>`created: `<br>`modified: ` |
| YAML Title | ON |
| Title Key | `title` |
| Mode | `First Heading or Filename` |

### 5. Front Matter Timestamps

Search "Front Matter Timestamps" → Install → Enable

| Setting | Value |
|---------|-------|
| Automatic update | ON |
| Automatic timestamps | ON |
| Created property name | `created` |
| Modified property name | `modified` |
| Date and time format | YYYY-MM-DD HH:mm:ss |
| Delay adding timestamps to new files | `100` |
| Excluded folders | `_templates` |
| Execute command after update | Save current file |

The 100ms delay gives Obsidian time to initialize the new file before timestamps are written. The "Save current file" command triggers Linter to populate the `title` field. This chain is timing-dependent. If `title` stops populating after plugin changes, increase the delay in 50ms increments until it stabilizes.

**Note:** "Save current file" may not appear in the Execute command dropdown in all plugin versions. Search the dropdown for "save" — if it is absent, leave the field blank and trigger Linter manually (`Ctrl+Alt+L`) until the issue is resolved.

### 6. Editing Toolbar

Search "Editing Toolbar" → Install → Enable

No additional configuration required.

### 7. Hider

Search "Hider" → Install → Enable

| Setting | Value |
|---------|-------|
| Hide properties in Reading view | ON |

### 8. Shell Commands

Search "Shell commands" → Install → Enable

#### Command 1: Weekly Outtake (automatic)

1. Click **New command**
2. Enter: `python3 {{vault_path}}/.scripts/weekly-snapshot.py {{vault_path}}`
3. Click gear icon → **Events** tab:
   - Enable **Obsidian starts**
   - Enable **Every n seconds** → `14400`
4. **Output** tab → Output channel for stdout : **Ignore**
5. Set alias: "Generate Weekly Outtake"

If Python 3 is not in PATH, use the full path: `/usr/bin/python3`

#### Command 2: New Meeting Series (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-meeting-series.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New Meeting Series"

After adding: open the command palette (`Cmd+P`) and confirm **New Meeting Series** appears. Run it once against your vault to verify the series and instance folders are created correctly before relying on it in a live meeting prep flow.

#### Command 3: New 1:1 (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-1on1.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New 1:1"

After adding: open the command palette (`Cmd+P`) and confirm **New 1:1** appears. The script creates a new note on first run for a given person, and appends a dated entry on subsequent runs — so the same command handles both first-time setup and recurring meetings.

#### Command 4: New Company (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-company.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New Company"

#### Command 5: New Project (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-project.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New Project"

#### Command 6: New Meeting (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-standalone-meeting.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New Meeting"

#### Troubleshooting Shell Commands

If a command silently does nothing when run from the palette, the most common cause is that Shell Commands is not configured to open a terminal. Interactive scripts (anything that prompts for input) require a real terminal session:

1. Open Shell Commands settings → find the command → click the gear icon
2. Go to the **Environments** tab
3. Under **Shell**, confirm it is set to your system shell (e.g. `/bin/bash` or `/bin/zsh`)
4. Under **Execute in**, select **New terminal** (not "Background")

Re-run from the palette — a terminal window should open and display the prompts.

### 9. Scroller

Search "Scroller" → Install → Enable

| Setting | Value |
|---------|-------|
| Auto-scroll on mode change | OFF |
| Enable typewriter mode | OFF |

Scroller moves the cursor to the bottom of a note on open and after tab title rename — placing it at the Log section ready to capture.

**Note:** Install Scroller last. Installing other plugins afterward can interfere with it — if auto-scroll stops working, disable and re-enable Scroller to restore it.

### Restart Obsidian

Restart once after all plugins are installed.

---

## Hotkey Setup

Settings → Hotkeys → search for each command and assign:

| Command | Recommended hotkey |
|---------|-------------------|
| Daily Notes: Open today's daily note | `Cmd+D` |
| Daily Notes: Open previous daily note | `Cmd+-` |
| Daily Notes: Open next daily note | `Cmd+=` |
| Templates: Insert template | `Cmd+Shift+T` |

Assign the Templates hotkey to quickly insert the Reflection template at end of day: Settings → Hotkeys → search "Templates: Insert template" → assign `Cmd+Shift+T`.

**Conflict:** macOS and most browsers assign `Cmd+Shift+T` to "Reopen closed tab." If the hotkey doesn't fire inside Obsidian, remove that system or browser assignment, or choose an alternate hotkey.

---

## Vault Updates

### Upgrading an existing vault

To upgrade an existing vault to the latest Meridian version:

```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --upgrade
```

The script will prompt you to select a vault and which company folders to upgrade. It runs all applicable migration scripts in order, then overwrites `Process/Meridian Documentation/` with the latest docs. The shell variable prompt runs at the end of every upgrade — if you skipped it during initial setup, upgrading is the other way to get it.

If you want to set up the shell variables without upgrading:

```bash
cd /path/to/meridian
./src/bin/scaffold-vault.sh --setup-shell
```

After the script writes to your rc file, reload your shell:

```bash
source ~/.zshrc   # or ~/.bash_profile for bash
```

See [[Upgrading]] for the full upgrade guide, including what happens when upgrading across multiple versions and how per-company version tracking works.

### Rename CurrentCompany

The scaffold creates a placeholder folder at `Work/CurrentCompany/`. Rename it to your actual company name before you start using the vault.

1. In Obsidian, open the file explorer
2. Right-click `Work/CurrentCompany` → **Rename**
3. Enter your company name exactly as you want it to appear (e.g. `Acme Corp`) and press Enter

Alternatively, open a terminal:
```bash
mv "$MERIDIAN_VAULT/Work/CurrentCompany" "$MERIDIAN_VAULT/Work/Your Company Name"
```

---

## Verification

Work through these checks after setup.

1. Press `Cmd+D` — a note should appear in `Life/Daily/YYYY-MM-DD.md` (personal vault) or `Work/<Company>/Daily/YYYY-MM-DD.md` (work vault), with the template populated and `created`/`modified` timestamps filled in.
2. Add a test task: `- [ ] !! Test urgent action item`
3. Open `Process/Action Items.md` — the task should appear under Urgent.
4. Check the task — it should show `✅ YYYY-MM-DD` and move to Recently Completed — Urgent.
5. Open `Process/Active Projects.md` — should be empty but no query errors, confirming Dataview is running.
6. Press `Cmd+N` — a blank note should appear. Wait 1–2 seconds. `created` and `modified` should populate. Type a `# Heading` and save — the filename should update and frontmatter `title` should populate.
7. Command palette → "Generate Weekly Outtake" — should run without error (output file in `Process/Weekly/` if any tasks exist).

---

## Daily Workflow

### Morning (~2 minutes)

1. Open today's daily note via `Cmd+D`
2. Glance at calendar — drop meeting headings into Log
3. Fill in Top 3 Goals
4. First comms triage — scan email and Teams

### Throughout the day

- Capture meeting notes under time-stamped `###` headings
- Add comms action items inline as they arrive
- Prefix interruptions: `— [[teams]]` or `— [[email]]`
- Intentional work (project notes, knowledge articles, person notes) goes directly into the right folder — not the daily note

The core rule: things that *happen to you* go in the daily note. Things you *intentionally create* go directly where they belong.

### End of day (~5 minutes)

- Final comms sweep
- Quick scan: any `!!` items missed?
- Optional: insert the Reflection template via `Cmd+Shift+T`. The template adds structured prompts for what went well, what was hard, what you'd do differently, and what to carry forward.

### Weekly review (~15–20 minutes)

1. **Weekly Outtake** — scan what shipped. Note patterns, wins, gaps.
2. **Action Items MOC** — anything overdue or stale? Close it or re-date it.
3. **Open Loops MOC** — follow up or mark done.
4. **Review Queue MOC** — process `>>` items: promote to Knowledge/Work/Life or check off.
5. **Current Priorities** — update if anything shifted.
6. Scan the week's daily notes for `&` insights worth promoting to Knowledge.
7. **Drafts** — file or delete any notes left in `Life/Drafts/` (personal) or `Work/<Company>/Drafts/` (work).

---

## Markers and Conventions

### Markers

Markers go at the start of a bullet, after the checkbox if present. Actionable items use checkboxes. Observations are plain bullets.

| Marker | Meaning | MOC |
|--------|---------|-----|
| `!` | Action item | Action Items (Standard) |
| `!!` | Urgent action item | Action Items (Urgent) |
| `~` | Waiting on someone | Open Loops |
| `>>` | Process later | Review Queue |
| `?` | Decision made | (searchable) |
| `&` | Insight or realization | (searchable) |
| `^` | Risk or concern | (searchable) |
| `*` | Feedback given or received | (searchable) |

Examples:
```
- [ ] ! Schedule 1:1 with [[Jane Doe]]
- [ ] !! Fix prod alert {{2026-03-12}}
- [ ] ~ [[Bob Smith]] owes API spec
- [ ] >> interesting SRE article to read
- ? Chose Kafka over SQS for event bus
- & Team velocity drops when PRs > 3 days
- ^ Migration timeline assumes no Q2 freeze
- * Told [[Jane Doe]] her RFC was strong
```

### Source tags

Source tags record where an action item came from. Add one at the end of a bullet when the origin matters for follow-up or context.

```
— [[email]]   action item originated from email
— [[teams]]   action item originated from Teams
```

### Due dates

Only add when there is a real deadline:
```
- [ ] !! Ship v2 API {{2026-03-15}}
```

### Links

```
[[First Last]]     person
[[Project Name]]   project
[[Topic Name]]     knowledge topic
```

### Status tags

```
#open        unresolved
#done        resolved
#cancelled   no longer relevant
```

---

## MOCs

| MOC | Engine | Pulls from | When to check |
|-----|--------|------------|---------------|
| Active Projects | Dataview | Work + Life Projects folders | Weekly review |
| Action Items | Tasks | `!` and `!!` markers | Daily + weekly |
| Open Loops | Tasks | `~` markers | Weekly review |
| Review Queue | Tasks | `>>` markers | Weekly review |
| Weekly Outtake | Tasks | All completed (rolling 7 days) | Anytime |
| Weekly Snapshots | Script | Static Mon–Sun archives | Auto-generated |
| Current Priorities | Manual | You write it | Weekly review |

Task lifecycle:
```
Create:   - [ ] ! Task description
Check:    Tasks plugin auto-stamps ✅ YYYY-MM-DD
View:     Appears in MOC "Recently Completed" for 2 days
Age out:  Drops from active MOC after 2 days
Record:   Always in Weekly Outtake (rolling 7 days)
Archive:  Static snapshot in Process/Weekly/ (auto-generated)
```

---

## Weekly Snapshots

The weekly snapshot script runs automatically on vault open and every 4 hours via Shell Commands. It discovers all `Daily/` directories across domain folders (`Life/Daily/`, `Work/*/Daily/`, and legacy `Process/Daily/`) and writes a static report to `Process/Weekly/` for the previous Monday–Sunday.

Output filename format: `YYYY-MM-DD–DD Weekly Outtake.md`

Run manually:
```bash
python3 "$MERIDIAN_VAULT/.scripts/weekly-snapshot.py" "$MERIDIAN_VAULT"
python3 "$MERIDIAN_VAULT/.scripts/weekly-snapshot.py" "$MERIDIAN_VAULT" --dry-run
python3 "$MERIDIAN_VAULT/.scripts/weekly-snapshot.py" "$MERIDIAN_VAULT" --date 2026-03-10
python3 "$MERIDIAN_VAULT/.scripts/weekly-snapshot.py" "$MERIDIAN_VAULT" --force
```

---

## Managing Companies

Run **New Company** from the command palette (or `new-company.sh`) when you start a new job or add a client. The script prompts for company name, checks for collisions, and creates the standard folder structure under `Work/`.

```bash
bash "$MERIDIAN_VAULT/.scripts/new-company.sh" --vault "$MERIDIAN_VAULT"
```

Created folders:

```
Work/[Company]/
  Daily/
  Drafts/
  Finances/
  General/
  Goals/
  Incidents/
  Knowledge/
    Technical/
    Leadership/
    Industry/
  Meetings/
    1on1s/
    Series/
    Single/
  People/
  Projects/
  Reference/
  Vendors/
```

`Goals/Current Priorities.md` is seeded automatically. The daily notes config is updated to point to the new company's `Daily/` folder. Run **New Project** afterward to add a project under the new company's `Projects/` folder.

---

## Managing Projects

Run **New Project** from the command palette (or `new-project.sh`) when starting a new project. It scaffolds the standard project structure under any `Projects/` directory — either `Work/[Company]/Projects/` or `Life/Projects/`.

```bash
bash "$MERIDIAN_VAULT/.scripts/new-project.sh" --vault "$MERIDIAN_VAULT"
```

The script prompts for project name and target Projects directory, then creates:

```
[ProjectName]/
  [ProjectName].md        ← project MOC (scoped Tasks + Dataview queries)
  Design/
    architecture.md
    design-decisions.md
    security.md
  Requirements/
    brd.md
    user-guide.md
    roadmap.md
  Prompts/
    scratch.md
```

All files are seeded with frontmatter (`title`, `created`, `modified`) and starter structure. The MOC queries are scoped to the project folder using vault-relative paths — the same convention the Process MOCs use for `/Daily/`.

The script warns if the Projects directory you provide doesn't match the expected vault conventions (`Work/[Company]/Projects/` or `Life/Projects/`) and prompts for confirmation before proceeding.

---

## Managing Meetings

Meridian has three types of meeting notes — series instances, 1:1 rolling notes, and standalone single notes — and three scripts to manage them. All are available from the Obsidian command palette via Shell Commands and can also be run directly from a terminal.

### Meeting series and instances

Run **New Meeting Series** from the command palette (or `new-meeting-series.sh`) when scheduling a recurring meeting — the first time for a new series, or any time you need to prep an instance of an existing one.

```bash
bash "$MERIDIAN_VAULT/.scripts/new-meeting-series.sh" --vault "$MERIDIAN_VAULT"
```

The script prompts for series name and date, then creates or updates:
- `Meetings/Series/[Series]/[Series].md` — series index (first run only; prompts for purpose and cadence)
- `Meetings/Series/[Series]/YYYY-MM-DD/[Series] YYYY-MM-DD.md` — per-date instance note

If the instance folder already exists, the script aborts without modifying any files.

### 1:1 notes

Run **New 1:1** from the command palette (or `new-1on1.sh`) to create or update a running 1:1 note for a person.

```bash
bash "$MERIDIAN_VAULT/.scripts/new-1on1.sh" --vault "$MERIDIAN_VAULT"
```

The script prompts for the person's name and meeting date, then:
- **First run for a person:** creates `Meetings/1on1s/[Name] 1on1s.md` with a header and the first dated entry
- **Subsequent runs:** appends a new dated entry to the bottom of the existing note

Unlike meeting-series instances (one file per date), a 1:1 note is a single rolling document per person. Each meeting adds an `## YYYY-MM-DD` section with Agenda and Notes fields. Open the note before the meeting to fill in the agenda; add notes during or after.

### Standalone meeting notes

Run **New Meeting** from the command palette (or `new-standalone-meeting.sh`) for any meeting that warrants its own record but is not a recurring series or 1:1.

```bash
bash "$MERIDIAN_VAULT/.scripts/new-standalone-meeting.sh" --vault "$MERIDIAN_VAULT"
```

The script creates a single note in `Meetings/Single/`. Use `--folder` for meetings where you expect prep materials or artifacts to be co-located:

```bash
bash "$MERIDIAN_VAULT/.scripts/new-standalone-meeting.sh" --vault "$MERIDIAN_VAULT" --name "Budget Review" --folder
```

No series index is created. The note links back to the daily note for the meeting date.

### Why not use the Templates plugin for meeting notes?

The meeting templates in `_templates/` use placeholders like `{{NAME}}` and `{{SERIES}}` that the core Templates plugin does not substitute (it only handles `{{date}}`, `{{time}}`, and `{{title}}`). Inserting them via `Cmd+Shift+T` into a new note also creates an H1 conflict with the heading that Filename Heading Sync adds automatically. The shell scripts bypass both problems by creating the file directly with the correct content and frontmatter.

---

## Filing Heuristics

| Question | Destination |
|----------|-------------|
| Would I care about this at a different company? | `Knowledge/` |
| Is it specific to my current company? | `Work/Reference/` |
| Is it someone else's artifact? | `Knowledge/References/` |
| Is it about a colleague? | `Work/People/` |
| Is it a personal relationship? | `Life/People/` |
| Is it an active scoped effort? | `Work` or `Life/Projects/` |
| Is it incident-related? | `Work/Incidents/` |
| Is it vendor or contract related? | `Work/Vendors/` |
| Not sure? | Leave in Daily, mark `>>` |

Work/People → Life/People migration: when you or a colleague leaves the company, move their note from `Work/People/` to `Life/People/`. Backlinks update automatically.

---

## Maintenance

### If title stops populating on new notes

Increase the delay in Front Matter Timestamps by 50ms increments until it stabilizes. This chain is timing-dependent and may need adjustment after plugin updates.

### If a MOC shows a query error

Check that the query uses `sort by filename reverse` (Tasks syntax), not `sort by file.name reverse` (Dataview syntax). These are not interchangeable.

### Python not found

Use the full path in the Shell Commands entry: `/usr/bin/python3`

---

## Documentation

The full documentation suite is copied into `Process/Meridian Documentation/` in your vault when you run the scaffold script. All files are searchable and linkable from inside Obsidian.

| File | Purpose |
|------|---------|
| `User Setup.md` | This file — installation, plugin configuration, and operational reference |
| `User Handbook.md` | Concepts, mindset, and how to use the system day-to-day |
| `Reference Guide.md` | Quick command and convention lookup |
| `Architecture.md` | System structure, data flows, and plugin stack |
| `Design Decision.md` | Design decision log with rationale |
| `Security.md` | Threat model and work/personal boundary |
| `Sync.md` | Syncthing setup and folder sync matrix |
| `Roadmap.md` | Deferred features |
| `Meridian System.pdf` | Printable quick reference |

### Quick Reference PDF

`meridian-system.html` is an HTML source file used to generate the PDF and is not copied to the vault.  It is designed to be printed as one double-sided hardcopy: one side covers conventions and structure (vault layout, markers, filing heuristics, task lifecycle), the other covers daily and weekly workflow.

`Meridian System.pdf` is the formatted print-ready version — open it and print directly.
