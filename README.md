# Meridian

A personal knowledge management system built on Obsidian. Designed for executives and knowledge workers with back-to-back meeting schedules who need low-friction capture and high-value retrieval.

## Quick Start

**1. Clone the repo:**
```bash
git clone --branch latest --depth 1 https://github.com/your-username/meridian.git
cd meridian
export MERIDIAN_PROJECT="$(pwd)"
```

**2. Personal machine:**
```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh
```
Prompts for a vault path (default: `~/Documents/Meridian`). Creates the full vault including `Northstar/`, `Life/`, and `References/`.

**3. Work machine:**
```bash
$MERIDIAN_PROJECT/src/bin/scaffold-vault.sh --profile work
```
Creates only `Process/` and `Work/`. Personal folders are never created, so personal content cannot exist on the work machine.

The scaffold script will offer to write `MERIDIAN_PROJECT` and `MERIDIAN_VAULT` to your shell profile. After confirming, run `source ~/.zshrc` (or open a new terminal) so the variables are available in every future session.

---

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

- **Marker-based capture** — 8 inline markers (`!`, `!!`, `~`, `>>`, `?`, `&`, `^`, `*`) replace folders and tags for action items, decisions, risks, and insights. See [src/documentation/User Setup.md](src/documentation/User%20Setup.md).
- **Automated MOCs** — 7 Maps of Content powered by Tasks and Dataview query the vault live. See [src/documentation/User Setup.md](src/documentation/User%20Setup.md#mocs).
- **Frontmatter automation** — `title`, `created`, and `modified` fields populate automatically on every note. See [src/documentation/Architecture.md](src/documentation/Architecture.md#frontmatter-chain).
- **Weekly snapshots** — a Python script generates static Mon–Sun completed-task reports automatically. See [src/documentation/User Setup.md](src/documentation/User%20Setup.md#weekly-snapshots).
- **Work machine profile** — `--profile work` scaffolds a work-only vault that omits all personal folders. Personal content is never created and cannot be accidentally synced to an employer machine. See [src/documentation/User Setup.md](src/documentation/User%20Setup.md#work-machine-setup).
- **Sync architecture** — Syncthing enforces the work/personal boundary at the filesystem level across machines. See [src/documentation/Sync.md](src/documentation/Sync.md).
- **Vault management scripts** — `new-company.sh` scaffolds a new employer or client under `Work/`. `new-project.sh` scaffolds a new project with a full MOC, Design, Requirements, and Prompts structure. Both are accessible from the Obsidian command palette.
- **Documentation in vault** — the full documentation suite is copied into `Process/Meridian Documentation/` at scaffold time, including a markdown cheat sheet and the quick-reference PDF.

## Security

Meridian is designed to keep personal knowledge off employer-managed machines. The `--profile work` flag ensures personal folders are never created on the work machine. The Syncthing sync architecture then enforces the same boundary at the network level. See [src/documentation/Security.md](src/documentation/Security.md).

## User Documentation

| File | Purpose |
|------|---------|
| [src/documentation/User Setup.md](src/documentation/User%20Setup.md) | Installation, plugin configuration, and operational reference |
| [src/documentation/User Handbook.md](src/documentation/User%20Handbook.md) | Concepts, mindset, and daily workflow |
| [src/documentation/Reference Guide.md](src/documentation/Reference%20Guide.md) | Quick command and convention lookup |
| [src/documentation/Architecture.md](src/documentation/Architecture.md) | System structure and data flows |
| [src/documentation/Sync.md](src/documentation/Sync.md) | Syncthing setup and migration path |
| [src/documentation/Design Decision.md](src/documentation/Design%20Decision.md) | Design decision log |
| [src/documentation/Security.md](src/documentation/Security.md) | Threat model and sync boundary |
| [src/documentation/Roadmap.md](src/documentation/Roadmap.md) | Deferred features |

All documentation is also available inside the vault at `Process/Meridian Documentation/` after running `scaffold-vault.sh`.

## Keeping Documentation Current

Documentation is updated between releases. To pull the latest version into your vault without changing your code:

```bash
$MERIDIAN_PROJECT/scripts/local/refresh-documentation.sh
```

The script fetches current docs from `origin/main` on GitHub by default, then copies them to the vault. If GitHub is unreachable it falls back to the docs bundled with your installed version. To skip the network fetch entirely:

```bash
$MERIDIAN_PROJECT/scripts/local/refresh-documentation.sh --from-local
```

To review what changed before the vault copy runs:
```bash
git -C "$MERIDIAN_PROJECT" diff src/documentation/
```

To revert to the documentation bundled with your installed version:
```bash
git -C "$MERIDIAN_PROJECT" checkout src/documentation/
```

## Project Documentation

| File | Purpose |
|------|---------|
| [RELEASING.md](RELEASING.md) | Release process: version bumping, migration scripts, validation, and tagging |
| [CLAUDE.md](CLAUDE.md) | Agent working guide: constraints, conventions, and task-specific read lists |
| [docs/next-release.md](docs/next-release.md) | Accumulated migration notes for the next release |
| [docs/work-scaffold.md](docs/work-scaffold.md) | Reference notes for the work profile feature |
