# Phase 2 — Documentation Spec

**Audience:** Technical writer or developer updating user-facing documentation.
**Depends on:** Phase 1 complete and `docs/phase-1-migration-notes.md` produced.
**Feeds into:** Phase 3 (integration — validation plan references documented behavior).

---

## Context

Meridian is a personal knowledge management system built on Obsidian. See `src/documentation/Architecture.md` for system context and `docs/phase-1-dev-spec.md` for the structural changes implemented in Phase 1.

This phase rewrites `User Handbook.md` and updates all other affected documentation to reflect Phase 1 changes. It does **not** update test scripts, write migration scripts, or bump the version — that is Phase 3.

**Before starting:** read `docs/phase-1-migration-notes.md`. If Phase 1 called out any deviations from its spec, adjust the documentation accordingly. The migration notes are the authoritative record of what was actually built.

---

## Summary of Structural Changes (from Phase 1)

These are the vault layout changes your documentation must reflect:

| What changed | Before | After |
|---|---|---|
| References location | `References/` (top-level) | `Knowledge/References/` |
| Series meeting path | `Meetings/[Series]/` | `Meetings/Series/[Series]/` |
| New folder | (did not exist) | `Meetings/Single/` |
| New script | (did not exist) | `new-standalone-meeting.sh` → **New Meeting** palette |

---

## File 1 — `src/documentation/User Handbook.md`

**Action:** Full rewrite. This file needs a new structure. The existing content is largely salvageable but must be reorganized and partially rewritten. Do not preserve the existing section order.

### New Structure

The handbook flows through three parts. Every existing section maps to one of them — nothing is dropped, some sections are split, and a few gaps are filled.

---

#### Part I — Philosophy

**Goal:** Explain why Meridian works the way it does before describing what it is. A reader who finishes Part I should understand the core design tradeoff and the habit that makes the system work.

**Section 1 — The Mental Model**
Preserve existing content. The framing (capture ≠ filing, daily note as frictionless inbox, MOCs surface what matters) is correct and well-written. No structural changes needed.

**Section 2 — Capture Mindset: Fast In, Filed Later**
Move here from its current position (was section 10). This is the behavioral precondition for the system — it belongs in Philosophy, not after all the structural sections. Preserve existing content. The markers table, the `>>` bridge, and the "what goes in daily note vs directly in vault" distinction are all correct.

**Section 3 — The Three Domains**
Move here from its current position (was section 3, but now closes Part I instead of opening the structural sections). Preserve existing content: Work/Life/Knowledge conceptual framework, the "these are not silos" framing. This section now flows directly into Part II — Structure.

---

#### Part II — Structure

**Goal:** Describe what exists in the vault and what goes where. A reader who finishes Part II should know what every top-level folder is for and be able to make filing decisions without consulting the Reference Guide.

**Section 4 — The Northstar**
Preserve existing content. No changes to the section itself. Northstar remains a top-level folder (personal vault only) and the philosophical anchor of the vault — it is not a subfolder of Life.

**Section 5 — Life: Everything Else That Matters**
Move above Work (was section 7). Life is conceptually prior to Work — it is the broader context in which work is one domain. Preserve existing content.

**Section 6 — Work: Structured and Ephemeral**
Preserve existing content for the Work folder structure overview. The folder tree in the current section is correct.

Then fold Meetings as a subsection (`###`) under Work. Meetings are work — structurally and conceptually. The subsection covers:

- **Which meetings get files** — preserve existing "The core distinction" content (daily note only / project folder / Meetings folder / 1:1 rolling note). This is structural taxonomy.
- **Updated folder paths** — the current handbook shows `Meetings/[Series]/` paths; update to show the new three-subfolder structure:
  ```
  Meetings/
    1on1s/     rolling 1:1 notes, one per person
    Series/    recurring series — [Series]/ → index + dated instances
    Single/    standalone one-off meeting notes
  ```
- **Two-level series structure** — preserve existing series index / instance index description, updated for the new `Meetings/Series/[Series]/` path.
- **Rolling 1:1 notes** — preserve existing content (what they are, the People note relationship, when to move them on company change). The path `Meetings/1on1s/` is unchanged.
- **What does not belong in Meetings** — preserve existing list (project meetings → Projects/, HR artifacts → People/, vendors → Vendors/, incident retros → Incidents/).

