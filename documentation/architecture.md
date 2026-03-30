# Architecture

## Conceptual Model

Meridian has three layers:

```
┌─────────────────────────────────────────────────────┐
│  Retrieval layer                                     │
│  MOCs (Tasks + Dataview queries), weekly snapshots   │
├─────────────────────────────────────────────────────┤
│  Capture layer                                       │
│  Daily notes + inline markers                        │
├─────────────────────────────────────────────────────┤
│  Knowledge layer                                     │
│  Northstar, Knowledge, Work, Life, References        │
└─────────────────────────────────────────────────────┘
```

The daily note is the only capture surface for incoming events. Intentional work goes directly into the knowledge layer. MOCs query the capture layer live. The snapshot script archives it weekly.

---

## Repository Structure

```
meridian/
  README.md                       repo landing page and quick start
  scaffold-vault.sh               vault scaffolding script (personal + work profiles)
  meridian-system.html            printable 2-sided quick reference (source for PDF)
  Meridian System.pdf             quick reference PDF
  .gitignore
  scripts/
    weekly-snapshot.py            weekly task report generator
    new-company.sh                scaffolds a new employer/client under Work/
    new-project.sh                scaffolds a new project under any Projects/ folder
  vault-files/                    reference copies of vault seed files
    templates/
      Daily Note.md
      Generic Note.md
      Reflection.md               end-of-day reflection template
    mocs/
      Action Items.md
      Active Projects.md
      Open Loops.md
      Review Queue.md
      Weekly Outtake.md
      Current Priorities.md
    northstar/
      Purpose.md  Vision.md  Mission.md
      Principles.md  Values.md  Goals.md  Career.md
  documentation/
    user-setup.md
    user-handbook.md
    reference-guide.md
    cheat-sheet.md                markdown version of the quick reference
    architecture.md               this file
    design-decisions.md
    security.md
    sync.md
    roadmap.md
```

The `scripts/` directory contains all runnable scripts. `scaffold-vault.sh` copies them into the vault's `.scripts/` directory at setup time. The `documentation/` directory contains all user-facing docs — these are also copied into the vault at `Process/Meridian Documentation/` with frontmatter injected. The vault itself is not committed to this repo.

---

## Scaffold Profiles

The scaffold script supports two profiles via `--profile personal|work`.

### Personal profile (default)

Full vault. All folders and seed files are created.

```bash
./scaffold-vault.sh --vault ~/Documents/MyVault
```

### Work profile

Work-only vault. Creates `Process/`, `Work/`, `Knowledge/`, `_templates/`, and `.scripts/`. Omits `Northstar/`, `Life/`, and `References/` entirely — they are never written to disk and cannot be accidentally synced to an employer machine.

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

The daily note template, all MOCs, and the Reflection template are identical between profiles. The plugin stack, hotkeys, and workflow are the same. Only the knowledge layer folders differ.

---

## Vault Structure (generated)

### Personal vault

```
vault/
  .obsidian/
    daily-notes.json
    templates.json
  .scripts/
    weekly-snapshot.py
    new-company.sh
    new-project.sh
  _templates/
    Daily Note.md
    Generic Note.md
    Reflection.md
  Northstar/
    Purpose.md  Vision.md  Mission.md
    Principles.md  Values.md  Goals.md  Career.md
  Process/
    Daily/                        YYYY-MM-DD.md files
    Weekly/                       YYYY-MM-DD–DD Weekly Outtake.md files
    Drafts/                       default location for new notes
    Active Projects.md            Dataview MOC
    Action Items.md               Tasks MOC
    Open Loops.md                 Tasks MOC
    Review Queue.md               Tasks MOC
    Weekly Outtake.md             Tasks MOC (rolling 7-day)
    Current Priorities.md         Manual MOC
    email.md                      source tag note
    teams.md                      source tag note
    Meridian Documentation/
      user-setup.md
      user-handbook.md
      reference-guide.md
      cheat-sheet.md
      architecture.md
      design-decisions.md
      security.md
      sync.md
      roadmap.md
      Meridian System.pdf
  Knowledge/
    Technical/  Leadership/  Industry/  General/
  Work/
    CurrentCompany/
      Projects/  People/  Reference/  Incidents/  Vendors/
      Goals/  Finances/  General/
  Life/
    Projects/  People/  Health/  Finances/
    Social/  Development/  Fun/  General/
  References/
```

### Work vault (`--profile work`)

