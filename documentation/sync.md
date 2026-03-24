# Sync Architecture

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

---

## Folder Sync Matrix

| Folder | Work laptop | Personal machine | Phone |
|--------|-------------|------------------|-------|
| `Process/` | Send & Receive | Send & Receive | Send & Receive (iCloud) |
| `Work/` | Send & Receive | Send & Receive | Send & Receive (iCloud) |
| `Knowledge/` | Send Only | Send & Receive | Send & Receive (iCloud) |
| `Life/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `Northstar/` | Not synced | Send & Receive | Send & Receive (iCloud) |
| `References/` | Not synced | Send & Receive | Send & Receive (iCloud) |

Knowledge/ is Send Only from the work laptop. Work-originated knowledge flows to all devices. Personal/phone-originated knowledge stays between personal machine and phone. The enforcement is at the sync layer — no discipline required.

---

## Syncthing Setup

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

For each folder in the sync matrix above:

1. On the personal machine: Add Folder → set path to the vault subfolder → share with work laptop device
2. On the work laptop: accept the folder share → set the folder type per the matrix

Folder type settings in Syncthing:
- **Send & Receive** — bidirectional (default)
- **Send Only** — pushes changes out, ignores incoming
- **Receive Only** — accepts incoming, never pushes back

### Conflict handling

Syncthing appends `.sync-conflict-YYYYMMDD-HHMMSS-DEVICEID` to conflicting files. Obsidian surfaces these as separate notes. Resolution rule:
- `Process/Daily/` — keep most recent version
- `Work/` — work laptop wins
- `Knowledge/` — personal machine wins (work laptop is Send Only, so conflicts should not occur)

---

## V2 Architecture (NAS, deferred)

See [roadmap.md](roadmap.md) for the NAS migration plan using TrueNAS + Syncthing container + Nextcloud.

---

## Security Boundary

The sync configuration enforces the personal/work boundary. See [security.md](security.md) for the threat model.
