# Reference Guide

See [user-guide.md](user-guide.md) for full details on any item.

---

## Prerequisites

```bash
brew install python   # Python 3
```

## Scaffold

```bash
chmod +x scaffold-vault.sh
./scaffold-vault.sh --vault /path/to/MyVault
```

## Hotkeys

| Action | Key |
|--------|-----|
| Open today's daily note | `Cmd+D` |
| Open previous daily note | `Cmd+-` |
| Open next daily note | `Cmd+=` |
| New note | `Cmd+N` |
| Save | `Cmd+S` |

## Markers

| Marker | Meaning | Type |
|--------|---------|------|
| `!` | Action item | Checkbox |
| `!!` | Urgent action | Checkbox |
| `~` | Waiting on someone | Checkbox |
| `>>` | Process later | Checkbox |
| `?` | Decision made | Plain bullet |
| `&` | Insight | Plain bullet |
| `^` | Risk / concern | Plain bullet |
| `*` | Feedback | Plain bullet |

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

## Frontmatter Fields

| Field | Populated by | When |
|-------|-------------|------|
| `title` | Linter (YAML Title) | On save |
| `created` | Front Matter Timestamps | On new file creation |
| `modified` | Front Matter Timestamps | On every save |

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

## Vault Structure

```
Northstar/       Purpose · Vision · Mission · Principles · Values · Goals · Career
Process/
  Daily/         one file per day
  Weekly/        auto-generated snapshots
  Active Projects · Action Items · Open Loops · Review Queue
  Weekly Outtake · Current Priorities
Knowledge/       Technical/ · Leadership/ · Industry/ · General/
Work/
  CurrentCompany/
    Projects/ · People/ · Reference/ · Incidents/ · Vendors/
Life/            Projects/ · People/ · Health/ · Finances/ · Social/ · Development/ · Fun/
References/      external artifacts, source material
_templates/      Daily Note.md · Generic Note.md
.scripts/        weekly-snapshot.py
```

## Weekly Snapshot CLI

```bash
python3 .scripts/weekly-snapshot.py <vault>              # previous week
python3 .scripts/weekly-snapshot.py <vault> --dry-run    # preview
python3 .scripts/weekly-snapshot.py <vault> --date DATE  # specific week
python3 .scripts/weekly-snapshot.py <vault> --force      # overwrite
```

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
