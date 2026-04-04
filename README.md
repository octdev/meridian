# Meridian

A personal knowledge management system built on Obsidian. Designed for executives and knowledge workers with back-to-back meeting schedules who need low-friction capture and high-value retrieval.

## Quick Start

**Personal machine:**
```bash
git clone https://github.com/your-username/meridian.git
cd meridian
src/bin/scaffold-vault.sh
```

**Work machine:**
```bash
src/bin/scaffold-vault.sh --profile work
```

The script prompts for a vault path and defaults to `~/Documents/Meridian`. The `--profile work` flag creates only the folders appropriate for a work machine — `Process/`, `Work/`, and `Knowledge/`. `Northstar/`, `Life/`, and `References/` are never created, so personal content cannot exist on the work machine.

Open Obsidian → "Open folder as vault" → select your vault path.
Then follow `Process/Meridian Documentation/User Setup.md` in the vault from Step 3 (Rename CurrentCompany) onward. See `User Handbook.md` for an introduction to the system's concepts and daily workflow.

## Daily Operation

| Action | Method |
|--------|--------|
| Open today's note | `Cmd+D` |
| Create a new note | `Cmd+N` |
| Open previous daily note | `Cmd+-` |
| Open next daily note | `Cmd+=` |
| Insert Reflection template | `Cmd+Shift+T` |
| Run weekly snapshot manually | Command palette → "Generate Weekly Outtake" |
| Add a new company under Work/ | Command palette → "New Company" |
| Scaffold a new project | Command palette → "New Project" |

## Prerequisites

- [Obsidian](https://obsidian.md) (desktop)
- Python 3 (`brew install python` or system Python 3)
- Bash (macOS built-in)

## Features

- **Marker-based capture** — 8 inline markers (`!`, `!!`, `~`, `>>`, `?`, `&`, `^`, `*`) replace folders and tags for action items, decisions, risks, and insights. See [documentation/User Setup.md](documentation/User%20Setup.md).
- **Automated MOCs** — 7 Maps of Content powered by Tasks and Dataview query the vault live. See [documentation/User Setup.md](documentation/User%20Setup.md#mocs).
- **Frontmatter automation** — `title`, `created`, and `modified` fields populate automatically on every note. See [documentation/Architecture.md](documentation/Architecture.md#frontmatter-chain).
- **Weekly snapshots** — a Python script generates static Mon–Sun completed-task reports automatically. See [documentation/User Setup.md](documentation/User%20Setup.md#weekly-snapshots).
- **Work machine profile** — `--profile work` scaffolds a work-only vault that omits all personal folders. Personal content is never created and cannot be accidentally synced to an employer machine. See [documentation/User Setup.md](documentation/User%20Setup.md#work-machine-setup).
- **Sync architecture** — Syncthing enforces the work/personal boundary at the filesystem level across machines. See [documentation/Sync.md](documentation/Sync.md).
- **Vault management scripts** — `new-company.sh` scaffolds a new employer or client under `Work/`. `new-project.sh` scaffolds a new project with a full MOC, Design, Requirements, and Prompts structure. Both are accessible from the Obsidian command palette.
- **Documentation in vault** — the full documentation suite is copied into `Process/Meridian Documentation/` at scaffold time, including a markdown cheat sheet and the quick-reference PDF.

## Security

Meridian is designed to keep personal knowledge off employer-managed machines. The `--profile work` flag ensures personal folders are never created on the work machine. The Syncthing sync architecture then enforces the same boundary at the network level. See [documentation/Security.md](documentation/Security.md).

## Documentation

| File | Purpose |
|------|---------|
| [documentation/User Setup.md](documentation/User%20Setup.md) | Installation, plugin configuration, and operational reference |
| [documentation/User Handbook.md](documentation/User%20Handbook.md) | Concepts, mindset, and daily workflow |
| [documentation/Reference Guide.md](documentation/Reference%20Guide.md) | Quick command and convention lookup |
| [documentation/Architecture.md](documentation/Architecture.md) | System structure and data flows |
| [documentation/Sync.md](documentation/Sync.md) | Syncthing setup and migration path |
| [documentation/Design Decision.md](documentation/Design%20Decision.md) | Design decision log |
| [documentation/Security.md](documentation/Security.md) | Threat model and sync boundary |
| [documentation/Roadmap.md](documentation/Roadmap.md) | Deferred features |

All documentation is also available inside the vault at `Process/Meridian Documentation/` after running `scaffold-vault.sh`.
