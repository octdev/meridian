# Meetings Layer — Implementation Story

**As a** Meridian user operating at executive scale,
**I want** a structured, low-friction layer for recurring meeting series and 1:1 tracking,
**so that** meeting artifacts, decisions, and action items are findable as a connected body of work rather than isolated dated files.

---

## Background

Meridian's existing capture model handles ad-hoc notes and project work well. It does not address the operational reality of an executive calendar: 40+ meetings per week, recurring series that generate artifacts across months, and direct report relationships that require longitudinal tracking. Without structure, meeting prep materials accumulate in the filesystem outside the vault, 1:1 notes fragment across daily notes, and series-level context is never recorded.

This story adds a Meetings layer to Meridian that handles this class of work. It does not change the daily note flow, the frontmatter chain, or the plugin stack.

---

## Acceptance Criteria

### 1. Vault structure

- [ ] `Work/CurrentCompany/Meetings/` is created by both `scaffold-vault.sh` (personal and work profiles) and `new-company.sh`
- [ ] `Work/CurrentCompany/Meetings/1on1s/` is created by the same scripts
- [ ] No series subfolders are pre-created; they emerge from `new-meeting-series.sh`

### 2. Templates

- [ ] `_templates/Meeting Instance.md` exists and contains the standard three-field frontmatter, the H1 pattern `[Series] YYYY-MM-DD`, and sections: Purpose, Attendees, Agenda, Key Points, Decisions, Action Items, Next Meeting, plus footer links to series index and daily note
- [ ] `_templates/Meeting Series.md` exists and contains standard frontmatter and sections: Purpose, Cadence, Standing Attendees, Format / Agenda Template, Instances
- [ ] `_templates/1on1.md` exists and contains standard frontmatter, H1 `[Name] 1:1s`, a link to the People note, and a single dated section with Agenda and Notes fields

### 3. `new-meeting-series.sh`

- [ ] Accepts `--vault`, `--series`, and `--date` flags; prompts interactively for any not supplied
- [ ] `--date` defaults to today if not provided
- [ ] If the series folder does not exist, creates `Meetings/[Series]/[Series].md` from the series template, prompting for purpose and cadence
- [ ] If the series folder exists, appends `- [[Series YYYY-MM-DD]]` to the Instances section of the existing series index
- [ ] Creates `Meetings/[Series]/[Date]/[Series] [Date].md` from the instance template with `title`, `created`, and `modified` frontmatter pre-populated
- [ ] Aborts with a clear error message if the instance folder already exists; no files are modified
- [ ] Outputs a hint to reference the instance from today's daily note
- [ ] Follows Meridian CLI conventions: colored output, validation, interactive prompts

### 4. Shell Commands integration

- [ ] A **New Meeting Series** palette entry exists in Shell Commands, invoking `new-meeting-series.sh --vault {{vault_path}}`
- [ ] The entry behaves consistently with the existing **New Company** and **New Project** palette entries

### 5. 1:1 rolling notes

- [ ] Rolling notes live flat in `Meetings/1on1s/` as `[Name] 1on1s.md`
- [ ] Each note links to the corresponding People note (`[[Name]]`)
- [ ] The corresponding People note links back (`[[Name 1on1s]]`)
- [ ] New entries are appended as `## YYYY-MM-DD` sections with Agenda and Notes fields; the file is never split

### 6. Action item flow

- [ ] Tasks written with standard markers in any instance index note (`- [ ] !`, `- [ ] !!`) surface in the Action Items MOC without additional configuration

### 7. Documentation

- [ ] `architecture.md` documents the Meetings folder structure, the two-level series/instance model, the rolling 1:1 pattern, and the linking model
- [ ] `design-decisions.md` records why Meetings is a peer folder to Projects and Reference, why series/instance nesting was chosen over flat date-named folders, why rolling 1:1 notes were chosen over per-instance folders, and why no new frontmatter fields were introduced
- [ ] `user-handbook.md` contains a Meetings section covering the meeting taxonomy, the series/instance model, the prep workflow, rolling 1:1 notes, and what does not belong in Meetings
- [ ] `reference-guide.md` contains the instance note structure, the 1:1 rolling note structure, the meeting taxonomy decision table, linking conventions, the new scaffold entry, and updated filing heuristics
- [ ] `user-setup.md` documents the Shell Commands palette entry for New Meeting Series
- [ ] `meridian-system.html` Vault Layout reflects `Meetings/` and `Meetings/1on1s/` under `Work/CurrentCompany/`

---

## Out of Scope

- Templater integration — templates use static placeholder text; variable substitution is handled by the script, not by Templater
- Per-instance folders for 1:1s — explicitly rejected; see design-decisions.md
- New frontmatter fields — explicitly rejected; see design-decisions.md
- Meetings folder in personal vault outside of Work — not applicable to this use case
