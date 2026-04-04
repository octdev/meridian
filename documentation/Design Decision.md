# Design Decision

## DD-01: Markers over tags and folders

**Decision:** Use inline text markers (!, !!, ~, >>, ?, &, ^, *) for content classification instead of tags or folder hierarchy.

**Rationale:** Tags require switching context to apply and are invisible in a quick scan. Folders require filing decisions at capture time, which creates friction and leads to deferral. Inline markers are typed in the flow of writing and are directly queryable by the Tasks plugin without any additional structure.

**Tradeoff:** Markers are text conventions — they have no enforcement mechanism. Typos or inconsistent usage silently break MOC queries.

---

## DD-02: Daily note as single capture surface

**Decision:** All incoming events (meetings, comms, interruptions, ad-hoc tasks) land in a single dated daily note. Intentional work goes directly into the knowledge layer.

**Rationale:** A single capture surface eliminates the "where does this go?" decision at capture time. The filing decision is deferred to review time when context is available.

**Tradeoff:** Daily notes grow large on busy days. The trade is acceptable because retrieval is via MOC queries, not manual browsing of daily notes.

---

## DD-03: Tasks plugin over Dataview for task queries

**Decision:** Task-driven MOCs use the Tasks plugin query language. Dataview is used only for the Active Projects file listing.

**Rationale:** Tasks provides native checkbox lifecycle management — completion timestamps, due dates, scheduled dates — that Dataview does not. The Tasks query language is purpose-built for filtering by completion state, date ranges, and text content. Dataview's `file.name` syntax is not valid in Tasks queries (`filename` is the correct field).

**Tradeoff:** Two query languages coexist in the vault. Operators must know which plugin owns which code fence (`tasks` vs `dataview`).

---

## DD-04: Linter over Templater for frontmatter automation

**Decision:** Frontmatter title management is handled by Linter (YAML Title rule + Insert YAML Attributes). Templater is not used.

**Rationale:** Templater's folder trigger for new note auto-application is unreliable in current versions and does not fire for notes created via Cmd+N when the vault root is the target folder. Linter fires on every save regardless of how the note was created.

**Tradeoff:** The frontmatter chain (Front Matter Timestamps → save → Linter) is timing-dependent. The 100ms delay in Front Matter Timestamps is a workaround for a race condition, not an event-driven trigger. Plugin updates may require delay adjustment.

---

## DD-05: Front Matter Timestamps over Update Time on Edit

**Decision:** `created` and `modified` frontmatter fields are managed by Front Matter Timestamps, not Update Time on Edit.

**Rationale:** Front Matter Timestamps inserts both fields on new file creation and updates `modified` on save. Update Time on Edit only updates `modified` — it does not insert `created`. Front Matter Timestamps also provides the "Execute command after update" hook that triggers the Linter save.

**Tradeoff:** Front Matter Timestamps requires `Properties in document` to be set to Source. Setting it to Visible breaks the timestamp insertion chain.

---

## DD-06: Work folder structure includes Incidents and Vendors

**Decision:** The Work/CurrentCompany/ folder includes Projects, People, Reference, Incidents, and Vendors subfolders.

**Rationale:** Incidents and Vendors have distinct retrieval patterns from general Reference material. Post-mortems, runbooks, and on-call notes are retrieved under time pressure and need their own namespace. Vendor notes (contracts, renewal dates, contacts) are retrieved by relationship, not by topic. Lumping both into Reference degrades retrieval over time.

**Tradeoff:** More folders increases the filing decision surface. Mitigated by the filing heuristics table.

---

## DD-08: Work profile flag omits personal folders at scaffold time

**Decision:** A `--profile work` flag on `scaffold-vault.sh` creates only `Process/`, `Work/`, `Knowledge/`, `_templates/`, and `.scripts/`. `Northstar/`, `Life/`, and `References/` are never written to disk on a work machine.

