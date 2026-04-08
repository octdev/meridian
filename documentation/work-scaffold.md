# Meridian — Work Vault Scaffold Summary

## What the work vault contains

| Folder | Included | Syncthing mode |
|--------|----------|----------------|
| `Process/` | Yes | Send & Receive |
| `Work/CurrentCompany/` | Yes | Send & Receive |
| `_templates/` | Yes | Send & Receive |
| `.scripts/` | Yes | Send & Receive |
| `Knowledge/` | No | Not configured |
| `Northstar/` | No | Not configured |
| `Life/` | No | Not configured |
| `References/` | No | Not configured |

## Work/CurrentCompany/ subfolders

- `Projects/`
- `People/`
- `Reference/`
- `Incidents/`
- `Vendors/`
- `Daily/`
- `Knowledge/Technical/`
- `Knowledge/Leadership/`
- `Knowledge/Industry/`

## Scaffold behavior

The work scaffold is identical to the personal scaffold except it skips:

- `Northstar/` folder and all 7 seed notes (Purpose, Vision, Mission, Principles, Values, Goals, Career)
- `Life/` folder and all subfolders (Projects, People, Health, Finances, Social, Development, Fun)
- `References/` folder

Everything else is created identically:

- `Process/Weekly/`, all 6 MOCs, source tag notes (no `Process/Daily/`)
- `Work/CurrentCompany/` with all standard subfolders, plus `Daily/` and `Knowledge/Technical/`, `Leadership/`, `Industry/`
- `_templates/Daily Note.md`, `Generic Note.md`, `Reflection.md`
- `.scripts/` (for weekly-snapshot.py)
- `.obsidian/daily-notes.json` (points to `Work/CurrentCompany/Daily`) and `templates.json`

## Implementation plan

Add `--profile work` flag to `scaffold-vault.sh`. When set:

- Skip Northstar folder and seed files
- Skip Life folder and subfolders
- Skip References folder
- Generate everything else as normal

The `--vault` and `--profile` flags are independent and composable:

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

Default profile (no flag) generates the full personal vault as today.

## Daily note and MOCs

The daily note and all MOC queries are identical between work and personal vaults. There is only one daily note per day — not separate work and personal notes. On the work machine, the daily note captures work events. On the personal machine (via Syncthing sync), the same note is visible alongside personal vault content.

## Syncthing v1 config for work laptop

| Folder | Mode | Notes |
|--------|------|-------|
| `Process/` | Send & Receive | MOCs, weekly snapshots |
| `Work/` | Send & Receive | All company subfolders including Daily/ and Knowledge/ |
| `Life/` | Not configured | Never present on work machine |
| `Northstar/` | Not configured | Never present on work machine |
| `References/` | Not configured | Never present on work machine |

## Current status

- `--profile work` is documented in `documentation/roadmap.md` as a deferred feature
- Current workaround: run full scaffold, manually delete personal folders, configure Syncthing to exclude them
- Building `--profile work` into `scaffold-vault.sh` is the next development task
