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
  meridian-system.html            printable 2-sided quick reference (source for PDF)
  Meridian System.pdf             quick reference PDF
  .gitattributes
  .gitignore
  src/
    bin/
      scaffold-vault.sh           vault scaffolding script (personal + work profiles)
      new-company.sh              scaffolds a new employer/client under Work/
      new-project.sh              scaffolds a new project under any Projects/ folder
      new-meeting-series.sh       scaffolds a meeting series instance (and series index if new)
      weekly-snapshot.py          weekly task report generator
    lib/
      colors.sh                   TTY-aware color variable definitions
      logging.sh                  output helpers: _pass, _fail, _warn, _hint, _detail, _cmd
      errors.sh                   die function and shared error handling
      vault-select.sh             vault registry, interactive vault selection, company detection
    templates/
      obsidian-templates/
        daily-note.md
        generic-note.md
        reflection.md             end-of-day reflection template
        meeting-instance.md       per-date instance index note
        meeting-series.md         series-level index note
        1on1.md                   rolling 1:1 note
      mocs/
        action-items.md
        active-projects.md
        open-loops.md
        review-queue.md
        weekly-outtake.md
        current-priorities.md
      northstar/
        purpose.md
        vision.md
        mission.md
        principles.md
        values.md
        goals.md
        career.md
    documentation/
      User Setup.md
      User Handbook.md
      Reference Guide.md
      Architecture.md               this file
      Design Decision.md
      Security.md
      Sync.md
      Roadmap.md
      Upgrading.md                  upgrade system: user guide and developer reference
  scripts/
    ci/
      release.sh                  version tagging and README update script
    local/
      backfill-timestamps.sh      populates empty created:/modified: fields in existing vault files
    upgrade/
      upgrade-runner.sh           sourced library: orchestrates vault upgrade chain
      upgrade-to-X.Y.Z.sh         entry point per release (one file per version)
      migrations/
        vX.Y.Z.sh                 migration script per release (one file per version)
  config/
    base/
      version.json                semver source of truth
  docs/
    work-scaffold.md              dev/planning notes for --profile work feature