**Rationale:** The most reliable way to keep personal content off an employer machine is to never create it there. Relying on Syncthing exclusions alone means the folders could exist briefly or be created by other means. With `--profile work`, the personal folders are structurally absent — there is nothing to accidentally sync, expose, or misconfigure. The work and personal vault structures remain in sync for work-relevant folders while enforcing a hard boundary at the filesystem level.

**Tradeoff:** A user who runs the wrong profile has to re-scaffold or manually remove folders. Mitigated by the profile warning in the scaffold output and the explicit documentation of which profile to use on each machine type.

---

## DD-09: scripts/ directory in the project repo

**Decision:** All runnable scripts (`weekly-snapshot.py`, `new-company.sh`, `new-project.sh`) live in a `scripts/` subdirectory of the Meridian project. The scaffold script copies them from there into the vault's `.scripts/` directory.

**Rationale:** Keeping scripts at the project root mixed them with configuration files (README, scaffold-vault.sh, gitignore). As the number of scripts grew beyond one, a subdirectory makes the repo navigable and makes the scaffold copy step systematic — one directory to copy from rather than individual root-level files.

**Tradeoff:** The scaffold script must know its own location (`SCRIPT_DIR`) to resolve relative paths. This is handled with `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` at script startup.

---

## DD-10: Documentation distributed into the vault at scaffold time

**Decision:** The full documentation suite is copied into `Process/Meridian Documentation/` in the vault at scaffold time, with frontmatter injected. This includes the cheat sheet in markdown form and the PDF. The HTML source for the cheat sheet stays in the project only.

**Rationale:** Documentation that only exists in the project repo requires switching out of Obsidian to read. Putting it in the vault means it is searchable, linkable, and readable in the same context where you are working. The frontmatter injection ensures Linter and Front Matter Timestamps see the files as properly formed notes from first open.

**Tradeoff:** The vault copies diverge from the project source as the project evolves. Re-running the scaffold skips existing files, so documentation updates do not auto-propagate. Users who want the latest docs must manually copy or delete and re-scaffold. This is acceptable: the vault docs are a snapshot at setup time, not a live mirror.

---

## DD-11: Process/Drafts/ as default new note location

**Decision:** Obsidian's "Default location for new notes" is set to `In the folder specified below` with the path `Process/Drafts/`, rather than "Same folder as current file."

**Rationale:** "Same folder as current file" places new notes wherever Obsidian's focus happens to be — almost always `Process/Daily/` during normal use, since that is where the primary capture surface lives. This contaminates the Daily folder with standalone notes and requires immediate manual relocation. `Process/Drafts/` is a neutral creation point: notes land there predictably regardless of context, and are filed to their intended destination immediately after creation. The folder is not an inbox for uncertain items — it is a workaround for Obsidian's default behavior.

**Tradeoff:** New notes require one extra filing step even when the destination is already known. The cost is low: the draft state is seconds long in normal use, and the alternative (notes scattered across wrong folders) is worse.

---

## DD-12: Meetings as a first-class peer folder under Work

**Decision:** `Work/CurrentCompany/Meetings/` is a direct peer to `Projects/`, `People/`, `Reference/`, `Incidents/`, and `Vendors/`.

**Rationale:** Reference is for stable company knowledge — processes, systems, decisions. Meeting artifacts are time-indexed operational records. The retrieval patterns are different: Reference is browsed by topic; Meetings is browsed by series and date. Projects implies active forward-moving scoped work with deliverables. A recurring meeting is not a project — it is an operational cadence. Mixing recurring meeting artifacts into either folder pollutes both.

**Tradeoff:** Adds one more folder to the `Work/CurrentCompany/` structure. Mitigated by the filing heuristics table, which gives a clear rule for when to use Meetings vs. Projects vs. Reference.

---

## DD-13: Series-folder / date-folder nesting over flat date-named folders

**Decision:** `Meetings/[Series]/[Date]/` nesting rather than `Meetings/Series+Date/` flat folders.