**Do not include** meeting preparation workflow or in-meeting linking patterns here — those move to Process.

**Section 7 — Knowledge: What Transcends Context**
Preserve existing content. Update one structural detail: `References/` is now a subfolder of `Knowledge/`, not a top-level peer. Add a brief paragraph after the Knowledge folder tree:

> **References** (`Knowledge/References/`) is an unstructured subfolder for external artifacts — source material, whitepapers, PDFs, documents you collected but didn't write. It is the raw input layer; Knowledge is the synthesis layer. Unlike the other Knowledge subfolders, References has no internal structure — filing decisions inside it are not Meridian's concern.

Remove any content that describes `References/` as a top-level folder.

**Section 8 — People Notes: When to Move Them**
Preserve existing content. This section spans Work and Life and closes the Structure part naturally.

---

#### Part III — Process

**Goal:** Describe how to operate the system day to day. A reader who finishes Part III should be able to run a daily capture flow, use the meeting scripts, run a weekly review, and understand how the vault compounds over time.

**Section 9 — Vault Management**
This section covers the five scripts: what they do, when to run them, flags, and what they create. It is the updated replacement for the current "Vault Management Scripts" section.

Rename from "Vault Management Scripts" to "Vault Management".

Cover all five scripts. The existing content for `new-company.sh`, `new-project.sh`, `new-meeting-series.sh`, and `new-1on1.sh` is mostly correct but needs path updates. Add `new-standalone-meeting.sh` as a new subsection. Add `set-default-company.sh` if not already present.

**Update for `new-meeting-series.sh`:** The paths in the existing section reference `Meetings/[Series]/` — update to `Meetings/Series/[Series]/`.

**New subsection — `new-standalone-meeting.sh`:**
```
### `new-standalone-meeting.sh` — Create a standalone meeting note

bash .scripts/new-standalone-meeting.sh
bash .scripts/new-standalone-meeting.sh --vault <path> --name <name> --date <YYYY-MM-DD> [--folder]
```

Run this for any meeting that warrants its own record but is not a recurring series or 1:1. The note is created in `Meetings/Single/`.

**Flags table:**

| Flag | Default | Notes |
|---|---|---|
| `--vault` | `$MERIDIAN_VAULT` or picker | Required |
| `--company` | Auto-resolved | Same resolution as other scripts |
| `--name` | Prompted | Used in filename and H1 |
| `--date` | Today | Allows prep for future meetings |
| `--folder` | Off | Creates a folder + index note for artifact-heavy meetings |

**Files created:**
- Default: `Meetings/Single/YYYY-MM-DD <Name>.md`
- With `--folder`: `Meetings/Single/YYYY-MM-DD <Name>/YYYY-MM-DD <Name>.md`

No series backlink. The note links to the daily note for the meeting date.

**Summary table** at the end of Vault Management (updated from current):

| Script | When to run | Command palette |
|---|---|---|
| `new-company.sh` | New employer or client | **New Company** |
| `new-project.sh` | New scoped effort with deliverables | **New Project** |
| `new-meeting-series.sh` | Before prep for any recurring meeting | **New Meeting Series** |
| `new-1on1.sh` | Before any 1:1 | **New 1:1** |
| `new-standalone-meeting.sh` | Before any one-off meeting needing its own note | **New Meeting** |
| `set-default-company.sh` | Change which company scripts default to | — |

---

**Section 10 — Running a Meeting**

This is a new section covering the operational meeting workflows. It replaces the "Preparing for a meeting" and "Linking during a meeting" subsections that previously lived inside the Meetings section.

**Subsection: Preparing for a Meeting**

Cover all five scenarios in this order:

1. **New recurring series (first instance)**
   Run `new-meeting-series.sh`. It creates the series index (`Meetings/Series/[Series]/[Series].md`) and the first instance folder and note. Prompts for series name, purpose, and cadence on first run.

2. **New instance of an existing series**
   Run `new-meeting-series.sh` again with the same series name. It appends an instance link to the existing series index and creates a new dated instance folder and note. Does not re-prompt for purpose or cadence.

