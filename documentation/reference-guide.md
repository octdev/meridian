# Reference Guide

See [user-setup.md](user-setup.md) for installation and configuration details. See [user-handbook.md](user-handbook.md) for concepts and daily workflow.

---

## Vault Structure

**Personal vault:**
```
Northstar/       Purpose · Vision · Mission · Principles · Values · Goals · Career
Process/
  Daily/         one file per day
  Weekly/        auto-generated snapshots
  Active Projects · Action Items · Open Loops · Review Queue
  Weekly Outtake · Current Priorities
  Meridian Documentation/   user-guide · reference-guide · architecture
                            design-decisions · security · sync · roadmap · PDF
Knowledge/       Technical/ · Leadership/ · Industry/ · General/
Work/
  CurrentCompany/
    Projects/ · People/ · Reference/ · Incidents/ · Vendors/
Life/            Projects/ · People/ · Health/ · Finances/ · Social/ · Development/ · Fun/
References/      external artifacts, source material
_templates/      Daily Note.md · Generic Note.md · Reflection.md
.scripts/        weekly-snapshot.py · new-company.sh · new-project.sh
```

**Work vault (`--profile work`) — Northstar, Life, References absent:**
```
Process/
  Daily/         one file per day
  Weekly/        auto-generated snapshots
  Active Projects · Action Items · Open Loops · Review Queue
  Weekly Outtake · Current Priorities
  Meridian Documentation/   (same as personal vault)
Knowledge/       Technical/ · Leadership/ · Industry/ · General/
Work/
  CurrentCompany/
    Projects/ · People/ · Reference/ · Incidents/ · Vendors/
_templates/      Daily Note.md · Generic Note.md · Reflection.md
.scripts/        weekly-snapshot.py · new-company.sh · new-project.sh
```

---

## Daily Note Structure

```
---
title:
created:
modified:
---

# YYYY-MM-DD

## Top 3 Goals
1.
2.
3.

## Log

  ### HH:MM — Meeting Title
  - [ ] ! Action item [[source]]
  - ? Decision made
  - [[Person Name]] observation
```

---

## Frontmatter Fields

| Field | Populated by | When |
|-------|-------------|------|
| `title` | Linter (YAML Title) | On save |
| `created` | Front Matter Timestamps | On new file creation |
| `modified` | Front Matter Timestamps | On every save |

---

## Markers

| Marker | Meaning | Type | Shows in MOC |
|--------|---------|------|--------------|
| `!` | Action item | Checkbox | Action Items (Standard) |
| `!!` | Urgent action | Checkbox | Action Items (Urgent) |
| `~` | Waiting on someone | Checkbox | Open Loops |
| `>>` | Process later | Checkbox | Review Queue |
| `?` | Decision made | Plain bullet | — (searchable) |
| `&` | Insight / realization | Plain bullet | — (searchable) |
| `^` | Risk / concern | Plain bullet | — (searchable) |
| `*` | Feedback given/received | Plain bullet | — (searchable) |

**Key rule:** Markers go at the start of a bullet, after the checkbox if present. Actionable items (`!` `!!` `~` `>>`) use checkboxes. Observations (`?` `&` `^` `*`) are plain bullets.

---

## Links, Source Tags, and Status

**Links:**

| Syntax | Use |
|--------|-----|
| `[[First Last]]` | Person |
| `[[Project Name]]` | Project |
| `[[Topic]]` | Knowledge topic |
| `[[email]]` | Originated from email |
| `[[teams]]` | Originated from Teams |

**Due dates** — only when there is a real deadline:
```
- [ ] !! Ship v2 API {{2026-03-15}}
```

**Status tags:**

| Tag | Meaning |
|-----|---------|
| `#open` | Unresolved |
| `#done` | Resolved |
| `#cancelled` | No longer relevant |

---

## Task Lifecycle

```
Create:  - [ ] ! Task description
Check:   Tasks auto-stamps ✅ YYYY-MM-DD
View:    MOC "Recently Completed" for 2 days
Age:     Drops from active MOC after 2 days
Record:  Always in Weekly Outtake (rolling 7 days)
Archive: Static snapshot in Process/Weekly/
```

---

## The Seven MOCs

| MOC | Engine | Pulls From | When to Check |
|-----|--------|------------|---------------|
| Active Projects | Dataview | Work + Life Projects folders | Weekly review |
| Action Items | Tasks | `!` and `!!` markers | Daily + weekly |
| Open Loops | Tasks | `~` markers | Weekly review |
| Review Queue | Tasks | `>>` markers | Weekly review |
| Weekly Outtake | Tasks | All completed (rolling 7 days) | Anytime |
| Weekly Snapshots | Script | Static Mon–Sun archives | Auto-generated |
| Current Priorities | Manual | You write it | Weekly review |

