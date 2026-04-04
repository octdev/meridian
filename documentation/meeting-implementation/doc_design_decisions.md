# design-decisions.md — additions

---

## Meetings layer

### Why a dedicated Meetings folder rather than using Projects or Reference

Rejected: filing all meeting artifacts under `Work/CurrentCompany/Reference/`.
Reason: Reference is for stable company knowledge — processes, systems, decisions. Meeting artifacts are time-indexed operational records. The retrieval patterns are different. Reference is browsed by topic; Meetings is browsed by series and date.

Rejected: filing recurring meeting artifacts under `Work/CurrentCompany/Projects/`.
Reason: Projects implies active forward-moving scoped work with deliverables. A recurring meeting is not a project — it is an operational cadence. Mixing them pollutes the Projects folder and the Active Projects MOC.

Adopted: `Work/CurrentCompany/Meetings/` as a first-class peer to Projects, People, Reference, Incidents, Vendors.

---

### Why series-folder / date-folder nesting rather than flat date-named folders

Rejected: `Meetings/Org Associates 2026-04-01/` (flat, series+date in folder name).
Reason: At executive meeting volume, flat Meetings produces hundreds of folders with no grouping. Obsidian's file browser becomes a long undifferentiated list. The series relationship exists only in the naming convention, not in the structure.

Adopted: `Meetings/[Series]/[Date]/` — the series folder groups all instances, the series index note makes the relationship explicit and navigable, and date folders isolate artifacts per instance.

---

### Why a series index note in addition to the instance index notes

The series index answers: *what is this meeting for, who attends, how does it run?* Without it, that context has to be re-established from instance notes or from memory. For a monthly all-hands with 100+ attendees and a consistent agenda format, the series index is the stable reference that instance notes inherit context from.

The series index also serves as the navigable list of all instances — a lightweight MOC for the series.

---

### Why rolling 1:1 notes rather than per-instance folders

Rejected: `Meetings/1on1s/[Name]/[Date]/[Name] [Date].md` per-instance folders.
Reason: At 10 direct reports meeting biweekly, this generates 240+ folders per year. The retrieval question for a 1:1 is almost never "what happened on April 1st" — it is "what is the arc of my work with this person." A rolling note answers that question in one scroll. A folder-per-instance forces reconstruction from many files.

Rejected: `Meetings/1on1s/[Name]/[Name] 1on1.md` (rolling note inside a per-person subfolder).
Reason: The subfolder adds filesystem depth with no benefit when there is only one file. A folder is only justified when artifacts exist — and those belong in `Work/CurrentCompany/People/` anyway.

Adopted: flat rolling note at `Meetings/1on1s/[Name] 1on1s.md`. Promote to a People subfolder only if formal artifacts (PIPs, promotion packets) are generated — and those artifacts go in `People/`, not in `Meetings/`.

---

### Why no new frontmatter fields for meeting notes

Considered: adding `meeting-series:` and `meeting-date:` to meeting instance frontmatter.
Rejected: the H1 (`# Series YYYY-MM-DD`) already encodes both. Adding frontmatter fields that duplicate the title creates a maintenance surface — they can drift. Meridian's principle is minimal frontmatter; structural metadata lives in the note content and in the folder path.

---

### Project meetings do not belong in Meetings

If a meeting is primarily about a project — a design review, a sprint retro, a stakeholder update — the notes belong in `Work/CurrentCompany/Projects/[Project]/`, not in `Meetings/`. The project folder is the right retrieval context. Filing by meeting would orphan the note from the project.

The heuristic: *would I look for this note when thinking about the project, or when thinking about the meeting series?* Almost always the former for project meetings.

---

### Action items in instance index notes flow to MOCs automatically

The Tasks plugin scans all vault files, including files nested inside `Meetings/`. Action items written with standard markers in an instance index note (`- [ ] !`, `- [ ] !!`) surface in the Action Items MOC without any additional configuration. No special setup is required.