3. **New 1:1 (first meeting with a person)**
   Run `new-1on1.sh`. Creates `Meetings/1on1s/[Name] 1on1s.md` with frontmatter, a link to the person's People note, and the first dated entry.

4. **Updating an existing 1:1**
   Run `new-1on1.sh` again with the same person's name. Appends a new dated entry to the bottom of the existing rolling note.

5. **Standalone one-off meeting**
   Run `new-standalone-meeting.sh` (or invoke **New Meeting** from the palette). No series index is created — just a single note in `Meetings/Single/`. Use `--folder` if you expect prep materials or artifacts to accompany the note.
   
   For very lightweight one-off meetings where you don't want a script, you can also create a note directly from the **Meeting Instance** template via `Cmd+Shift+T` in a new note. Note that template placeholders are not auto-substituted — you'll need to fill in the header fields manually.

For all script-created notes: fill in Purpose and Attendees before the meeting. Add Key Points, Decisions, and Action Items during or immediately after.

**Subsection: Linking During a Meeting**

Preserve the existing "Linking during a meeting" content from the current Meetings section. This covers inline person/project links, the action item marker convention, and the note that Tasks scans all vault files including nested Meetings folders.

---

**Section 11 — The Weekly Rhythm**
Preserve existing content. No changes needed.

**Section 12 — Building a Connected Graph Over Time**
Preserve existing content. This is the right closing section — it describes the long-term payoff.

---

### Table of Contents

Update to match the new structure:

```
## Table of Contents

**Part I — Philosophy**
1. The Mental Model
2. Capture Mindset: Fast In, Filed Later
3. The Three Domains

**Part II — Structure**
4. The Northstar
5. Life: Everything Else That Matters
6. Work: Structured and Ephemeral
7. Knowledge: What Transcends Context
8. People Notes: When to Move Them

**Part III — Process**
9. Vault Management
10. Running a Meeting
11. The Weekly Rhythm
12. Building a Connected Graph Over Time
```

---

## File 2 — `src/documentation/User Setup.md`

**Action:** Targeted updates — do not rewrite. Identify and update every affected section.

### Section: Work Machine Setup → What the work profile includes

Update the table. `References/` no longer exists as a top-level folder:

| Folder | Personal vault | Work vault |
|---|---|---|
| `Process/` | Yes | Yes |
| `Work/` | Yes | Yes |
| `Knowledge/` | Yes | **No** (lives at `Work/<Company>/Knowledge/`) |
| `_templates/` | Yes | Yes |
| `.scripts/` | Yes | Yes |
| `Northstar/` | Yes | **No** |
| `Life/` | Yes | **No** |

Remove the `References/` row — it no longer exists at the top level in either profile.

Update the prose below the table:
> "The three omitted folders are intentionally absent..."

Change to reference two omitted folders (`Northstar/` and `Life/`) plus top-level `Knowledge/`. References is no longer in scope — it lives at `Knowledge/References/` in the personal vault only, and the work vault has no equivalent.

### Section: Work Machine Setup → Syncthing configuration

The Syncthing table references `References/` as "Not configured":

```
| References/      | Not configured |
```