---

## Hotkeys

| Action | Key |
|--------|-----|
| Open today's daily note | `Cmd+D` |
| Open previous daily note | `Cmd+-` |
| Open next daily note | `Cmd+=` |
| New note | `Cmd+N` |
| Save | `Cmd+S` |
| Insert Reflection template | `Cmd+Shift+T` |

---

## Morning Triage (~2 min)

1. Open today's daily note via `Cmd+D` — located at `Process/Daily/YYYY-MM-DD.md`
2. Glance at calendar → drop meeting headings into Log section
3. Fill in **Top 3 Goals**
4. First comms sweep — scan email + Teams, capture actionable items with markers

## Throughout the Day

**In meetings:** Capture under time-stamped `###` headings. Use markers inline — don't organize. Link people: `[[First Last]]`. Link projects: `[[Project Name]]`.

**Between meetings:** Comms items → inline bullets with source tags. Prefix interruptions: `— [[teams]]` or `— [[email]]`. Intentional work → write directly in Knowledge, Work, or Life (not the daily note).

> **The core rule:** Things that *happen to you* go in the daily note. Things you *intentionally create* go directly where they belong.

## End of Day (~5 min)

1. Final comms sweep — catch anything that came in late
2. Quick scan: any `!!` urgent items missed?
3. Optional: insert Reflection template (`Cmd+Shift+T`) for structured end-of-day notes

## Weekly Review (~15–20 min)

1. **Weekly Outtake** — scan what shipped. Note patterns, wins, gaps.
2. **Action Items MOC** — anything overdue or stale? Close it or re-date it.
3. **Open Loops MOC** — follow up or mark done.
4. **Review Queue MOC** — process `>>` items: promote to Knowledge/Work/Life or check off.
5. **Current Priorities** — update if anything shifted.
6. Scan the week's daily notes for `&` insights worth promoting to Knowledge.

---

## Guiding Principles

- **Capture fast, file later.** If unsure where it goes, mark `>>` and move on.
- **Links over tags.** Use `[[wikilinks]]` for people, projects, topics.
- **Don't create notes preemptively.** Let structure emerge from real content.
- **MOCs emerge naturally.** When you have enough notes on a topic, create an entry point then.

---

## Filing Heuristics

| Question | Destination |
|----------|-------------|
| Care across companies? | `Knowledge/` |
| Someone else's artifact? | `References/` |
| About a colleague? | `Work/People/` |
| Personal relationship? | `Life/People/` |
| Active scoped effort? | `*/Projects/` |
| Incident-related? | `Work/Incidents/` |
| Vendor / contract? | `Work/Vendors/` |
| Not sure? | Daily note, mark `>>` |

---

## Scaffold

**Personal machine (full vault):**
```bash
chmod +x scaffold-vault.sh
./scaffold-vault.sh --vault /path/to/MyVault
```

**Work machine (work vault — omits Northstar, Life, References):**
```bash
./scaffold-vault.sh --vault /path/to/WorkVault --profile work
```

The scaffold script automatically copies all scripts into `.scripts/` and all documentation into `Process/Meridian Documentation/`.

## Vault Management Scripts

```bash
bash .scripts/new-company.sh   # add a new employer/client under Work/
bash .scripts/new-project.sh   # scaffold a new project under any Projects/ folder
```

Or invoke from the Obsidian command palette: **New Company**, **New Project**.

## Weekly Snapshot CLI

The weekly snapshot runs automatically every Monday via the Shell Commands plugin. These flags are available if you need to trigger or inspect it manually:

```bash
python3 .scripts/weekly-snapshot.py <vault>              # previous week
python3 .scripts/weekly-snapshot.py <vault> --dry-run    # preview without writing
python3 .scripts/weekly-snapshot.py <vault> --date DATE  # specific week
python3 .scripts/weekly-snapshot.py <vault> --force      # overwrite existing snapshot
```

---

## Plugins

| # | Plugin | Type | Category | Role |
|---|--------|------|----------|------|
| 1 | Daily Notes | Core | Automation | Auto-creates daily capture surface |
| 2 | Templates | Core | Automation | Populates daily note from template |
| 3 | Tasks | Community | MOCs | Task lifecycle, completion stamps, queries |
| 4 | Dataview | Community | MOCs | Powers Active Projects MOC |
| 5 | Filename Heading Sync | Community | Frontmatter | Keeps filename and H1 in sync |
| 6 | Linter | Community | Frontmatter | Writes `title` from H1 on save |
| 7 | Front Matter Timestamps | Community | Frontmatter | Auto-inserts `created` and `modified` |
| 8 | Scroller | Community | UX | Cursor to bottom on open/rename |
| 9 | Shell Commands | Community | Automation | Triggers weekly snapshot |