```
vault/
  .obsidian/
    daily-notes.json
    templates.json
  .scripts/
    weekly-snapshot.py
    new-company.sh
    new-project.sh
  _templates/
    Daily Note.md
    Generic Note.md
    Reflection.md
  Process/
    Daily/                        YYYY-MM-DD.md files
    Weekly/                       YYYY-MM-DD–DD Weekly Outtake.md files
    Drafts/                       default location for new notes
    Active Projects.md            Dataview MOC
    Action Items.md               Tasks MOC
    Open Loops.md                 Tasks MOC
    Review Queue.md               Tasks MOC
    Weekly Outtake.md             Tasks MOC (rolling 7-day)
    Current Priorities.md         Manual MOC
    email.md                      source tag note
    teams.md                      source tag note
    Meridian Documentation/       (same docs as personal vault)
  Knowledge/
    Technical/  Leadership/  Industry/  General/
  Work/
    CurrentCompany/
      Projects/  People/  Reference/  Incidents/  Vendors/
      Goals/  Finances/  General/
```

`Northstar/`, `Life/`, and `References/` are absent — not excluded, not hidden. They do not exist. `Process/Meridian Documentation/` is present in both profiles.

---

## Plugin Stack

| # | Plugin | Type | Category | Role |
|---|--------|------|----------|------|
| 1 | Daily Notes | Core | Automation | Auto-creates daily capture surface |
| 2 | Templates | Core | Automation | Populates daily note from template |
| 3 | Tasks | Community | MOCs | Task lifecycle, completion stamps, queries |
| 4 | Dataview | Community | MOCs | Powers Active Projects MOC |
| 5 | Filename Heading Sync | Community | Frontmatter | Keeps filename and H1 in sync (bidirectional) |
| 6 | Linter | Community | Frontmatter | Writes `title` frontmatter from H1 on save |
| 7 | Front Matter Timestamps | Community | Frontmatter | Auto-inserts and maintains `created` and `modified` |
| 8 | Scroller | Community | UX | Moves cursor to bottom of note on open and title rename |
| 9 | Shell Commands | Community | Automation | Triggers weekly snapshot; palette entries for new-company and new-project |

---

## Frontmatter Chain

Every new note triggers this sequence automatically:

```
Cmd+N or new note icon
          │
          ▼
Obsidian creates blank note
          │
          ▼
Front Matter Timestamps fires (after 100ms delay)
  → inserts created: and modified:
  → executes "Save current file"
          │
          ▼
Save triggers Linter
  → Insert YAML Attributes adds title: if missing
  → YAML Title populates title: from H1
  → Add Blank Line After YAML ensures clean formatting
          │
          ▼
Save triggers Filename Heading Sync
  → H1 and filename sync bidirectionally
          │
          ▼
Scroller moves cursor to bottom of note
```

The 100ms delay in Front Matter Timestamps is a timing dependency, not an event-driven trigger. If the title stops populating after plugin updates, increase the delay in 50ms increments.

---

## Data Flows

### Task lifecycle

```
Daily note → Tasks query (MOC) → completion stamp → Recently Completed view
          → ages out of MOC after 2 days
          → Weekly Outtake MOC (rolling 7 days)
          → weekly-snapshot.py → Process/Weekly/ static archive
```

### Weekly snapshot script

The script runs on vault open and every 4 hours via Shell Commands. It scans `Process/Daily/` for the previous Monday–Sunday, extracts completed tasks by marker category, and writes a static Markdown report. It is idempotent — it exits immediately if the output file already exists. Use `--force` to regenerate.

### Sync data flow (v1)

```
Work laptop ──Syncthing──► Personal machine ──iCloud──► Phone
  Process/: Send & Receive   Send & Receive              full vault
  Work/:    Send & Receive
  Knowledge/: Send Only
  (Life/, Northstar/, References/ not configured on work laptop)
```

See [sync.md](sync.md) for full configuration.

---

## Key Specifications

### Frontmatter schema (all notes)

```yaml
---
title:      string — note title, synced with H1 and filename
created:    YYYY-MM-DD HH:mm:ss — set once on creation
modified:   YYYY-MM-DD HH:mm:ss — updated on every save
---
```

### Tasks query syntax note

Tasks plugin uses its own query language. `sort by filename reverse` is correct. `sort by file.name` is Dataview syntax and causes a query error in Tasks blocks.

### Daily note filename format

`YYYY-MM-DD.md` — ISO 8601 date. Sorting by filename gives chronological order.

### Weekly snapshot filename format

Same-month week: `YYYY-MM-DD–DD Weekly Outtake.md` (e.g. `2026-03-02–08 Weekly Outtake.md`)
Cross-month week: `YYYY-MM-DD–MM-DD Weekly Outtake.md`
