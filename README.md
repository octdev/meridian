# Meridian

A personal knowledge management system built on Obsidian. Designed for executives and knowledge workers with back-to-back meeting schedules who need low-friction capture and high-value retrieval.

## Quick Start

**Personal machine:**
```bash
git clone https://github.com/your-username/meridian.git
cd meridian
chmod +x scaffold-vault.sh
./scaffold-vault.sh --vault ~/Documents/MyVault
```

**Work machine:**
```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

The `--profile work` flag creates only the folders appropriate for a work machine — `Process/`, `Work/`, and `Knowledge/`. `Northstar/`, `Life/`, and `References/` are never created, so personal content cannot exist on the work machine.

Open Obsidian → "Open folder as vault" → select the path you provided.
Then follow `Process/Meridian Documentation/user-guide.md` in the vault from Step 3 (Rename CurrentCompany) onward.

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

- **Marker-based capture** — 8 inline markers (`!`, `!!`, `~`, `>>`, `?`, `&`, `^`, `*`) replace folders and tags for action items, decisions, risks, and insights. See [documentation/user-guide.md](documentation/user-guide.md).
- **Automated MOCs** — 7 Maps of Content powered by Tasks and Dataview query the vault live. See [documentation/user-guide.md](documentation/user-guide.md#mocs).
- **Frontmatter automation** — `title`, `created`, and `modified` fields populate automatically on every note. See [documentation/architecture.md](documentation/architecture.md#frontmatter-chain).
- **Weekly snapshots** — a Python script generates static Mon–Sun completed-task reports automatically. See [documentation/user-guide.md](documentation/user-guide.md#weekly-snapshots).
- **Work machine profile** — `--profile work` scaffolds a work-only vault that omits all personal folders. Personal content is never created and cannot be accidentally synced to an employer machine. See [documentation/user-guide.md](documentation/user-guide.md#work-machine-setup).
- **Sync architecture** — Syncthing enforces the work/personal boundary at the filesystem level across machines. See [documentation/sync.md](documentation/sync.md).
- **Vault management scripts** — `new-company.sh` scaffolds a new employer or client under `Work/`. `new-project.sh` scaffolds a new project with a full MOC, Design, Requirements, and Prompts structure. Both are accessible from the Obsidian command palette.
- **Documentation in vault** — the full documentation suite is copied into `Process/Meridian Documentation/` at scaffold time, including a markdown cheat sheet and the quick-reference PDF.

## Security

Meridian is designed to keep personal knowledge off employer-managed machines. The `--profile work` flag ensures personal folders are never created on the work machine. The Syncthing sync architecture then enforces the same boundary at the network level. See [documentation/security.md](documentation/security.md).

## Documentation

| File | Purpose |
|------|---------|
| [documentation/user-guide.md](documentation/user-guide.md) | Full setup and operational manual |
| [documentation/reference-guide.md](documentation/reference-guide.md) | Quick command and convention lookup |
| [documentation/cheat-sheet.md](documentation/cheat-sheet.md) | Markdown quick reference (also copied to vault) |
| [documentation/architecture.md](documentation/architecture.md) | System structure and data flows |
| [documentation/sync.md](documentation/sync.md) | Syncthing setup and migration path |
| [documentation/design-decisions.md](documentation/design-decisions.md) | Design decision log |
| [documentation/security.md](documentation/security.md) | Threat model and sync boundary |
| [documentation/roadmap.md](documentation/roadmap.md) | Deferred features |

All documentation is also available inside the vault at `Process/Meridian Documentation/` after running `scaffold-vault.sh`.