Remove this row. `Knowledge/References/` is part of the personal vault only and has no sync configuration change (it's nested inside `Knowledge/`, which was already absent from the work machine).

### Section: Files and Links

The "Default location for new attachments" row currently reads:
```
| Default location for new attachments | `References` (personal) ... |
```

Update to:
```
| Default location for new attachments | `Knowledge/References` (personal) ... |
```

### Section: Managing Companies

The folder tree shown after the command lists `Meetings/1on1s/` as the only Meetings subfolder:

```
  Meetings/
    1on1s/
```

Update to:

```
  Meetings/
    1on1s/
    Series/
    Single/
```

### Section: Managing Meetings

This section needs a substantial rewrite. The current content covers `new-meeting-series.sh` and `new-1on1.sh`. It must be updated to cover all five meeting scenarios and add `new-standalone-meeting.sh`.

The target structure for this section:

1. Brief overview: Meridian has three types of meeting notes (series instances, 1:1 rolling notes, and standalone single notes) and three scripts to manage them.

2. **Meeting series and instances** — update existing content:
   - Update path references: `Meetings/[Series]/[Series].md` → `Meetings/Series/[Series]/[Series].md`
   - Update path references: `Meetings/[Series]/YYYY-MM-DD/` → `Meetings/Series/[Series]/YYYY-MM-DD/`

3. **1:1 notes** — update existing content:
   - Update path references: `Meetings/1on1s/[Name]/[Name] 1on1s.md` (verify against Phase 1 migration notes for exact path)

4. **Standalone meeting notes** — new content:
   - Describe `new-standalone-meeting.sh` and its `--folder` flag
   - Show the command: `bash "$MERIDIAN_VAULT/.scripts/new-standalone-meeting.sh" --vault "$MERIDIAN_VAULT"`
   - Note that **New Meeting** is the palette alias

5. Keep the existing "Why not use the Templates plugin for meeting notes?" explanation — it applies to all three script types and is useful context.

### Section: Shell Commands → Add Command 6: New Meeting (palette)

Add a new command entry following the pattern of commands 2–5:

```
#### Command 6: New Meeting (palette)

1. Click **New command**
2. Enter: `bash "{{vault_path}}/.scripts/new-standalone-meeting.sh" --vault "{{vault_path}}"`
3. Set **Working directory**: `{{vault_path}}`
4. Click gear icon → **Events** tab: leave all disabled (palette-only, not automatic)
5. **Output** tab → Output channel for stdout: **Show in notification** (or **Ask after execution**)
6. Set alias: "New Meeting"
```

### Section: Filing Heuristics

Update the `References/` row:

```
# Before
| Is it someone else's artifact? | `References/` |

# After
| Is it someone else's artifact? | `Knowledge/References/` |
```

---

## File 3 — `src/documentation/Architecture.md`

**Action:** Update vault structure diagrams and Meetings layer section. Do not rewrite other content.

### Personal vault structure

Find the personal vault folder tree. Make these changes:

1. Remove `References/` as a top-level folder entry.
2. Add `References/` as a subfolder under `Knowledge/`:
   ```
   Knowledge/
     Technical/
     Leadership/
     Industry/
     General/
     References/      external source material — unstructured
   ```

3. Update the Meetings subtree under `Work/CurrentCompany/`:
   ```
   # Before
   Meetings/
     1on1s/
     [Series Name]/
       [Series Name].md
       YYYY-MM-DD/
         [Series] YYYY-MM-DD.md

   # After
   Meetings/
     1on1s/           rolling 1:1 notes, one file per person
     Series/          one folder per recurring series
       [Series Name]/
         [Series Name].md        series index note
         YYYY-MM-DD/             one folder per instance
           [Series] YYYY-MM-DD.md
     Single/          standalone one-off meeting notes
   ```

### Work vault structure

Update the Meetings subtree identically (same change, same paths).

The work vault has no `Knowledge/` or `References/` at top level — this is unchanged. No References update needed for the work vault diagram.

### Meetings Layer section

Update all path references in the Meetings Layer section:

- `Meetings/[Series]/[Series].md` → `Meetings/Series/[Series]/[Series].md`
- `Meetings/[Series]/[Date]/[Series] [Date].md` → `Meetings/Series/[Series]/[Date]/[Series] [Date].md`
- Update the series index / instance index descriptions to reference the new paths
- Update the linking model diagram paths accordingly

---

## File 4 — `src/documentation/Reference Guide.md`

**Action:** Targeted updates to vault structure listing, filing heuristics, and Meetings paths.

### Vault Structure section

**Personal vault:**
1. Remove `References/` top-level entry.
2. Add `References/` under `Knowledge/`:
   ```
   Knowledge/       Technical/ · Leadership/ · Industry/ · General/ · References/
   ```

3. Update Meetings paths under `Work/CurrentCompany/`:
   ```
   # Before
   Meetings/
     1on1s/         [Name] 1on1s.md — rolling notes, one per person
     [Series]/      [Series].md · YYYY-MM-DD/ → [Series] YYYY-MM-DD.md

   # After
   Meetings/
     1on1s/         [Name] 1on1s.md — rolling notes, one per person
     Series/        [Series]/ → [Series].md · YYYY-MM-DD/ → [Series] YYYY-MM-DD.md
     Single/        YYYY-MM-DD <Name>.md — standalone one-off notes
   ```

**Work vault:**
Update the Meetings subtree identically.

### Meeting Taxonomy — Decision Rules table

Add a row for standalone meetings:

| Meeting type | Where output goes |
|---|---|
| Recurring series with artifacts | `Meetings/Series/[Series]/[Date]/` |
| Project-related meeting | `Projects/[Project]/` |
| 1:1 with ongoing tracking | `Meetings/1on1s/[Name] 1on1s.md` |
| Standalone one-off meeting | `Meetings/Single/YYYY-MM-DD <Name>.md` |
| Tasks + bullets only | Daily note only |
| No notes needed | — |

### Linking Conventions — Meetings table

Update path references in the From/To columns to reflect the new `Meetings/Series/` paths. The link *syntax* (`[[Series YYYY-MM-DD]]`) does not change — only the physical location of the files.

### Filing Heuristics table

Update the `References/` row:

```
# Before
| Someone else's artifact? | `References/` |

# After
| Someone else's artifact? | `Knowledge/References/` |
```

### Scaffold section

Update the work vault description:

```
# Before
**Work machine (work vault — omits Northstar, Life, References):**

# After
**Work machine (work vault — omits Northstar, Life, and top-level Knowledge):**
```

---

## File 5 — `meridian-system.html`

**Action:** Update the three affected areas. This is a print-ready HTML quick reference — preserve the existing layout and style precisely; change content only where noted.

### Area 1 — Structure / Vault Layout

Find the vault layout section. Apply the same changes as Architecture.md:
- Remove `References/` from top-level personal vault listing
- Add `References/` under `Knowledge/`
- Update Meetings to show `1on1s/`, `Series/`, `Single/`

### Area 2 — Vault Management / Scripts

Find the script reference section. Add `new-standalone-meeting.sh`:

| Script | When to run |
|---|---|
| `new-standalone-meeting.sh` | Before any one-off meeting needing its own note |

Add **New Meeting** to the command palette list.

### Area 3 — Meetings

Find the meetings section. Update path references from `Meetings/[Series]/` to `Meetings/Series/[Series]/`. Add a line for `Meetings/Single/` alongside the existing series and 1:1 entries.

---

## File 6 — `README.md`

**Action:** Targeted updates only.

### Quick Start section

The personal vault description currently mentions `References/`:

> "Creates the full vault including `Northstar/`, `Life/`, and `References/`."

Update to:

> "Creates the full vault including `Northstar/`, `Life/`, and `Knowledge/References/`."

### Features section

The work machine profile bullet mentions omitted folders:

> "`--profile work` scaffolds a work-only vault that omits all personal folders."

Update the description to remove `References/` as a named omitted folder. References is no longer top-level.

### Daily Operation table

Add a row for the new script:

| Action | Method |
|---|---|
| Create a standalone meeting note | Command palette → "New Meeting" |

---

## File 7 — Documentation Audit

**Action:** Search all `src/documentation/` files for any remaining stale path references. Fix anything found.

Search patterns to check:

1. `References/` appearing as a top-level path (should now be `Knowledge/References/`)
2. `Meetings/[^1S]` — any Meetings path not starting with `1on1s`, `Series`, or `Single` (these are stale series paths)
3. `new-standalone-meeting` — verify it appears wherever other `new-*.sh` scripts are listed

Files to check beyond the ones already updated:
- `src/documentation/Sync.md` — has a Syncthing folder matrix that references `References/`
- `src/documentation/Security.md` — may reference vault folder layout
- `src/documentation/Upgrading.md` — may reference vault structure

For each stale reference found: fix inline and note it in a brief audit log at the bottom of this spec (add a "Audit Findings" section as you work).

---

## Deliverables Checklist

- [ ] `src/documentation/User Handbook.md` — fully rewritten per new structure
- [ ] `src/documentation/User Setup.md` — all affected sections updated
- [ ] `src/documentation/Architecture.md` — vault diagrams and Meetings layer updated
- [ ] `src/documentation/Reference Guide.md` — vault structure, taxonomy table, filing heuristics updated
- [ ] `meridian-system.html` — structure, scripts, and meetings areas updated
- [ ] `README.md` — Quick Start, Features, Daily Operation table updated
- [ ] Audit complete — all stale `References/` and `Meetings/` path references resolved across all docs
