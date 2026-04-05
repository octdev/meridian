# Epic: Contextual Vault Segmentation

## Goal

Restructure Meridian's capture layer and knowledge layer so that content is owned by the domain it belongs to, the Process layer becomes a pure aggregation surface, and work vault deployments never receive personal knowledge or personal daily capture — by structure, not by sync policy.

---

## Description

Meridian's current architecture conflates capture and aggregation in `Process/`, and treats `Knowledge/` as a single portable tree that is sent to work machines via a Send Only sync policy. As vaults mature and work deployments are created for new employers, this creates two problems:

1. A well-established personal vault would bulk-deliver years of accumulated general knowledge to a new work machine on first sync — including content with personal overlap.
2. The `Process/Daily/` location implies daily notes belong to the process layer, when they are actually content generated in the context of a specific life domain (personal life or a specific employer).

This epic moves daily capture into the domain folders where it belongs, elevates `Process/` to a pure retrieval layer, scopes work knowledge to the employer that generated it, and removes `Knowledge/` from the work vault profile entirely. The result is a cleaner architectural boundary, a more honest sync model, and a vault structure where the folder path communicates the content's context before you open it.

---

## Architectural Changes

### 1. Daily notes move into domain folders

| Current | New |
|---|---|
| `Process/Daily/YYYY-MM-DD.md` | `Life/Daily/YYYY-MM-DD.md` (personal vault) |
| `Process/Daily/YYYY-MM-DD.md` | `Work/CurrentCompany/Daily/YYYY-MM-DD.md` (work vault) |

`Process/Daily/` is removed from both vault profiles. `Process/` becomes a pure aggregation layer containing only MOCs, weekly snapshots, drafts, and documentation.

The Obsidian Daily Notes plugin is configured at scaffold time to point to the correct path per profile. `Cmd+D` routes to `Life/Daily/` on personal vaults and `Work/CurrentCompany/Daily/` on work vaults.

### 2. Process/ becomes a pure aggregation layer

`Process/` retains:
- MOC files (Action Items, Open Loops, Review Queue, Weekly Outtake, Active Projects, Current Priorities)
- `Weekly/` snapshot archive
- `Drafts/`
- `Meridian Documentation/`
- Source tag notes (`email.md`, `teams.md`)

`Process/` loses:
- `Daily/` — moved to domain folders as above

### 3. Work-scoped knowledge replaces the shared Knowledge/ tree on work vaults

| Current | New |
|---|---|
| `Knowledge/Technical/` (synced to work vault) | `Work/CurrentCompany/Knowledge/Technical/` |
| `Knowledge/Leadership/` (synced to work vault) | `Work/CurrentCompany/Knowledge/Leadership/` |
| `Knowledge/Industry/` (synced to work vault) | `Work/CurrentCompany/Knowledge/Industry/` |
| `Knowledge/General/` (synced to work vault) | Removed from work vault entirely |

The personal vault retains `Knowledge/` as-is. The work vault profile does not include a top-level `Knowledge/` folder. Knowledge generated at work lives under the company folder. Promotion to the personal `Knowledge/` tree is a deliberate, manual act — the user decides what is genuinely transferable.

Extraction of personal knowledge into a work vault for a specific project is a manual copy or reference, never a sync relationship.

### 4. Sync model simplification

The Send Only configuration for `Knowledge/` from the work laptop is removed. The work vault no longer has a top-level `Knowledge/` folder to sync. `Work/CurrentCompany/Knowledge/` syncs bidirectionally as part of the `Work/` subtree, which is already bidirectional.

The personal `Knowledge/` tree is never on the work machine. The boundary is structural.

---

## Acceptance Criteria

### Vault structure

- [ ] Personal vault contains `Life/Daily/` as the daily note location; `Process/Daily/` does not exist
- [ ] Work vault contains `Work/CurrentCompany/Daily/` as the daily note location; `Process/Daily/` does not exist
- [ ] Work vault contains `Work/CurrentCompany/Knowledge/Technical/`, `Leadership/`, `Industry/`; no top-level `Knowledge/` folder exists in the work vault profile
- [ ] Personal vault retains top-level `Knowledge/Technical/`, `Leadership/`, `Industry/`, `General/` unchanged
- [ ] `Process/` in both profiles contains only MOCs, `Weekly/`, `Drafts/`, `Meridian Documentation/`, and source tag notes

### Obsidian configuration

