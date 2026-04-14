# Validation Plan — Meridian 1.5.0

Execute after running the upgrade on a real vault and opening it in Obsidian.

## 1. Vault Structure

- [ ] `Knowledge/References/` exists and is accessible in file explorer
- [ ] No `References/` folder at vault root
- [ ] `Meetings/` contains exactly three subfolders: `1on1s/`, `Series/`, `Single/`
- [ ] Existing series folders (if any) are now inside `Meetings/Series/`
- [ ] `Meetings/Single/` exists and is empty (unless standalone meetings already exist)

## 2. Filing Heuristics — References

- [ ] Drop a PDF into `Knowledge/References/` — file appears in vault file explorer under Knowledge/References/
- [ ] Open an existing Knowledge note, link to the reference with `[[filename]]` — wikilink resolves

## 3. New Meeting Series

- [ ] Run `new-meeting-series.sh` for a brand new series
- [ ] Verify series index created at `Meetings/Series/[Series]/[Series].md`
- [ ] Verify instance created at `Meetings/Series/[Series]/[Date]/[Series] [Date].md`
- [ ] Run again for the same series — verify new instance created, series index updated, old instance preserved
- [ ] Open series index — verify instance link resolves

## 4. Existing Series Backlinks (upgrade only)

- [ ] Open an existing daily note that links to a series instance — verify wikilink still resolves after migration
- [ ] Open a migrated series index — verify instance links still resolve
- [ ] Open a migrated instance note — verify Series backlink and daily note backlink still resolve

## 5. New Standalone Meeting

- [ ] Run `new-standalone-meeting.sh` without `--folder`
- [ ] Verify note created at `Meetings/Single/YYYY-MM-DD <Name>.md`
- [ ] Verify note contains correct frontmatter, H1, and daily note backlink
- [ ] Run with `--folder` — verify folder + index note created
- [ ] Run for same name/date again — verify script aborts without writing

## 6. New 1:1

- [ ] Run `new-1on1.sh` for a new person — verify note at `Meetings/1on1s/[Name] 1on1s.md`
- [ ] Run again for same person — verify new dated entry appended, no duplicate header

## 7. MOCs

- [ ] Open `Process/Action Items.md` — no query errors
- [ ] Add a task in a meeting note under `Meetings/Series/` — verify it appears in Action Items MOC
- [ ] Add a task in a note under `Meetings/Single/` — verify it appears in Action Items MOC

## 8. Command Palette

- [ ] **New Meeting Series** appears in palette and runs successfully
- [ ] **New 1:1** appears in palette and runs successfully
- [ ] **New Meeting** appears in palette and runs successfully
- [ ] **New Company** appears in palette and runs successfully
- [ ] **New Project** appears in palette and runs successfully

## 9. Documentation

- [ ] Open `Process/Meridian Documentation/User Handbook.md` — renders correctly in Obsidian
- [ ] Open `Process/Meridian Documentation/Reference Guide.md` — vault structure paths are correct
- [ ] TOC links in User Handbook navigate correctly