```

`src/bin/` contains all product scripts. `scaffold-vault.sh` copies them — and the `src/lib/` shared libraries — into the vault's `.scripts/` directory at setup time. `src/templates/` holds vault seed files; filenames are kebab-case in the repo and retain their display-case names when written into the vault. `src/documentation/` contains all user-facing docs — these are copied into the vault at `Process/Meridian Documentation/` with frontmatter injected. `docs/` contains developer and project planning notes that are never distributed to users. The vault itself is not committed to this repo.

`scripts/local/` holds one-off utilities run directly from the repo, not copied to the vault. `backfill-timestamps.sh` is used when migrating an existing vault: it walks all Markdown files and populates any empty `created:` or `modified:` frontmatter fields, leaving existing timestamps untouched.

`scripts/upgrade/` contains the versioned upgrade system. `upgrade-runner.sh` is a sourced library that orchestrates discovery, ordering, and execution of migration scripts. Each release gets one entry point (`upgrade-to-X.Y.Z.sh`) and one migration script (`migrations/vX.Y.Z.sh`). Users run upgrades via `scaffold-vault.sh --upgrade`, which delegates to the appropriate entry point. See `src/documentation/Upgrading.md` for full details.

---

## Version Tracking

Meridian tracks version at two levels: the project repo and each scaffolded vault.

### Project version

Stored in `config/base/version.json` in the repo. This is the authoritative version of the Meridian software itself.

| Field | Format | Purpose |
|---|---|---|
| `semver.major/minor/patch` | `X.Y.Z` | Semantic version |
| `semver.build` | string | Optional build metadata |
| `metadata.releaseDate` | `YYYY-MM-DD` | Release date |
| `metadata.gitCommit` | SHA string | Git commit (`pending` until release) |

### Vault version

Stored in `.scripts/.vault-version` inside each vault. Records which Meridian version scaffolded or last upgraded that vault.

| Key | Example | Purpose |
|---|---|---|
| `vault` | `vault=1.4.0` | Global vault version |
| `DefaultCompany` | `DefaultCompany=AcmeCorp` | Active/default company |
| `<Company>-vault` | `Acme-vault=1.4.0` | Per-company version |

Per-company entries allow independent upgrade tracking when a vault contains multiple company contexts. The default company at scaffold time is `CurrentCompany` — after the user renames it in the filesystem, the `.vault-version` entry retains the original name. There is no mechanism to detect or reconcile a company rename; all entries are flat and equal.

`new-company.sh` appends a new `<Company>-vault=X.Y.Z` entry when a company is added and automatically sets that company as the default. `DefaultCompany=` records the active company and can be updated with `set-default-company.sh`. `resolve_company` uses it as a fallback when `.obsidian/daily-notes.json` is absent or unset.

**Version file format:** key=value pairs. Older vaults stored a plain version string — `upgrade-runner.sh` migrates these automatically on first upgrade.

### Note-level frontmatter

All vault notes carry per-note timestamps, managed by the frontmatter plugin chain (see [Frontmatter Chain](#frontmatter-chain)).

| Field | Format | Purpose |
|---|---|---|
| `title` | string | Note title, synced with H1 and filename |
| `created` | `YYYY-MM-DD HH:mm:ss` | Set once on creation |
| `modified` | `YYYY-MM-DD HH:mm:ss` | Updated on every save |

---

## Scaffold Profiles

The scaffold script supports two profiles via `--profile personal|work`.

### Personal profile (default)

Full vault. All folders and seed files are created.

```bash
src/bin/scaffold-vault.sh --vault ~/Documents/MyVault
```

### Work profile

Work-only vault. Creates `Process/`, `Work/`, `_templates/`, and `.scripts/`. Omits `Northstar/`, `Life/`, `References/`, and the top-level `Knowledge/` entirely — they are never written to disk and cannot be accidentally synced to an employer machine. Knowledge generated at work lives at `Work/<Company>/Knowledge/`.

```bash
src/bin/scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
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
    .vault-version                key=value version file (vault= and Company-vault= entries)
    weekly-snapshot.py
    new-company.sh
    new-project.sh
    new-meeting-series.sh
    lib/
      colors.sh
      logging.sh
      errors.sh
  _templates/
    Daily Note.md
    Generic Note.md
    Reflection.md
    Meeting Instance.md
    Meeting Series.md
    1on1.md
  Northstar/
    Purpose.md
    Vision.md
    Mission.md
    Principles.md
    Values.md
    Goals.md
    Career.md
  Process/
    Weekly/                       YYYY-MM-DD–DD Weekly Outtake.md files
    Active Projects.md            Dataview MOC
    Action Items.md               Tasks MOC
    Open Loops.md                 Tasks MOC
    Review Queue.md               Tasks MOC
    Weekly Outtake.md             Tasks MOC (rolling 7-day)
    email.md                      source tag note
    teams.md                      source tag note
    Meridian Documentation/       Meridian-managed — overwritten on upgrade and refresh
      User Setup.md               do not store personal notes here
      User Handbook.md
      Reference Guide.md
      Architecture.md
      Design Decision.md
      Security.md
      Sync.md
      Roadmap.md
      Upgrading.md
      Meridian System.pdf
  Knowledge/
    Technical/
    Leadership/
    Industry/
    General/
  Work/
    CurrentCompany/
      Projects/
      People/
      Reference/
      Incidents/
      Vendors/
      Goals/
        Current Priorities.md     Manual note
      Finances/
      General/
      Daily/                      YYYY-MM-DD.md files
      Drafts/                     default location for new notes (work vault)
      Knowledge/
        Technical/
        Leadership/
        Industry/
      Meetings/
        1on1s/                    rolling 1:1 notes, one file per direct report or tracked peer
        [Series Name]/            one folder per recurring series (created by new-meeting-series.sh)
          [Series Name].md        series index note
          YYYY-MM-DD/             one folder per instance (created by new-meeting-series.sh)
            [Series] YYYY-MM-DD.md
  Life/
    Daily/                        YYYY-MM-DD.md files
    Drafts/                       default location for new notes (personal vault)
    Projects/
    People/
    Health/
    Finances/
    Social/
    Development/
    Fun/
    General/
  References/
