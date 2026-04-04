# user-handbook.md — new section: Meetings

Add after the existing "Work: Structured and Ephemeral" section.

---

## Meetings: Operational Records at Executive Scale

At executive scale, meetings are not incidental to work — they are a primary work surface. Decisions get made in them. Commitments get recorded in them. Artifacts get produced for them. The Meetings layer exists to make those records findable and connected, without forcing a filing decision in the middle of every calendar day.

### The core distinction: which meetings get files

Not every meeting needs a note outside the daily note. The decision:

**Daily note only** — the meeting produced tasks, observations, or bullets that belong to the day's capture flow and don't need independent retrieval. A status check, a quick decision, an interrupt. The timestamped `###` heading in the daily note is enough. Tasks surface in MOCs automatically.

**Project folder** — the meeting was primarily about a project. Notes go in `Work/CurrentCompany/Projects/[Project]/`. You would look for this note when thinking about the project, not when thinking about the meeting series. Filing it under Meetings would orphan it from its context.

**Meetings folder** — the meeting is a recurring operational cadence (all-hands, staff meeting, council, board review) that generates artifacts, decisions, and action items that need to be found *as a series* over time. This is what the Meetings layer is for.

**1:1 rolling note** — one-on-ones with direct reports or tracked peers where you maintain an ongoing record of the working relationship. Not a per-meeting file — a single rolling document per person, appended over time.

If you're unsure: does the output need to be found independently of a specific date, and does it belong to a recurring series rather than a project? If yes, use Meetings.

### Series index and instance index

Every recurring meeting in the Meetings layer has two levels of note.

The **series index** lives at `Meetings/[Series]/[Series].md`. It is the permanent record of what the meeting is: its purpose, cadence, standing attendees, and typical agenda format. You create it once (via `new-meeting-series.sh`) and update it when the meeting's structure changes. It also serves as the navigable list of all instances — an entry point to the full history of the series.

The **instance index** lives at `Meetings/[Series]/[Date]/[Series] [Date].md`. It is the canonical record of one specific meeting. All prep materials, the deck, the PDF, and any other artifacts for that meeting are co-located in the same date folder and linked from the instance index. The instance index links up to the series index and back to the daily note on meeting day.

This two-level structure means: to understand what the meeting is, open the series index. To find what happened on a specific date, open the instance index. To find all instances, the series index lists them.

### Preparing for a meeting

Run `new-meeting-series.sh` (or invoke **New Meeting Series** from the command palette) before you start prep work — not after. The script creates the series folder, series index (if new), date folder, and instance index in one step.

Once the instance index exists:
1. Create prep notes directly in the date folder — they are co-located with the instance index and linked from it.
2. Add the deck and PDF to the same folder when they exist.
3. Reference the meeting from your daily note on the prep day and the meeting day: `Working on [[Org Associates 2026-04-01]]`.

The instance index is your working document during prep and your archival record after. Fill in Purpose and Attendees before the meeting. Add Key Points, Decisions, and Action Items during or immediately after.

### Linking during a meeting

In the instance index, link people and projects inline as you normally would in a daily note:

```markdown
## Key Points
- [[Alice Chen]] flagged capacity risk on Platform migration ^
- Decision to defer [[Project Phoenix]] kickoff to May ?
```

Action items written in the instance index with standard markers surface in the Action Items MOC automatically. The Tasks plugin scans all vault files including nested Meetings folders — no special configuration needed.

### Rolling 1:1 notes

For direct reports and peers where you maintain an ongoing record, use a rolling note at `Meetings/1on1s/[Name] 1on1s.md`. Each meeting appends a new `## YYYY-MM-DD` section with Agenda and Notes. The file grows over time — this is intentional. The full arc of a working relationship is more useful than a collection of isolated per-meeting snapshots.

The rolling note links to the People note (`[[Name]]`). The People note links back (`[[Name 1on1s]]`). They serve different purposes:

- **People note** — who this person is: communication style, context, background, working preferences
- **1:1 rolling note** — your working history together: what you've discussed, committed to, observed, and decided

When a colleague leaves the company (or you do), move their People note from `Work/CurrentCompany/People/` to `Life/People/`. The 1:1 rolling note stays in place as a historical record — or moves with the People note if you expect the relationship to continue.

### What does not belong in Meetings

- **Project meeting notes** — file under the project
- **People profiles** — file under `Work/CurrentCompany/People/`
- **Formal HR artifacts** (PIPs, promotion packets, review documents) — file under `Work/CurrentCompany/People/`
- **Vendor and contract discussions** — file under `Work/CurrentCompany/Vendors/`
- **Incident retros** — file under `Work/CurrentCompany/Incidents/`

The Meetings layer is for operational cadences. Everything else has a more specific home.
