# reference-guide.md — additions

---

## Vault Structure changes

Under `Work/CurrentCompany/`, add to both personal and work vault listings:

```
Meetings/
  1on1s/                    [Name] 1on1s.md — rolling notes, one per person
  [Series]/                 one folder per recurring meeting series
    [Series].md             series index — purpose, cadence, attendees, instance list
    YYYY-MM-DD/             one folder per meeting instance
      [Series] YYYY-MM-DD.md   instance index note
      [prep and artifact files]
```

---

## Meeting Instance Note Structure

```
---
title:
created:
modified:
---

# [Series] YYYY-MM-DD

## Purpose

## Attendees

## Agenda

## Key Points

## Decisions
- ?

## Action Items
- [ ] !

## Next Meeting

---
*Series:* [[Series Name]]
*Daily note:* [[YYYY-MM-DD]]
```

---

## 1:1 Rolling Note Structure

```
---
title:
created:
modified:
---

# [Name] 1:1s

*People note:* [[Name]]

---

## YYYY-MM-DD
**Agenda:**

**Notes:**
```

Each meeting appends a new `## YYYY-MM-DD` section. Never split the file.

---

## Meeting Taxonomy — Decision Rules

| Meeting type | Where output goes |
|---|---|
| Recurring series with artifacts | `Meetings/[Series]/[Date]/` |
| Project-related meeting | `Projects/[Project]/` |
| 1:1 with ongoing tracking | `Meetings/1on1s/[Name] 1on1s.md` |
| Tasks + bullets only | Daily note only |
| No notes needed | — |

---

## Linking Conventions — Meetings

| From | Link | To |
|---|---|---|
| Daily note | `[[Series YYYY-MM-DD]]` | Instance index |
| Instance index | `[[Series Name]]` | Series index |
| Instance index | `[[YYYY-MM-DD]]` | Daily note |
| Series index | `[[Series YYYY-MM-DD]]` | Each instance index |
| 1:1 rolling note | `[[Name]]` | People note |
| People note | `[[Name 1on1s]]` | 1:1 rolling note |

---

## Hotkeys / Palette — addition

| Action | Trigger |
|---|---|
| New Meeting Series | Command palette: **New Meeting Series** |

---

## Vault Management Scripts — addition

```bash
bash .scripts/new-meeting-series.sh --vault <path>
# Interactive: prompts for series name and date
# Creates series index (if new) and instance folder + index note
# Idempotent — aborts if instance already exists
```

Flags:
```bash
--vault   path to vault (required, or prompted)
--series  series name (optional, or prompted)
--date    YYYY-MM-DD (optional, defaults to today)
```

---

## Filing Heuristics — additions

| Question | Destination |
|---|---|
| Recurring meeting with artifacts? | `Meetings/[Series]/[Date]/` |
| Meeting primarily about a project? | `Projects/[Project]/` |
| 1:1 with a tracked person? | `Meetings/1on1s/[Name] 1on1s.md` |
| Formal HR document (PIP, promotion)? | `Work/People/[Name]/` |
