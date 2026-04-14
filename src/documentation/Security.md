# Security

## Threat Model

Meridian is a personal knowledge system that spans employer-managed and personally-owned machines. The primary security concern is personal information exposure to an employer.

#### In scope

- Personal notes (Life/, Northstar/) appearing on a work machine
- Personal notes syncing to employer-accessible cloud storage
- Work machine filesystem scans revealing personal content

#### Out of scope

- Vault encryption at rest (Obsidian does not provide this natively)
- Protection against a compromised personal machine
- Network-level interception of sync traffic

---

## Defense Layers

#### Layer 1: Work profile scaffold (primary)

The `--profile work` flag ensures personal folders are never created on the work machine:

```bash
./scaffold-vault.sh --vault ~/Documents/WorkVault --profile work
```

`Northstar/` and `Life/` are structurally absent — not excluded, not hidden, not gitignored. They do not exist on disk. The top-level `Knowledge/` folder is also absent; work-generated knowledge lives at `Work/<Company>/Knowledge/`. This is the strongest guarantee: content that was never written cannot be exposed.

#### Layer 2: Syncthing folder-level access control

The sync configuration ensures `Life/`, `Northstar/`, and the top-level `Knowledge/` are never configured as sync targets on the work machine. Because these folders do not exist on the work machine (Layer 1), they cannot appear in its Syncthing folder list.

Work-originated knowledge lives at `Work/<Company>/Knowledge/` and syncs bidirectionally as part of the `Work/<Company>/` share. The top-level `Knowledge/` folder is personal-only and is never created on the work machine.

Only `Work/<Company>/` syncs bidirectionally — this is the expected work-accessible content. `Process/` is not synced between machines.

See [Sync.md](Sync.md) for the full folder sync matrix.

#### Layer 3: Personal device sync is outside the Syncthing mesh

Personal machine to phone/tablet sync (via Yaos or iCloud) is entirely outside the Syncthing mesh. The work laptop has no configuration for personal device sync and is not a peer in that topology.

#### Layer 4: No vault on employer cloud storage

The vault is never stored in employer-managed cloud storage (OneDrive, SharePoint, Google Workspace managed accounts). Syncthing is peer-to-peer with no cloud intermediary.

---

## Accepted Tradeoffs

| Risk | Mitigation | Residual risk | Future path |
|------|------------|---------------|-------------|
| Work machine is employer-controlled — anything on it is potentially visible | Keep personal folders off the work machine via `--profile work` scaffold + Syncthing config | Work content (Process/, Work/) is on an employer machine | Accept — this is the expected state |
| Syncthing misconfiguration could expose personal folders | `--profile work` means folders don't exist to misconfigure; document the matrix explicitly | Human error creating personal folders manually on work machine | Automated config verification script (see Roadmap.md) |
| Vault is not encrypted at rest | Physical machine security | Low for typical threat model | Full-disk encryption on both machines mitigates this outside Obsidian |

---

## Security Checklist

Before using on a new work machine, verify:

- [ ] Vault was scaffolded with `--profile work` — confirm `Northstar/`, `Life/`, and top-level `Knowledge/` are absent
- [ ] `Life/`, `Northstar/`, and top-level `Knowledge/` are not present in Syncthing folder list on work laptop
- [ ] Vault is stored in a personally-owned storage location, not employer cloud storage
- [ ] Full-disk encryption is enabled on both machines (FileVault on macOS)
