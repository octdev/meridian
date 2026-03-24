# Meridian

A personal knowledge management system built on Obsidian. Designed for executives and knowledge workers with back-to-back meeting schedules who need low-friction capture and high-value retrieval.

## Quick Start

```bash
git clone https://github.com/your-username/meridian.git
cd meridian
chmod +x scaffold-vault.sh
./scaffold-vault.sh --vault ~/Documents/MyVault
```

Open Obsidian → "Open folder as vault" → select the path you provided.
Then follow [documentation/user-guide.md](documentation/user-guide.md) from Step 4 onward.

## Daily Operation

| Action | Method |
|--------|--------|
| Open today's note | `Cmd+D` |
| Create a new note | `Cmd+N` |
| Open previous daily note | `Cmd+-` |
| Open next daily note | `Cmd+=` |
| Run weekly snapshot manually | Command palette → "Generate Weekly Outtake" |

## Prerequisites

- [Obsidian](https://obsidian.md) (desktop)
- Python 3 (`brew install python` or system Python 3)
- Bash (macOS built-in)

## Features

- **Marker-based capture** — 8 inline markers (`!`, `!!`, `~`, `>>`, `?`, `&`, `^`, `*`) replace folders and tags for action items, decisions, risks, and insights. See [documentation/user-guide.md](documentation/user-guide.md).
- **Automated MOCs** — 7 Maps of Content powered by Tasks and Dataview query the vault live. See [documentation/user-guide.md](documentation/user-guide.md#mocs).
- **Frontmatter automation** — `title`, `created`, and `modified` fields populate automatically on every note. See [documentation/architecture.md](documentation/architecture.md#frontmatter-chain).
- **Weekly snapshots** — a Python script generates static Mon–Sun completed-task reports automatically. See [documentation/user-guide.md](documentation/user-guide.md#weekly-snapshots).
- **Sync architecture** — Syncthing separates work and personal content across machines. See [documentation/sync.md](documentation/sync.md).

## Security

Meridian is designed to keep personal knowledge off employer-managed machines. The sync architecture enforces this boundary at the filesystem level. See [documentation/security.md](documentation/security.md).

## Documentation

| File | Purpose |
|------|---------|
| [documentation/user-guide.md](documentation/user-guide.md) | Full setup and operational manual |
| [documentation/reference-guide.md](documentation/reference-guide.md) | Quick command and convention lookup |
| [documentation/architecture.md](documentation/architecture.md) | System structure and data flows |
| [documentation/sync.md](documentation/sync.md) | Syncthing setup and migration path |
| [documentation/design-decisions.md](documentation/design-decisions.md) | Design decision log |
| [documentation/security.md](documentation/security.md) | Threat model and sync boundary |
| [documentation/roadmap.md](documentation/roadmap.md) | Deferred features |
