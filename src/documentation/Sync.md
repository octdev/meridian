# Sync

## Overview

Meridian separates work and personal content across machines using Syncthing. The boundary is enforced at the filesystem level — personal content never touches the work machine.

---

## V1 Architecture (current)

```
Work laptop ──Syncthing──► Personal machine ──iCloud──► Phone
```

- Syncthing handles work ↔ personal machine sync with folder-level access control
- iCloud handles personal machine ↔ phone sync
- The phone is not part of the Syncthing mesh

The work laptop is scaffolded with `--profile work`, which means `Northstar/`, `Life/`, and `References/` are never created there. Syncthing is then configured to match: those folders are absent from the work laptop's sync configuration entirely.

---

## Folder Sync Matrix

| Folder | Work laptop | Personal machine | Phone |
|--------|-------------|------------------|-------|
| `Work/` | Send & Receive | Send & Receive | Send & Receive (iCloud) |
| `Knowledge/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `Life/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `Northstar/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `References/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `Process/` | Not synced | Not synced | Send & Receive (iCloud) |

`Work/` is Send & Receive and includes `Work/<Company>/Daily/`, `Work/<Company>/Knowledge/`, and `Work/<Company>/Goals/` (which contains `Current Priorities.md`). Work-originated knowledge and priorities sync bidirectionally as part of `Work/` — there is no separate Syncthing entry for any subfolder.

`Process/` contains only query-based MOCs, generated weekly snapshots, and Meridian documentation — all of which are either rebuilt locally from vault content or refreshed on upgrade. It is not synced between machines.

---

## Syncthing Setup

### Prerequisites

The work laptop vault must be scaffolded with `--profile work` before configuring Syncthing:

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

This ensures `Northstar/`, `Life/`, and `References/` do not exist on the work machine before Syncthing is configured. See [User Setup.md](User%20Setup.md#work-machine-setup) for the full work machine setup sequence.

### Install

**macOS (both machines):**
```bash
brew install syncthing
brew services start syncthing
```

Open the Syncthing web UI: http://127.0.0.1:8384

### Pair devices

1. On the work laptop, copy the Device ID from Actions → Show ID
2. On the personal machine, go to Add Remote Device → paste the ID
3. Accept the connection request on the work laptop

### Configure folders

Only `Work/` is synced between the work laptop and personal machine. Configure it as a single folder share:

1. On the personal machine: Add Folder → set path to `Work/` → share with work laptop device
2. On the work laptop: accept the folder share → set type to Send & Receive

Folder type settings in Syncthing:
- **Send & Receive** — bidirectional (default)
- **Send Only** — pushes changes out, ignores incoming
- **Receive Only** — accepts incoming, never pushes back

### Conflict handling

Syncthing appends `.sync-conflict-YYYYMMDD-HHMMSS-DEVICEID` to conflicting files. Obsidian surfaces these as separate notes. Resolution rule:
- `Work/<Company>/Daily/` — keep most recent version
- `Work/` (other folders) — work laptop wins

---

## V2 Architecture (NAS, deferred)

See [Roadmap.md](Roadmap.md) for the NAS migration plan using TrueNAS + Syncthing container + Nextcloud.

---

## Security Boundary

The sync configuration enforces the personal/work boundary. See [Security.md](Security.md) for the threat model.