**Rationale:** At executive meeting volume, flat Meetings produces hundreds of folders with no grouping. Obsidian's file browser becomes a long undifferentiated list. The series relationship exists only in the naming convention, not in the structure. The series folder groups all instances, the series index note makes the relationship explicit and navigable, and date folders isolate artifacts per instance.

**Tradeoff:** Two levels of nesting mean the instance file is three folders deep from vault root. Accepted because the Shell Commands palette entry (`new-meeting-series.sh`) handles creation, so manual filesystem navigation is uncommon.

---

## DD-14: Series index note in addition to instance index notes

**Decision:** Each meeting series has a `[Series].md` index note at the series folder level, separate from the per-date instance notes.

**Rationale:** The series index answers: *what is this meeting for, who attends, how does it run?* Without it, that context has to be re-established from instance notes or from memory. For a monthly all-hands with a consistent agenda format, the series index is the stable reference that instance notes inherit context from. It also serves as the navigable list of all instances — a lightweight MOC for the series.

**Tradeoff:** Two notes to maintain instead of one. In practice the series index changes rarely; most activity is in instance notes.

---

## DD-15: Rolling 1:1 notes over per-instance folders

**Decision:** A single rolling file at `Meetings/1on1s/[Name] 1on1s.md`, appended per meeting, rather than per-instance folders.

**Rationale:** At 10 direct reports meeting biweekly, per-instance folders generate 240+ folders per year. The retrieval question for a 1:1 is almost never "what happened on April 1st" — it is "what is the arc of my work with this person." A rolling note answers that question in one scroll. A folder-per-instance forces reconstruction from many files. A per-person subfolder (rolling note inside `Meetings/1on1s/[Name]/`) adds filesystem depth with no benefit when there is only one file — a folder is only justified when artifacts exist, and those belong in `Work/CurrentCompany/People/` anyway.

**Tradeoff:** Large rolling files can become slow in Obsidian on mobile. Acceptable: 1:1 notes are typically short entries, and the mobile use case for 1:1 review is low-frequency.

---

## DD-16: No new frontmatter fields for meeting notes

**Decision:** Meeting instance notes and 1:1 rolling notes use the standard three-field frontmatter (`title`, `created`, `modified`). No `meeting-series:` or `meeting-date:` fields are added.

**Rationale:** The H1 (`# Series YYYY-MM-DD`) already encodes both series and date. Adding frontmatter fields that duplicate the title creates a maintenance surface — they can drift. Meridian's principle is minimal frontmatter; structural metadata lives in the note content and in the folder path.

**Tradeoff:** Series and date are not queryable via Dataview on frontmatter fields. Accepted: the primary retrieval paths are the series index (instance list), the daily note backlink, and full-text search — not Dataview queries on meeting metadata.

---

## DD-17: Project meetings do not belong in Meetings

**Decision:** Notes for meetings that are primarily about a project are filed under `Work/CurrentCompany/Projects/[Project]/`, not under `Meetings/`.

**Rationale:** The project folder is the right retrieval context for project-related meeting notes. Filing by meeting would orphan the note from the project. The heuristic: *would I look for this note when thinking about the project, or when thinking about the meeting series?* For project meetings, almost always the former.

**Tradeoff:** The boundary requires a judgment call at filing time. Mitigated by the filing heuristics table and the meeting taxonomy decision table.

---

## DD-07: Syncthing for work/personal boundary enforcement

**Decision:** Syncthing with folder-level Send Only / Receive Only modes enforces the personal/work content boundary between machines.

**Rationale:** Personal content (Life/, Northstar/, References/) must never appear on an employer-managed work machine. Syncthing's per-folder sync modes enforce this at the filesystem level without relying on manual discipline. Knowledge/ is Send Only from the work laptop so personal knowledge notes stay off the work machine.

**Tradeoff:** Syncthing must be installed on the work laptop. If the work machine is MDM-locked against software installation, this approach is not available.