```

### Work vault (`--profile work`)

```
vault/
  .obsidian/
    daily-notes.json
    templates.json
  .scripts/
    .vault-version                key=value version file (vault= and Company-vault= entries)
    weekly-snapshot.py
    new-company.sh
    new-project.sh
    new-meeting-series.sh
    lib/
      colors.sh
      logging.sh
      errors.sh
  _templates/
    Daily Note.md
    Generic Note.md
    Reflection.md
    Meeting Instance.md
    Meeting Series.md
    1on1.md
  Process/
    Weekly/                       YYYY-MM-DD–DD Weekly Outtake.md files
    Active Projects.md            Dataview MOC
    Action Items.md               Tasks MOC
    Open Loops.md                 Tasks MOC
    Review Queue.md               Tasks MOC
    Weekly Outtake.md             Tasks MOC (rolling 7-day)
    email.md                      source tag note
    teams.md                      source tag note
    Meridian Documentation/       (same docs as personal vault, including Upgrading.md)
  Work/
    CurrentCompany/
      Projects/
      People/
      Reference/
      Incidents/
      Vendors/
      Goals/
        Current Priorities.md     Manual note
      Finances/
      General/
      Daily/                      YYYY-MM-DD.md files
      Drafts/                     default location for new notes
      Knowledge/
        Technical/
        Leadership/
        Industry/
      Meetings/
        1on1s/                    rolling 1:1 notes, one file per direct report or tracked peer
        [Series Name]/            one folder per recurring series (created by new-meeting-series.sh)
          [Series Name].md        series index note
          YYYY-MM-DD/             one folder per instance (created by new-meeting-series.sh)
            [Series] YYYY-MM-DD.md
```

`Northstar/`, `Life/`, `References/`, and the top-level `Knowledge/` are absent — not excluded, not hidden. They do not exist. `Process/Meridian Documentation/` is present in both profiles.

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
| 9 | Shell Commands | Community | Automation | Triggers weekly snapshot; palette entries for new-company, new-project, and new-meeting-series |

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

The script runs on vault open and every 4 hours via Shell Commands. It discovers all `Daily/` directories across domain folders (`Life/Daily/`, `Work/*/Daily/`, and legacy `Process/Daily/`), extracts completed tasks by marker category for the previous Monday–Sunday, and writes a static Markdown report. It is idempotent — it exits immediately if the output file already exists. Use `--force` to regenerate.

### Sync data flow (v1)

```
Work laptop ──Syncthing──► Personal machine ──Yaos/iCloud──► Phone/Tablet
  Work/<Co>/: Send & Receive  (includes Daily/, Knowledge/, Goals/, and the rest)
  (Process/, Life/, Northstar/, References/ not configured on work laptop)
```

See [Sync.md](Sync.md) for full configuration.

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

---

## Meetings Layer

### Meeting taxonomy

Not all meetings generate files. The decision rule:

| Meeting type | Output |
|---|---|
| Artifact-generating recurring meeting | `Meetings/[Series]/[Date]/` folder + instance index note |
| Project-related meeting | Note filed under `Projects/[Project]/`, not under Meetings |
| 1:1 with ongoing tracking | Rolling note appended in `Meetings/1on1s/` |
| Daily-note-sufficient meeting | Timestamped `###` heading in daily note only |
| No notes required | Nothing |

### Series index vs. instance index

The **series index** (`Meetings/[Series]/[Series].md`) is the permanent record of what the meeting is: its purpose, cadence, standing attendees, and format. It lists every instance as a wikilink. It is created once by `new-meeting-series.sh` on first use.

The **instance index** (`Meetings/[Series]/[Date]/[Series] [Date].md`) is the canonical record of a single meeting: what was discussed, decided, and assigned. All prep materials and output artifacts are co-located in the same date folder and linked from this note.

### Rolling 1:1 notes

A rolling 1:1 note is a single file per person, located at `Meetings/1on1s/[Name] 1on1s.md`. Each meeting appends a new `## YYYY-MM-DD` section. The file is never split. This keeps the full relationship history in one searchable document.

The 1:1 rolling note links to the People note (`Work/CurrentCompany/People/[Name].md`). The People note links back. They serve different purposes: the People note captures who the person is; the 1:1 note captures your working history together.

### Linking model

```
Daily note (YYYY-MM-DD)
  └─ [[Series YYYY-MM-DD]]          reference on meeting day

Instance index (Series YYYY-MM-DD)
  └─ [[Series]]                     up-link to series index
  └─ [[YYYY-MM-DD]]                 back-link to daily note
  └─ prep file links                co-located artifacts

Series index (Series)
  └─ [[Series YYYY-MM-DD]]          one entry per instance

1:1 rolling note (Name 1on1s)
  └─ [[Name]]                       link to People note

People note (Name)
  └─ [[Name 1on1s]]                 link to 1:1 rolling note
```

### Action items from meetings

Action items captured in an instance index use standard Meridian task markers (`- [ ] !`, `- [ ] !!`). They surface in the Action Items MOC automatically. The Tasks plugin scans all vault files, including files nested inside `Meetings/` — no additional configuration required.
