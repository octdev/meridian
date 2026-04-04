# architecture.md — additions and changes

---

## Repository Structure changes

Under `src/bin/`, add:

```
new-meeting-series.sh       scaffolds a meeting series instance (and series index if new)
```

Under `src/templates/obsidian-templates/`, add:

```
meeting-instance.md         per-date instance index note
meeting-series.md           series-level index note
1on1.md                     rolling 1:1 note
```

---

## Vault Structure changes — both profiles

Under `Work/CurrentCompany/`, add:

```
Meetings/
  1on1s/                    rolling 1:1 notes, one file per direct report or tracked peer
  [Series Name]/            one folder per recurring meeting series (created by new-meeting-series.sh)
    [Series Name].md        series index note — purpose, cadence, standing attendees, instance list
    YYYY-MM-DD/             one folder per instance (created by new-meeting-series.sh)
      [Series] YYYY-MM-DD.md   instance index note — the canonical record for that meeting
      [prep and artifact files co-located here]
```

The `Meetings/` folder is created by `scaffold-vault.sh` and `new-company.sh`. Series folders and instance folders are created by `new-meeting-series.sh` — they are never pre-created.

---

## Plugin Stack — no changes

No new plugins required. The Meetings layer uses standard Obsidian wikilinks, the existing frontmatter chain, and the existing Shell Commands palette.

---

## Frontmatter schema — no changes

Meeting instance notes and 1:1 rolling notes use the standard three-field frontmatter (`title`, `created`, `modified`). No new fields are introduced.

---

## Meetings layer design

### Meeting taxonomy

Not all meetings generate files. The decision rule:

| Meeting type | Output |
|---|---|
| Artifact-generating recurring meeting | `Meetings/[Series]/[Date]/` folder + instance index note |
| Project-related meeting | Note filed under `Projects/[Project]/`, not under Meetings |
| 1:1 with ongoing tracking | Rolling note appended in `Meetings/1on1s/` |
| Daily-note-sufficient meeting | Timestamped `###` heading in daily note only |
| No notes required | Nothing |

### Series index vs. instance index

The **series index** (`Meetings/[Series]/[Series].md`) is the permanent record of what the meeting is: its purpose, cadence, standing attendees, and format. It lists every instance as a wikilink. It is created once by `new-meeting-series.sh` on first use.

The **instance index** (`Meetings/[Series]/[Date]/[Series] [Date].md`) is the canonical record of a single meeting: what was discussed, decided, and assigned. All prep materials and output artifacts are co-located in the same date folder and linked from this note.

### Rolling 1:1 notes

A rolling 1:1 note is a single file per person, located at `Meetings/1on1s/[Name] 1on1s.md`. Each meeting appends a new `## YYYY-MM-DD` section. The file is never split. This keeps the full relationship history in one searchable document.

The 1:1 rolling note links to the People note (`Work/CurrentCompany/People/[Name].md`). The People note links back. They serve different purposes: the People note captures who the person is; the 1:1 note captures your working history together.

### Linking model

```
Daily note (YYYY-MM-DD)
  └─ [[Series YYYY-MM-DD]]          reference on meeting day

Instance index (Series YYYY-MM-DD)
  └─ [[Series]]                     up-link to series index
  └─ [[YYYY-MM-DD]]                 back-link to daily note
  └─ prep file links                co-located artifacts

Series index (Series)
  └─ [[Series YYYY-MM-DD]]          one entry per instance

1:1 rolling note (Name 1on1s)
  └─ [[Name]]                       link to People note

People note (Name)
  └─ [[Name 1on1s]]                 link to 1:1 rolling note
```

### Action items from meetings

Action items captured in an instance index use standard Meridian task markers (`- [ ] !`, `- [ ] !!`). They surface in the Action Items MOC automatically. For MOC pickup to work, the instance index must be saved after task entry — the Tasks plugin scans all vault files.

Optionally, significant action items may also be copied to the daily note on meeting day to ensure they are visible in the daily capture flow. The instance index is canonical; the daily note entry is a convenience copy.
