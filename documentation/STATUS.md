# Meridian — Project Status Summary

## Repo location

`/Users/chris/Projects/meridian`

## File inventory (all written to disk)

```
meridian/
  .gitignore
  README.md
  scaffold-vault.sh           -- profile work flag not yet built
  weekly-snapshot.py
  cheat-sheet.html            -- printable 2-sided reference sheet
  vault-files/
    templates/
      Daily Note.md
      Generic Note.md
      Reflection.md           -- end of day reflection template
    mocs/
      Action Items.md
      Active Projects.md
      Open Loops.md
      Review Queue.md
      Weekly Outtake.md
      Current Priorities.md
    northstar/
      Purpose.md · Vision.md · Mission.md
      Principles.md · Values.md · Goals.md · Career.md
  documentation/
    user-guide.md
    reference-guide.md
    architecture.md
    sync.md
    design-decisions.md
    security.md
    roadmap.md
```

## Pending actions

### Immediate

1. **Git init and push** — repo not yet initialized:
   ```bash
   cd /Users/chris/Projects/meridian
   chmod +x scaffold-vault.sh
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/meridian.git
   git push -u origin main
   ```

2. **Assign Reflection template hotkey** — `Cmd+Shift+T` is documented as suggested but must be assigned manually in Obsidian: Settings → Hotkeys → "Templates: Insert template"

3. **Print cheat-sheet** — open `cheat-sheet.html` in Safari → Export as PDF. Verify page 1 fits after Filing Heuristics row removal.

### Near-term

4. **Build `--profile work` flag** — see `work-scaffold.md` for full spec. Adds work-only scaffold mode to `scaffold-vault.sh` that skips Northstar, Life, and References.

5. **Syncthing setup** — install on work laptop and personal machine, pair devices, configure per folder sync matrix in `documentation/sync.md`.

### Deferred (roadmap.md)

6. **NAS v2 sync hub** — TrueNAS + Syncthing container + Nextcloud, once NAS rebuild is complete
7. **Syncthing config verification script**
8. **Automated vault config verification on open**
9. **Mobile capture improvements** (iOS Shortcut / Drafts integration)

## Key constraints to remember

- **Properties in document must stay set to Source** — changing to Visible breaks the Front Matter Timestamps → Linter frontmatter chain
- **Front Matter Timestamps delay is 100ms** — timing-dependent, not event-driven; increase in 50ms increments if title stops populating after plugin changes
- **Tasks query syntax** — `sort by filename reverse` is correct; `sort by file.name` is Dataview syntax and breaks Tasks queries
- **`_templates/` must be excluded** in both Filename Heading Sync and Linter — otherwise templates get corrupted on save

## Plugin stack (final)

| # | Plugin | Type | Category | Role |
|---|--------|------|----------|------|
| 1 | Daily Notes | Core | Automation | Auto-creates daily capture surface |
| 2 | Templates | Core | Automation | Populates daily note from template |
| 3 | Tasks | Community | MOCs | Task lifecycle, completion stamps, queries |
| 4 | Dataview | Community | MOCs | Powers Active Projects MOC |
| 5 | Filename Heading Sync | Community | Frontmatter | Keeps filename and H1 in sync |
| 6 | Linter | Community | Frontmatter | Writes `title` from H1 on save |
| 7 | Front Matter Timestamps | Community | Frontmatter | Auto-inserts `created` and `modified` |
| 8 | Scroller | Community | UX | Cursor to bottom on open/rename |
| 9 | Shell Commands | Community | Automation | Triggers weekly snapshot |
