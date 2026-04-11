# Meridian — Work Vault Reference

## What the work vault contains

| Folder | Included | Syncthing |
|--------|----------|-----------|
| `Process/` | Yes | Not synced |
| `Work/CurrentCompany/` | Yes | Send & Receive |
| `_templates/` | Yes | Not synced |
| `.scripts/` | Yes | Not synced |
| `Knowledge/` | No | Not configured |
| `Northstar/` | No | Not configured |
| `Life/` | No | Not configured |
| `References/` | No | Not configured |

`Process/` contains only query-based MOCs, generated weekly snapshots, and Meridian documentation — all rebuilt locally or refreshed on upgrade. It is not synced between machines.

## Work/CurrentCompany/ subfolders

- `Projects/`
- `People/`
- `Reference/`
- `Incidents/`
- `Vendors/`
- `Goals/` — contains `Current Priorities.md`
- `Finances/`
- `General/`
- `Daily/`
- `Drafts/`
- `Knowledge/Technical/`
- `Knowledge/Leadership/`
- `Knowledge/Industry/`
- `Meetings/`
- `Meetings/1on1s/`

## Scaffold behavior

The work scaffold is identical to the personal scaffold except it omits:

- `Northstar/` and all 7 seed notes (Purpose, Vision, Mission, Principles, Values, Goals, Career)
- `Life/` and all subfolders (Projects, People, Health, Finances, Social, Development, Fun, Daily, Drafts)
- `References/`
- Top-level `Knowledge/` (work knowledge lives at `Work/<Company>/Knowledge/`)

Everything else is created identically:

- `Process/Weekly/`, all 5 Process MOCs (Active Projects, Action Items, Open Loops, Review Queue, Weekly Outtake), source tag notes
- `Work/CurrentCompany/` with all standard subfolders including `Goals/Current Priorities.md`
- `_templates/` (Daily Note, Generic Note, Reflection, Meeting Instance, Meeting Series, 1on1)
- `.scripts/` (weekly-snapshot.py, new-company.sh, new-project.sh, new-meeting-series.sh)
- `.obsidian/daily-notes.json` (points to `Work/CurrentCompany/Daily`), `app.json`, `templates.json`

## Syncthing config for work laptop

Only `Work/` is synced between the work laptop and personal machine. `Process/` is not synced — its contents are either query-driven (MOCs), generated from vault content (weekly snapshots), or managed by Meridian releases (documentation).

| Folder | Mode | Notes |
|--------|------|-------|
| `Work/` | Send & Receive | All company subfolders including Daily/, Knowledge/, Goals/ |
| `Life/` | Not configured | Never present on work machine |
| `Northstar/` | Not configured | Never present on work machine |
| `References/` | Not configured | Never present on work machine |

See `src/documentation/Sync.md` for full setup instructions.
