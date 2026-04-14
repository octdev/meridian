# Sync

## Overview

Meridian has two distinct sync scenarios with different tools and scope:

1. **Work ↔ Personal** — Syncthing syncs your active company folder between work laptop and personal machine. This enforces the work/personal boundary at the filesystem level.

2. **Personal across devices** — Your full personal vault syncs across personal machines, phone, and tablet. [Yaos](https://yaos.dev) is the recommended approach; Syncthing is an alternative for laptop/desktop/NAS scenarios.

---

## Work ↔ Personal Sync (Syncthing)

#### What syncs

Only your active company folder syncs between the work laptop and personal machine. Both vaults have `Work/<Company>/` at the same relative path — Syncthing keeps them in sync bidirectionally.

| Folder | Work laptop | Personal machine |
|--------|-------------|-----------------|
| `Work/<Company>/` | Send & Receive | Send & Receive |
| `Process/` | Not synced | Not synced |
| `Knowledge/` | Not present | Not in this share |
| `Life/` | Not present | Not in this share |
| `Northstar/` | Not present | Not in this share |
| `Knowledge/` (top-level) | Not present | Not in this share |

`Work/<Company>/` includes all subfolders: `Daily/`, `Knowledge/`, `Goals/`, `Projects/`, `People/`, `Meetings/`, and the rest. Everything under the company folder travels as one Syncthing share — no per-subfolder configuration needed.

`Process/` is not synced. Its contents (MOCs, weekly snapshots, Meridian documentation) are either rebuilt locally from vault content or refreshed on upgrade. Nothing in `Process/` requires cross-machine sync.

#### Prerequisites

The work laptop vault must be scaffolded with `--profile work` before configuring Syncthing:

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

This ensures `Northstar/`, `Life/`, and the top-level `Knowledge/` do not exist on the work machine — there is nothing to accidentally sync. See [User Setup.md](User%20Setup.md#work-machine-setup) for the full work machine setup sequence.

#### Install

**macOS (both machines):**
```bash
brew install syncthing
brew services start syncthing
```

Open the Syncthing web UI: http://127.0.0.1:8384

#### Pair devices

1. On the work laptop: Actions → Show ID → copy the Device ID
2. On the personal machine: Add Remote Device → paste the ID
3. Accept the connection request on the work laptop

#### Configure the folder share

Configure one folder share for `Work/<Company>/`:

1. On the personal machine: Add Folder → set path to `~/path/to/vault/Work/AcmeCorp/` → share with work laptop device
2. On the work laptop: accept the folder share → verify the path resolves to `Work/AcmeCorp/` inside the work vault → set type to Send & Receive

Configure at the company folder level, not the `Work/` parent. If your personal machine has multiple company folders from previous jobs, only the active company syncs. Previous employer folders are historical records and do not need to be shared.

#### Conflict handling

Syncthing appends `.sync-conflict-YYYYMMDD-HHMMSS-DEVICEID` to conflicting files. Obsidian surfaces these as separate notes. Resolution rule:
- `Work/<Company>/Daily/` — keep most recent version
- Everything else under `Work/<Company>/` — work laptop wins

---

## Personal Vault Across Devices

For syncing your full personal vault across personal machines, phone, and tablet. Yaos is recommended for any setup involving mobile devices.

#### Option A: Yaos (recommended)

[Yaos](https://yaos.dev) is a self-hosted, real-time sync solution for Obsidian built on Cloudflare Workers. It uses CRDTs (Conflict-free Replicated Data Types) — a class of data structure that merges changes without conflicts. There are no `.sync-conflict` files, no manual resolution, no sync delays.

| Property | Value |
|----------|-------|
| Platforms | macOS, Windows, Linux, iOS, Android |
| Hosting | Your own Cloudflare account (no central servers) |
| Cost | Free within Cloudflare free tier (100,000 requests/day) |
| Setup | Under 60 seconds — deploys as a Cloudflare Worker |

Yaos is the recommended approach for personal vault sync because it handles mobile cleanly, which neither Syncthing nor iCloud does reliably for Obsidian. Setup instructions are at [yaos.dev](https://yaos.dev).

#### Option B: Syncthing

Syncthing works well for laptop-to-laptop and laptop-to-NAS scenarios. For personal device sync, configure a single share for the vault root — no folder-level access control is needed since all personal devices are trusted.

1. On the primary personal machine: Add Folder → set path to vault root → share with other personal devices
2. On each target device: accept the share → set type to Send & Receive

**Note:** Syncthing does not have a reliable iOS client. For any setup involving iPhone or iPad, use Yaos instead.

#### Option C: iCloud (legacy fallback)

iCloud syncs the full vault to iPhone via the Obsidian mobile app. It requires no configuration beyond placing the vault in an iCloud-synced directory on macOS.

iCloud offers no folder-level sync control, no conflict resolution strategy, and can be slow to propagate changes. Use Yaos in preference to iCloud for any setup where sync reliability matters.

---

## Full Device Matrix

| Folder | Work laptop | Personal laptop | Phone / Tablet |
|--------|-------------|-----------------|----------------|
| `Work/<Company>/` | Send & Receive (Syncthing) | Send & Receive (Syncthing) | Via personal vault sync |
| `Knowledge/` | Not present | Personal vault sync | Via personal vault sync |
| `Life/` | Not present | Personal vault sync | Via personal vault sync |
| `Northstar/` | Not present | Personal vault sync | Via personal vault sync |
| `Knowledge/References/` | Not present | Personal vault sync | Via personal vault sync |
| `Process/` | Not synced | Not synced | Via personal vault sync |

The work laptop participates only in the Work↔Personal Syncthing share. Personal vault sync (Yaos or Syncthing) runs between personal devices only and is independent of the work machine.

---

## V2 Architecture (NAS, deferred)

See [Roadmap.md](Roadmap.md) for the NAS migration plan using TrueNAS + Syncthing container.

---

## Security Boundary

The sync configuration enforces the personal/work boundary. See [Security.md](Security.md) for the threat model.
