# User Handbook

This document explains how to think about and use Meridian day-to-day. For installation and plugin configuration, see [User Setup.md](User%20Setup.md).

## Table of Contents

1. **Philosophy**
	1. [[#The Mental Model]]
	2. [[#Capture Mindset: Fast In, Filed Later]]
	3. [[#The Three Domains]]

2. **Structure**
	1. [[#The Northstar]]
	2. [[#Life: Everything Else That Matters]]
	3. [[#Work: Structured and Ephemeral]]
	4. [[#Knowledge: What Transcends Context]]
	5. [[#People Notes: When to Move Them]]

3. **Process**
	1. [[#Vault Management]]
	2. [[#Running a Meeting]]
	3. [[#The Weekly Rhythm]]
	4. [[#Building a Connected Graph Over Time]]

---

## The Mental Model

Meridian is built on one observation: most productivity systems fail because they demand a filing decision at the moment of capture. You're in a meeting, someone says something important, and the system asks: *where does this go?* The friction causes deferral, and deferred items become lost items.

Meridian separates capture from filing. The daily note is a frictionless inbox — everything that happens to you lands there. Filing happens during review, when you have context and calm. The system stays useful because the MOCs surface what matters without requiring you to browse the inbox manually.

This only works if you actually capture everything. Half-capture breaks the loop. The sections below explain how to build that habit and where things eventually land.

---

## Capture Mindset: Fast In, Filed Later

The single habit that makes Meridian work is this: **capture without filing decisions.**

The daily note is always open. `Cmd+D` returns you to it from anywhere. When something happens — a meeting, a call, a message, a realization — it goes in the log, with a marker if it needs follow-up. No folder navigation, no "where does this belong," no context switch.

The markers tell the system what kind of thing it is:

```
- [ ] !   needs doing (not urgent)
- [ ] !!  needs doing now
- [ ] ~   waiting on someone else
- [ ] >>  interesting or uncertain — process at review time
```

The `>>` marker is especially important. It is the bridge between "I don't know where this goes" and "I'll figure it out later." Use it freely. During the weekly review, the Review Queue MOC surfaces everything you've marked `>>` so you can promote, file, or discard.

**What goes in the daily note vs. directly in the vault:**

The core rule from the reference guide applies here:

> Things that *happen to you* go in the daily note. Things you *intentionally create* go directly where they belong.

If you're sitting down to write a project design document, don't start in the daily note — start directly in `Work/[Company]/Projects/[Project]/`. If a conversation triggers an important technical insight you want to capture as a standing note, write it directly in `Work/[Company]/Knowledge/Technical/` (or `Knowledge/Technical/` on a personal vault). The daily note is for reactive capture; intentional creation goes to its destination immediately.

---

## The Three Domains

The vault's knowledge layer is divided into three domains: **Work**, **Life**, and **Knowledge**. Understanding the distinction between them is the most important conceptual piece of the system.

```
Work/       What you do for your current employer or clients
Life/       Everything else — health, finances, relationships, projects
Knowledge/  What you've learned that transcends any single job or context
```

These are not silos. A meeting note in Work might generate an insight that belongs in Knowledge. A personal project in Life might reference technical knowledge you built at work. The links between them are the point — Meridian becomes more valuable over time as the graph of connections grows.

The filing heuristics in the reference guide give you the decision rules. The sections below explain the *reasoning* behind them.

---

## The Northstar

The `Northstar/` folder is the foundation of the vault. It is not a capture surface and it is not a project folder. It is a small set of documents that answer the question: *what am I actually trying to do with my life?*

It contains seven files:

| File | Question it answers |
|------|-------------------|
| `Purpose.md` | Why do I do what I do? |
| `Vision.md` | What does the future look like when I'm succeeding? |
| `Mission.md` | What work am I doing right now to move toward that? |
| `Values.md` | What do I optimize for? What are the non-negotiables? |
| `Principles.md` | What rules guide my decisions? |
| `Goals.md` | What are the concrete targets, with timelines? |
| `Career.md` | Where am I professionally, and where am I going? |

#### Setting It Up

These files ship empty with placeholder prompts. Fill them in before you start using the rest of the vault. A few sentences per file is enough to start — the point is to make the implicit explicit, not to write a manifesto.

Work outward from the most stable to the most concrete:

1. **Purpose** first. This changes rarely if ever. It is the underlying reason behind your work and your life — not your job title, not your current role. Something like "to build things that make other people's work easier" or "to be someone my family can rely on."

2. **Values** next. These are what you actually optimize for when you make trade-offs. If you claim to value family time but consistently override it for work, one of those is a real value and one is an aspiration. Be honest here — the notes are private.

3. **Vision** and **Mission** together. Vision is the destination; Mission is the current leg of the journey. Vision might be "leading a product organization at a company I believe in." Mission right now might be "becoming a principal engineer in the next two years."

4. **Principles** are your operating rules — the things you'd tell a past version of yourself. Short, direct statements work better than paragraphs.

5. **Goals** last, because they should flow from the above. If a goal doesn't connect to purpose or mission, it's a task masquerading as a goal. The template provides 12-month and 3-year buckets. Use both.

6. **Career** is an ongoing reference. Keep it current as your trajectory evolves.

#### Using the Northstar Daily

You don't open these files every morning. They anchor two things you do touch every day:

- **Top 3 Goals** in the daily note. These should connect to your 12-month goals or current mission. If you consistently fill in goals that have nothing to do with your Northstar, either the daily goals are noise or the Northstar is out of date.
- **Current Priorities** in `Work/<Company>/Goals/Current Priorities.md`. This is a manually maintained note where you write what you're focused on this week, month, and quarter at work. Keep it honest — it should reflect your actual priorities, not your aspirational ones. See [[#Northstar vs. Work Goals]] for the distinction between these two systems.

Review the Northstar once a quarter. Update Mission and Goals if things have shifted. Purpose and Values rarely change.

#### Northstar vs. Work Goals

The Northstar and your work goals are related but distinct systems operating at different scopes.

**Northstar** (`Northstar/`) is personal and life-wide. It lives only on your personal machine — it is never created on the work machine and never syncs there. It answers questions about who you are and where you are going across your entire life, independent of any single employer: purpose, values, long-term vision, personal goals, career trajectory.

**Work Goals** (`Work/<Company>/Goals/`) is job-scoped. It lives under your active company folder and syncs bidirectionally between your work and personal machines via Syncthing. It answers the operational question: *what am I focused on right now at this job?* — this week, this month, this quarter, this performance cycle.

The intended connection: your work priorities should trace back to your Northstar. If your Northstar mission is "become an engineering leader who builds high-performing teams," your annual work goal might be "lead the platform migration end-to-end" and your quarterly priority "close the three open engineering manager hires." The work goals are the operational expression of the Northstar at your current job.

When that connection breaks — when you are consistently busy but the work doesn't trace to anything in your Northstar — it is worth noticing. Either the work has drifted, the Northstar is out of date, or you are in the wrong job.

| Content | Location | Syncs to work machine |
|---------|----------|-----------------------|
| Purpose, values, vision | `Northstar/Purpose.md`, `Northstar/Values.md`, `Northstar/Vision.md` | No |
| Personal life goals (1-year, 3-year) | `Northstar/Goals.md` | No |
| Career trajectory and aspirations | `Northstar/Career.md` | No |
| Current work priorities (week/month/quarter) | `Work/<Company>/Goals/Current Priorities.md` | Yes |
| Performance goals for this employer | `Work/<Company>/Goals/` | Yes |

---

## Life: Everything Else That Matters

Life is where your personal existence lives. It has fewer prescribed subfolders because personal life is more varied than work, but the structure provided is a starting point:

```
Projects/     Personal projects with defined scope
People/       Personal relationships — family, friends, contacts
Health/       Medical, fitness, nutrition, mental health
Finances/     Personal accounts, investments, budgeting
Social/       Events, social coordination, community
Development/  Learning, skills, reading, growth
Fun/          Hobbies, travel, entertainment — things worth remembering
General/      Catch-all
```

One pattern that surprises people: Life gets used less than Work at first, but it grows to be just as valuable over time. Most people start capturing work things diligently and underuse the personal side of the vault. Resist this. A note about a health conversation with your doctor, a record of a meaningful trip, a note about a difficult family situation you navigated — these are the things you'll actually want to find in three years.

The filing heuristic is simple: if it matters to you personally and would matter at a different company, it goes in Life.

---

## Work: Structured and Ephemeral

Work has the most structure because work has the most retrieval pressure. When something goes wrong at 2am, you need to find the on-call runbook fast. When a vendor contract comes up for renewal, you need to find the previous negotiation notes. The folder structure under `Work/CurrentCompany/` reflects this:

```
Projects/     Active scoped work with defined scope and deliverables
People/       Notes on colleagues — context, 1:1 notes, feedback
Reference/    Company-specific knowledge: processes, systems, decisions
Incidents/    Post-mortems, on-call notes, escalation records
Vendors/      Contracts, renewals, contacts, relationship notes
Goals/        Your goals at this company — performance review material
Finances/     Compensation, equity, benefits, offers
General/      Anything that doesn't fit the above
Daily/        Your daily notes at this company (YYYY-MM-DD.md)
Knowledge/    Work-scoped knowledge: Technical/, Leadership/, Industry/
```

A note belongs in Work if it is specific to your current employer. If you leave this company, does the note still matter? If no, it belongs in Work. If yes, it belongs in Knowledge.

**When you leave a company:** Run `new-company.sh` to scaffold the new one. The old company's folder stays in place — it's a record, not a live system. Move any notes from `Work/People/` for colleagues you'll stay in touch with over to `Life/People/`. Backlinks update automatically.

#### Meetings

At executive scale, meetings are not incidental to work — they are a primary work surface. Decisions get made in them. Commitments get recorded in them. Artifacts get produced for them. The Meetings layer exists to make those records findable and connected, without forcing a filing decision in the middle of every calendar day.

##### Which meetings get files

Not every meeting needs a note outside the daily note. The decision:

**Daily note only** — the meeting produced tasks, observations, or bullets that belong to the day's capture flow and don't need independent retrieval. A status check, a quick decision, an interrupt. The timestamped `###` heading in the daily note is enough. Tasks surface in MOCs automatically.

**Project folder** — the meeting was primarily about a project. Notes go in `Work/CurrentCompany/Projects/[Project]/`. You would look for this note when thinking about the project, not when thinking about the meeting series. Filing it under Meetings would orphan it from its context.

**Meetings folder** — any planned meeting that needs its own record, where you'd look for it by the meeting rather than by the project. Three subfolders based on type: recurring series go under `Meetings/Series/`, standalone one-off meetings go under `Meetings/Single/`, and ongoing 1:1s go under `Meetings/1on1s/`.

```
Meetings/
  1on1s/     rolling 1:1 notes, one per person
  Series/    recurring series — [Series]/ → index + dated instances
  Single/    standalone one-off meeting notes
```

**1:1 rolling note** — one-on-ones with direct reports or tracked peers where you maintain an ongoing record of the working relationship. Not a per-meeting file — a single rolling document per person, appended over time.

If you're unsure: does this meeting need a record you'd look for outside the daily note, and is it not primarily about a project? If yes, use Meetings.

##### Series index and instance index

Every recurring meeting in the Meetings layer has two levels of note.

The **series index** lives at `Meetings/Series/[Series]/[Series].md`. It is the permanent record of what the meeting is: its purpose, cadence, standing attendees, and typical agenda format. You create it once (via `new-meeting-series.sh`) and update it when the meeting's structure changes. It also serves as the navigable list of all instances — an entry point to the full history of the series.

The **instance index** lives at `Meetings/Series/[Series]/[Date]/[Series] [Date].md`. It is the canonical record of one specific meeting. All prep materials, the deck, the PDF, and any other artifacts for that meeting are co-located in the same date folder and linked from the instance index. The instance index links up to the series index and back to the daily note on meeting day.

This two-level structure means: to understand what the meeting is, open the series index. To find what happened on a specific date, open the instance index. To find all instances, the series index lists them.

##### Rolling 1:1 notes

For direct reports and peers where you maintain an ongoing record, use a rolling note at `Meetings/1on1s/[Name] 1on1s.md`. Each meeting appends a new `## YYYY-MM-DD` section with Agenda and Notes. The file grows over time — this is intentional. The full arc of a working relationship is more useful than a collection of isolated per-meeting snapshots.

The rolling note links to the People note (`[[Name]]`). The People note links back (`[[Name 1on1s]]`). They serve different purposes:

- **People note** — who this person is: communication style, context, background, working preferences
- **1:1 rolling note** — your working history together: what you've discussed, committed to, observed, and decided

When a colleague leaves the company (or you do), move their People note from `Work/CurrentCompany/People/` to `Life/People/`. The 1:1 rolling note stays in place as a historical record — or moves with the People note if you expect the relationship to continue.

##### What does not belong in Meetings

- **Project meeting notes** — file under the project
- **People profiles** — file under `Work/CurrentCompany/People/`
- **Formal HR artifacts** (PIPs, promotion packets, review documents) — file under `Work/CurrentCompany/People/`
- **Vendor and contract discussions** — file under `Work/CurrentCompany/Vendors/`
- **Incident retros** — file under `Work/CurrentCompany/Incidents/`

The Meetings layer is for operational cadences. Everything else has a more specific home.

---

## Knowledge: What Transcends Context

Knowledge is the most important folder in the vault, and the most commonly underused one.

Knowledge is not where you dump reference material. It is where you put things you've actually learned — insights, mental models, technical understanding, leadership observations — that you want to carry with you across jobs, across roles, across years.

**Personal vault:** top-level `Knowledge/` with five subfolders:

```
Technical/    Engineering, architecture, tooling, systems design
Leadership/   Management, org dynamics, communication, team health
Industry/     Market knowledge, domain expertise, trends
General/      Everything else worth knowing
References/   External artifacts — source material, not yet synthesized
```

**References** (`Knowledge/References/`) is an unstructured subfolder for external artifacts — source material, whitepapers, PDFs, documents you collected but didn't write. It is the raw input layer; Knowledge is the synthesis layer. Unlike the other Knowledge subfolders, References has no internal structure — filing decisions inside it are not Meridian's concern.

**Work vault:** Work accrued knowledge starts at `Work/<Company>/Knowledge/` (Technical, Leadership, Industry) and is promoted to personal `Knowledge/` by deliberate choice. This scoping is intentional — work-generated knowledge is context-specific until you decide it is transferable.

#### The Test

Before filing a note, ask: *would I want this if I started at a new company tomorrow?*

- Notes about your current company's architecture → `Work/Reference/`
- Notes about architectural patterns you've developed opinions on → `Work/<Company>/Knowledge/Technical/` (then promote to personal `Knowledge/` if truly transferable)
- Notes about how your current manager gives feedback → `Work/People/`
- Notes about what you've learned about giving good feedback → `Work/<Company>/Knowledge/Leadership/`
- Notes about your current product's market position → `Work/Reference/`
- Notes about how to think about market positioning → `Work/<Company>/Knowledge/Industry/`

The distinction is *specific context* (Work) versus *transferable understanding* (Knowledge). When in doubt, leave the note in the daily note with a `>>` marker and decide at weekly review.

#### Promoting Work Knowledge

Knowledge that started as work-scoped can graduate to your personal `Knowledge/` folder when you are confident it is transferable — patterns you'd apply at a future employer, mental models that outlast any single job. This is a manual move: copy or rename the file from `Work/<Company>/Knowledge/` to `Knowledge/`. Obsidian updates backlinks automatically.

#### Promoting Insights

The `&` marker is the mechanism for Knowledge promotion. When you have a realization mid-day — in a meeting, during a problem-solving session, in a conversation — mark it with `&`:

```
& The velocity drop happens consistently when PR review time exceeds 3 days
& Users don't want more features — they want fewer failure modes
```

These are searchable in the daily notes. During the weekly review, scan for `&` items and decide which ones are worth promoting to a standing Knowledge note. Not every insight needs its own note — sometimes a few bullets under a broader topic note is enough.

---

## People Notes: When to Move Them

People notes deserve special attention because they can span both Work and Life, and may outlast the context in which you first created them.

Start a person note the moment you have a meaningful interaction that you'll want to remember. A colleague's communication style, the context they gave you in a 1:1, a commitment they made, a pattern you've noticed — these are ephemeral in memory and durable in notes.

**Where they live:**

- Active colleagues at your current company → `Work/People/`
- Everyone else — personal contacts, former colleagues you're still in touch with, professional connections outside current employment → `Life/People/`

**When to move them:**

When a colleague leaves the company (or when you leave), move their note from `Work/People/` to `Life/People/` if the relationship will outlast the initial professional context. Obsidian updates backlinks automatically.

The move preserves the history: your notes about working with someone at one company become the foundation of understanding them as a person, not just as a colleague.

---

## Vault Management

Six scripts handle vault scaffolding and meeting management. They live in `.scripts/` inside the vault and can be run from a terminal or triggered via the Obsidian command palette (Shell Commands plugin). All scripts accept flags or run fully interactively — if you omit a flag, you will be prompted.

All scripts resolve the vault from `--vault <path>`, the `$MERIDIAN_VAULT` environment variable, or an interactive picker, in that order.

| Script | When to run | Command palette |
|--------|------------|-----------------|
| `new-company.sh` | New employer or client | **New Company** |
| `new-project.sh` | New scoped effort with deliverables | **New Project** |
| `new-meeting-series.sh` | Before prep for any recurring meeting | **New Meeting Series** |
| `new-1on1.sh` | Before any 1:1 | **New 1:1** |
| `new-standalone-meeting.sh` | Before any one-off meeting needing its own note | **New Meeting** |
| `set-default-company.sh` | Change which company scripts default to | — |
| `set-default-vault.sh` | Change which vault is the default in the registry | — |

---

#### `new-company.sh` — Add a new employer or client

```bash
bash .scripts/new-company.sh
```
```bash
bash .scripts/new-company.sh --vault <path> --company <name>
```

Run this when you start at a new employer or take on a new client. It creates the full company folder structure under `Work/` and seeds two things:

- `Goals/Current Priorities.md` — pre-structured with Annual / Quarter / Month / Week sections
- `.obsidian/daily-notes.json` — updated to point daily note creation at the new company's `Daily/` folder

**Folders created:**
```
Work/<Company>/
  Daily/    Drafts/    Finances/    General/    Goals/
  Incidents/    Knowledge/{Technical,Leadership,Industry}
  Meetings/{1on1s,Series,Single}/    People/    Projects/    Reference/    Vendors/
```

The script also sets this company as the `DefaultCompany` in `.scripts/.vault-version`, so subsequent scripts know which company to default to. It checks for an existing company with the same name and requires `[y/N]` confirmation before writing anything.

**After running:** run `new-project.sh` to scaffold your first project.

---

#### `new-project.sh` — Scaffold a project

```bash
bash .scripts/new-project.sh
```
```bash
bash .scripts/new-project.sh --vault <path> --name <name> --projects-dir <path>
```

Run this whenever a scoped effort with deliverables starts — under `Work/<Company>/Projects/` or `Life/Projects/`. The script validates the target location and warns if the path doesn't match either expected pattern, allowing you to override.

When prompting for a Projects directory, the script suggests a default in this priority order: the active/default company's `Work/<Company>/Projects/` (resolved from `.obsidian/daily-notes.json` then `DefaultCompany` in `.vault-version`), then `Life/Projects/`, then the only Work company if exactly one exists. You can always type a different path.

**Files created (all with frontmatter):**

| File | Purpose |
|------|---------|
| `<ProjectName>.md` | MOC — Dataview file list + Tasks queries for urgent/standard action items and open loops |
| `Design/architecture.md` | Conceptual model, repo structure, runtime, data flows |
| `Design/design-decisions.md` | Numbered DD-01, DD-02… entries |
| `Design/security.md` | Threat model, defense layers, checklist |
| `Requirements/brd.md` | Problem statement, goals, personas, functional requirements |
| `Requirements/user-guide.md` | Setup, core workflow, daily operation, maintenance |
| `Requirements/roadmap.md` | Feature-by-feature current/future/notes |
| `Prompts/scratch.md` | Freeform scratch space seeded with today's date |

The script aborts if the project directory already exists and requires `[y/N]` confirmation before writing anything.

---

#### `new-meeting-series.sh` — Create a meeting series instance

```bash
bash .scripts/new-meeting-series.sh --vault <path>
```
```bash
bash .scripts/new-meeting-series.sh --vault <path> --company <name> --series <name> --purpose <text> --cadence <text>
```

Run this before you start prep work for any recurring meeting — not after. It resolves the active company automatically (from `.obsidian/daily-notes.json` then `DefaultCompany`) unless `--company` is specified.

**What it creates depends on whether the series exists:**

- **New series:** creates `Meetings/Series/<Series>/<Series>.md` (the series index) with Purpose, Cadence, Standing Attendees, and Format/Agenda Template sections. Prompts for purpose and cadence if not passed as flags.
- **Existing series:** appends a new instance link to the existing series index.

In both cases it creates today's instance at `Meetings/Series/<Series>/YYYY-MM-DD/<Series> YYYY-MM-DD.md` with Purpose, Attendees, Agenda, Key Points, Decisions, Action Items, and Next Meeting sections. The instance links back to the series index and to the daily note for that date.

The two-level structure means: open the series index to understand what the meeting is and see all instances; open the instance to see what happened on a specific date.

---

#### `new-1on1.sh` — Create or update a 1:1 note

```bash
bash .scripts/new-1on1.sh --vault <path>
```
```bash
bash .scripts/new-1on1.sh --vault <path> --company <name> --name <name>
```

Run this before a 1:1 — either your first with someone or any subsequent one. Resolves the active company automatically unless `--company` is specified.

**Behavior depends on whether the note already exists:**

- **New note:** creates `Meetings/1on1s/<Name> 1on1s.md` with frontmatter, a link to the person's People note (`[[<Name>]]`), and the first dated entry.
- **Existing note:** appends a new `---`-separated `## YYYY-MM-DD` entry with Agenda and Notes fields.

One file per person, appended over time. This is intentional — the full arc of a working relationship is more useful in one scrollable document than scattered across per-meeting files. See the [[#Meetings]] subsection under Work for the reasoning behind rolling notes.

---

#### `new-standalone-meeting.sh` — Create a standalone meeting note

```bash
bash .scripts/new-standalone-meeting.sh
```
```bash
bash .scripts/new-standalone-meeting.sh --vault <path> --name <name> --date <YYYY-MM-DD> [--folder]
```

Run this for any meeting that warrants its own record but is not a recurring series or 1:1. The note is created in `Meetings/Single/`.

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

---

#### `set-default-company.sh` — Change the default company

```bash
bash .scripts/set-default-company.sh
```
```bash
bash .scripts/set-default-company.sh --vault <path> --company <name>
```

Writes `DefaultCompany=<name>` to `.scripts/.vault-version`. The default company is used by `new-project.sh`, `new-meeting-series.sh`, and `new-1on1.sh` when `.obsidian/daily-notes.json` is absent or still set to the placeholder `CurrentCompany`.

`new-company.sh` sets the default automatically when it scaffolds a new company, so in the normal flow you only need this script when correcting a stale or missing value.

---

#### `set-default-vault.sh` — Change the default vault

```bash
bash src/bin/set-default-vault.sh
```
```bash
bash src/bin/set-default-vault.sh --vault <path>
```

Moves the chosen vault to the top of `config/vaults.txt` in the Meridian repo. The first entry in that file is the default shown by `select_vault` — the vault that interactive scripts pre-select when you press Enter without typing a path.

Run this when you have multiple vaults registered and want to change which one scripts default to. If `$MERIDIAN_VAULT` is set in your shell, that still takes priority over the registry order.

---

## Running a Meeting

#### Preparing for a Meeting

Choose the scenario that matches your meeting type:

1. **New recurring series (first instance)**
   Run `new-meeting-series.sh` (or **New Meeting Series** from the palette). It creates the series index at `Meetings/Series/[Series]/[Series].md` and the first instance folder and note. Prompts for series name, purpose, and cadence on first run.

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

#### Linking During a Meeting

In the instance index, link people and projects inline as you normally would in a daily note:

```markdown
## Key Points
- [[Alice Chen]] flagged capacity risk on Platform migration ^
- Decision to defer [[Project Phoenix]] kickoff to May ?
```

Action items written in the instance index with standard markers surface in the Action Items MOC automatically. The Tasks plugin scans all vault files including nested Meetings folders — no special configuration needed.

---

## The Weekly Rhythm

The system's long-term health depends on a weekly review. Without it, `>>` items accumulate, action items go stale, and the vault becomes a write-only archive.

The weekly review has five parts, in order:

#### 1. Scan the Weekly Outtake (~5 min)

The Weekly Outtake MOC shows everything you completed in the last 7 days. Open it and read through. Note patterns: were most things urgent (`!!`)? Were there items you marked done but didn't actually finish? Did anything ship that you haven't acknowledged?

The static weekly snapshot (`Process/Weekly/`) is the historical archive — one file per week, written Monday morning. The Outtake MOC is the live rolling view.

#### 2. Process the Review Queue (~5 min)

Open `Process/Review Queue.md`. Every `>>` item you marked during the week is here. For each one:

- **Promote to Knowledge** if it's a transferable insight or useful reference
- **File to Work or Life** if it belongs somewhere specific
- **Create a task** (`- [ ] !`) if it needs follow-up
- **Check it off** if it was situational and no longer relevant

The goal is to reach an empty queue by end of review.

#### 3. Sweep Action Items (~5 min)

Open `Process/Action Items.md`. Look at everything in Urgent and Standard. Anything overdue? Either do it, re-date it with a realistic deadline, or accept that it's not happening and close it. Stale action items are worse than no action items — they create noise that buries real work.

#### 4. Check Open Loops (~2 min)

Open `Process/Open Loops.md`. These are the `~` items — things waiting on someone else. Did any of them resolve? Were any forgotten? Follow up on anything that's been sitting more than a week.

#### 5. Update Current Priorities (~3 min)

Open `Work/<Company>/Goals/Current Priorities.md` and update it to reflect what actually matters this coming week. Compare it against your Northstar goals (`Northstar/Goals.md`). If you're consistently busy but your priorities don't connect to your goals, something needs to change — either the goals aren't real or you're not working on the right things.

---

## Building a Connected Graph Over Time

Meridian's value compounds with use. The most powerful feature isn't any single MOC — it's the graph of links between notes that accumulates over months and years.

Use `[[wikilinks]]` liberally:

- Link people everywhere they appear: `[[Jane Doe]]` in a meeting note, a project note, a decision note
- Link projects from daily notes, from Knowledge articles, from People notes
- Link Knowledge topics from Work notes when you apply them

After six months, opening `[[Jane Doe]]`'s note and clicking "Backlinks" shows every meeting you had with her, every project you worked on together, every decision she was part of. Opening a Knowledge article shows every daily note where you applied that concept or referenced it.

This graph isn't built intentionally — it's a byproduct of consistent linking while capturing. The habit is: whenever you mention a person, project, or topic that has (or should have) a note, link it. Don't create the note preemptively — let notes emerge from content that actually exists. But when you mention something that deserves a note, create it.

The vault that exists after a year of daily use is qualitatively different from a traditional notes app. It's not a filing cabinet — it's a record of how you think, what you've built, who you've worked with, and what you've learned.
