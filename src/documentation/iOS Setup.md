# iOS Setup

Meridian's vault content and sync layer are fully supported on iOS. The scaffold and automation scripts (bash, Python) cannot run on an iPhone or iPad — those run once on macOS and their output syncs to iOS automatically.

---

## What Works on iOS

| Feature | iOS |
|---------|-----|
| All vault content (notes, MOCs, templates) | Yes |
| Daily Notes (core plugin) | Yes |
| Templates (core plugin) | Yes |
| Tasks MOC queries | Yes |
| Dataview MOC queries | Yes |
| Filename Heading Sync | Yes |
| Linter | Yes |
| Front Matter Timestamps | Yes |
| Editing Toolbar | Yes |
| Hider | Yes |
| Shell Commands (bash scripts) | **No** |
| Weekly snapshot auto-run | **No** |
| New company / project / meeting palette entries | **No** |

---

## Prerequisites

- The vault must be scaffolded on macOS first. Complete [[User Setup]] through Step 3 before deploying to iOS.
- Yaos sync must be configured on macOS. See [[Sync]] for setup instructions.

---

## Deploying to iOS

### Step 1: Verify sync is running on macOS

Open Obsidian on macOS. Confirm that Yaos is active and the vault is syncing. Make a small edit and confirm it saves without error before continuing.

### Step 2: Install Obsidian on iOS

Install Obsidian from the App Store.

### Step 3: Install and configure Yaos on iOS

In Obsidian iOS: **Settings → Community Plugins → Browse → search "Yaos" → Install → Enable**.

Open the Yaos plugin settings and connect to the same Cloudflare Worker endpoint you configured on macOS. The vault will appear as an available remote.

### Step 4: Open the vault

In Yaos plugin settings, select the vault and tap **Open**. Obsidian will open the synced vault. Wait for the initial sync to complete before continuing.

### Step 5: Install community plugins on iOS

Go to **Settings → Community Plugins → Browse** and install the following. Skip Shell Commands — it has no function on iOS.

| Plugin | Install on iOS |
|--------|---------------|
| Tasks | Yes |
| Dataview | Yes |
| Filename Heading Sync | Yes |
| Linter | Yes |
| Front Matter Timestamps | Yes |
| Editing Toolbar | Yes |
| Hider | Yes |
| Shell Commands | **No** |

### Step 6: Configure Core Plugins

**Daily Notes**: Settings → Core Plugins → Daily Notes → enable. Set the same date format (`YYYY-MM-DD`) and folder path (`Life/Daily` for personal, `Work/<Company>/Daily` for work) as macOS.

**Templates**: Settings → Core Plugins → Templates → enable. Set template folder to `_templates`.

---

## Plugin Timing on iOS

The frontmatter chain (Front Matter Timestamps → save → Linter → Filename Heading Sync) uses a 100 ms delay configured in Front Matter Timestamps. iOS CPU scheduling may cause occasional misses on the first save of a new note. If `title` stops populating reliably, increase the delay in Front Matter Timestamps by 50 ms increments until it stabilizes.

---

## Limitations and Workarounds

### Weekly snapshots

`weekly-snapshot.py` runs automatically on macOS via Shell Commands on vault open and every four hours. It cannot run on iOS. The generated `Process/Weekly/` files sync to iOS via Yaos — they are readable on iOS but generated on macOS.

**Workaround**: Weekly snapshots are created automatically the next time you open Obsidian on macOS. No manual action is required on iOS.

### New company, project, and meeting scripts

`new-company.sh`, `new-project.sh`, `new-meeting-series.sh`, `new-1on1.sh`, and `new-standalone-meeting.sh` require a terminal and cannot run on iOS.

**Workaround**: Create the folder structure and note manually using the `_templates/` templates, or perform the scaffolding on macOS and let it sync to iOS.

### Shell Commands palette entries

All Shell Commands palette entries (New Company, New Project, New Meeting Series, New 1:1, New Meeting) are unavailable on iOS. The Shell Commands plugin should not be installed on iOS.

---

## Daily Workflow on iOS

The iOS workflow mirrors macOS for capture and retrieval:

1. **Morning**: Open today's daily note (tap the Daily Note icon).
2. **Throughout the day**: Capture tasks, notes, and events in the daily note using standard markers.
3. **Reviewing MOCs**: Action Items, Open Loops, Review Queue, Active Projects, and Weekly Outtake all render correctly on iOS.
4. **Navigation**: Use wikilinks and MOCs to move between notes as usual.

Operations that require automation (new company, new project, new meeting series, weekly snapshots) must be performed on macOS.