- [ ] Daily Notes plugin `new file location` is set to `Life/Daily` in personal vault `.obsidian/daily-notes.json`
- [ ] Daily Notes plugin `new file location` is set to `Work/CurrentCompany/Daily` in work vault `.obsidian/daily-notes.json`
- [ ] Daily Notes plugin `new file location` is updated by `new-company.sh` when a new company is scaffolded, reflecting the new company folder path
- [ ] `Cmd+D` opens today's note in the correct location for each profile

### Scripts

- [ ] `scaffold-vault.sh` creates `Life/Daily/` for personal profile; `Work/CurrentCompany/Daily/` for work profile; does not create `Process/Daily/` for either
- [ ] `scaffold-vault.sh` creates `Work/CurrentCompany/Knowledge/Technical/`, `Leadership/`, `Industry/` for work profile
- [ ] `scaffold-vault.sh` does not create a top-level `Knowledge/` folder for the work profile
- [ ] `new-company.sh` creates `Daily/` and `Knowledge/Technical/`, `Leadership/`, `Industry/` under the new company folder
- [ ] `weekly-snapshot.py` scans `Life/Daily/` on personal vault; `Work/CurrentCompany/Daily/` on work vault; produces correct weekly archive in both cases
- [ ] `weekly-snapshot.py` resolves the correct daily path at runtime rather than relying on a hardcoded path — either via a config file, a vault profile flag, or by detecting which daily folder exists
- [ ] All MOC query paths updated to reflect new daily note locations

### Sync

- [ ] Sync matrix updated: `Knowledge/` Send Only row removed; `Work/` bidirectional row implicitly covers `Work/CurrentCompany/Knowledge/`
- [ ] Personal `Knowledge/` is absent from work vault sync configuration entirely
- [ ] `Sync.md` updated to reflect new matrix

### Documentation

- [ ] `Architecture.md` — vault structure diagrams updated for both profiles; data flows updated; conceptual model description updated to reflect Process as pure aggregation layer
- [ ] `User Handbook.md` — Knowledge section updated to describe work-scoped knowledge and promotion workflow; Daily note section updated to reflect domain-scoped locations; Work section updated to describe `Work/CurrentCompany/Knowledge/`
- [ ] `User Setup.md` — daily note plugin configuration updated for both profiles; Syncthing setup updated
- [ ] `Design Decision.md` — new DD entries for: daily notes in domain folders (supersedes implicit Process/Daily assumption), work-scoped knowledge, Process as pure aggregation layer
- [ ] `Sync.md` — sync matrix updated; Knowledge Send Only configuration removed; work knowledge sync described as part of Work/ bidirectional

---

## Files Changed

### Scripts
- `src/bin/scaffold-vault.sh`
- `src/bin/new-company.sh`
- `src/bin/weekly-snapshot.py`

### Templates / config
- `src/templates/obsidian-templates/daily-note.md` — frontmatter and any path-relative links reviewed
- `.obsidian/daily-notes.json` — generated path per profile

### MOC templates
- `src/templates/mocs/action-items.md`
- `src/templates/mocs/open-loops.md`
- `src/templates/mocs/review-queue.md`
- `src/templates/mocs/weekly-outtake.md`

### Documentation
- `documentation/Architecture.md`
- `documentation/User Handbook.md`
- `documentation/User Setup.md`
- `documentation/Design Decision.md`
- `documentation/Sync.md`

---

## Open Questions

- **Shell Commands plugin entries** — the palette entries for `new-company.sh`, `new-project.sh`, and `new-meeting-series.sh` are configured in `.obsidian/` and written at scaffold time. If Shell Commands plugin config embeds any path assumptions about `Process/Daily/`, those need to be updated. Needs verification during implementation.
- **`weekly-snapshot.py` company folder resolution** — on the work vault, the script needs to know which company folder is current (i.e. `Work/CurrentCompany/`). The current script likely hardcodes or infers this. The resolution mechanism needs to be explicit, especially after a `new-company.sh` run changes the active company path.
- **Dataview Active Projects MOC** — currently queries for project folders. Path assumptions should be verified; the move of Daily out of Process should not affect it, but worth confirming no implicit `Process/` path dependency exists.
- **`Reference Guide.md`** — not listed in Files Changed. If it contains filing heuristics that reference `Process/Daily/` or `Knowledge/` as a work vault destination, it needs updating. Needs a pass.

---

## Out of Scope

- Changes to `new-project.sh` or `new-meeting-series.sh` — unaffected by this restructure
- Changes to the Northstar, Life subfolder structure, or References — unchanged
- Any change to the personal vault's top-level `Knowledge/` tree — unchanged
- Migration tooling for existing vaults — deferred; tracked separately if needed
