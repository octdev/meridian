# Design Decisions

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

## DD-07: Syncthing for work/personal boundary enforcement

**Decision:** Syncthing with folder-level Send Only / Receive Only modes enforces the personal/work content boundary between machines.

**Rationale:** Personal content (Life/, Northstar/, References/) must never appear on an employer-managed work machine. Syncthing's per-folder sync modes enforce this at the filesystem level without relying on manual discipline. Knowledge/ is Send Only from the work laptop so personal knowledge notes stay off the work machine.

**Tradeoff:** Syncthing must be installed on the work laptop. If the work machine is MDM-locked against software installation, this approach is not available.
