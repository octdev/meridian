# User Guide

## Table of Contents

1. [How It Works](#how-it-works)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Work Machine Setup](#work-machine-setup)
5. [Appearance Settings](#appearance-settings)
6. [Files and Links](#files-and-links)
7. [Core Plugins](#core-plugins)
8. [Community Plugins](#community-plugins)
9. [Hotkeys](#hotkeys)
10. [Verification](#verification)
11. [Daily Workflow](#daily-workflow)
12. [Markers and Conventions](#markers-and-conventions)
13. [MOCs](#mocs)
14. [Weekly Snapshots](#weekly-snapshots)
15. [Managing Companies](#managing-companies)
16. [Managing Projects](#managing-projects)
17. [Filing Heuristics](#filing-heuristics)
18. [Maintenance](#maintenance)
19. [Documentation](#documentation)

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

**Personal machine:**
```bash
chmod +x scaffold-vault.sh
./scaffold-vault.sh --vault /path/to/MyVault
```

**Work machine:**
```bash
./scaffold-vault.sh --vault /path/to/WorkVault --profile work
```

The `--profile work` flag creates only the folders appropriate for an employer-managed machine — `Process/`, `Work/`, and `Knowledge/`. `Northstar/`, `Life/`, and `References/` are never created. See [Work Machine Setup](#work-machine-setup) for the full workflow.

Default path is `./vault` if `--vault` is omitted.

The scaffold script automatically copies all three scripts (`weekly-snapshot.py`, `new-company.sh`, `new-project.sh`) into `.scripts/` and copies the full documentation suite into `Process/Meridian Documentation/`, including a markdown cheat sheet and a PDF of the quick reference.

### Step 2: Open the vault in Obsidian

Obsidian → Open folder as vault → select the vault root.

### Step 3: Rename CurrentCompany

In the file explorer, rename `Work/CurrentCompany/` to your actual company name.

---

## Work Machine Setup

Meridian is designed to run on both a personal machine and a work machine simultaneously, with different vault content on each. The `--profile work` flag is the starting point for work machine setup.

### What the work profile includes

| Folder | Personal vault | Work vault |
|--------|---------------|------------|
| `Process/` | Yes | Yes |
| `Work/` | Yes | Yes |
| `Knowledge/` | Yes | Yes |
| `_templates/` | Yes | Yes |
| `.scripts/` | Yes | Yes |
| `Northstar/` | Yes | **No** |
| `Life/` | Yes | **No** |
| `References/` | Yes | **No** |

The three omitted folders are intentionally absent — not excluded by a setting, not gitignored, not hidden. They simply do not exist on the work machine. Syncthing is then configured to never introduce them.

### Work machine scaffold

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

Then follow the standard setup from [Step 1: Run the scaffold script](#initial-setup) → [Appearance Settings](#appearance-settings) onward. The plugin stack, hotkeys, and daily workflow are identical between profiles — the only difference is which folders exist.

### Syncthing configuration for the work machine

| Folder | Mode |
|--------|------|
| `Process/` | Send & Receive |
| `Work/` | Send & Receive |
| `Knowledge/` | Send Only |
| `Life/` | Not configured |
| `Northstar/` | Not configured |
| `References/` | Not configured |

`Knowledge/` is Send Only from the work machine so work-originated knowledge flows to all devices, but personal knowledge notes never reach the work machine. See [sync.md](sync.md) for the full Syncthing setup.

---

## Appearance Settings

Configure these before enabling plugins. Order matters.

1. **Settings → Appearance → Inline title → OFF**
   The H1 heading is the visible title. Inline title duplicates it.

2. **Settings → Appearance → Show tab title bar → ON**
   Shows the tab bar for navigating open notes.

3. **Settings → Editor → Default editing mode → Source mode**
   Required for frontmatter to render as raw YAML. Live Preview collapses the frontmatter block.

4. **Settings → Editor → Properties in document → Source**
   Renders frontmatter as editable YAML inline.
   **Important:** this setting must remain Source. Changing it to Visible breaks the Front Matter Timestamps → Linter chain. If frontmatter stops populating after changing this setting, revert to Source.

---

## Files and Links

Settings → Files and Links

| Setting | Value |
|---------|-------|
| Default location for new notes | Same as current file |
| Default location for new attachments | In the folder specified below |
| Attachment folder path | `References` |
| Confirm file deletion | OFF |

---

## Core Plugins

### Daily Notes

Settings → Core Plugins → Daily Notes → ON

| Setting | Value |
|---------|-------|
| Date format | `YYYY-MM-DD` |
| New file location | `Process/Daily` |
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
4. **Output** tab → **Ignore**
5. Set alias: "Generate Weekly Outtake"

If Python 3 is not in PATH, use the full path: `/usr/bin/python3`

#### Command 2: New Company (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-company.sh"`
3. No events — palette access only
4. Set alias: "New Company"

#### Command 3: New Project (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-project.sh"`
3. No events — palette access only
4. Set alias: "New Project"

**Note:** `new-company.sh` and `new-project.sh` require interactive terminal input and do not work reliably from the Obsidian command palette. Run them from a system terminal opened to the vault directory:
```bash
bash .scripts/new-company.sh
bash .scripts/new-project.sh
```
The palette entries serve as a reminder that the commands exist.

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

## Verification

Work through these checks after setup.

1. Press `Cmd+D` — a note should appear in `Process/Daily/YYYY-MM-DD.md` (today's date) with the template populated and `created`/`modified` timestamps filled in.
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

The weekly snapshot script runs automatically on vault open and every 4 hours via Shell Commands. It scans `Process/Daily/` for the previous Monday–Sunday and writes a static report to `Process/Weekly/`.

Output filename format: `YYYY-MM-DD–DD Weekly Outtake.md`

Run manually:
```bash
python3 .scripts/weekly-snapshot.py /path/to/vault
python3 .scripts/weekly-snapshot.py /path/to/vault --dry-run
python3 .scripts/weekly-snapshot.py /path/to/vault --date 2026-03-10
python3 .scripts/weekly-snapshot.py /path/to/vault --force
```

---

## Managing Companies

Run `new-company.sh` when you start a new job or add a client. It creates the standard folder structure under `Work/`.

Run from the command palette (**New Company**) or from a terminal in the vault directory:

```bash
bash .scripts/new-company.sh
```

The script prompts for vault root and company name, checks for collisions, and creates:

```
Work/[Company]/
  Incidents/
  People/
  Projects/
  Reference/
  Vendors/
```

No content files are seeded — notes are added individually as work begins. Run `new-project.sh` afterward to add a project under the new company's `Projects/` folder.

---

## Managing Projects

Run `new-project.sh` when starting a new project. It scaffolds the standard project structure under any `Projects/` directory — either `Work/[Company]/Projects/` or `Life/Projects/`.

Run from the command palette (**New Project**) or from a terminal in the vault directory:

```bash
bash .scripts/new-project.sh
```

The script prompts for project name, vault root, and target Projects directory, then creates:

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

All files are seeded with frontmatter (`title`, `created`, `modified`) and starter structure. The MOC queries are scoped to the project folder using vault-relative paths — the same convention the Process MOCs use for `Process/Daily`.

The script warns if the Projects directory you provide doesn't match the expected vault conventions (`Work/[Company]/Projects/` or `Life/Projects/`) and prompts for confirmation before proceeding.

---

## Filing Heuristics

| Question | Destination |
|----------|-------------|
| Would I care about this at a different company? | `Knowledge/` |
| Is it specific to my current company? | `Work/Reference/` |
| Is it someone else's artifact? | `References/` |
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
| `user-guide.md` | This file — full setup and operational manual |
| `reference-guide.md` | Quick command and convention lookup |
| `cheat-sheet.md` | Condensed quick reference (see below) |
| `architecture.md` | System structure, data flows, and plugin stack |
| `design-decisions.md` | Design decision log with rationale |
| `security.md` | Threat model and work/personal boundary |
| `sync.md` | Syncthing setup and folder sync matrix |
| `roadmap.md` | Deferred features |
| `Meridian System.pdf` | Printable quick reference |

### Cheat Sheet

`meridian-system.html` is an HTML source file used to generate the PDF and is not copied to the vault.  It is designed to be printed as one double-sided hardcopy: one side covers conventions and structure (vault layout, markers, filing heuristics, task lifecycle), the other covers daily and weekly workflow.

`Meridian System.pdf` is the formatted print-ready version — open it and print directly.

`cheat-sheet.md` is the markdown version.  It is not as dense and is less suitable for printing.
