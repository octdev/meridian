# Meridian — Agent Working Guide

Meridian is a personal knowledge management system built on Obsidian. It consists of a scaffold script that creates a vault folder structure and seeds files, a set of utility scripts for ongoing vault management, and a documentation suite distributed into the vault at setup time. The deliverable for users is a configured Obsidian vault, not an app.

---

## Read First for Each Task Type

| Task | Read first | Skip |
|------|-----------|------|
| Modify `scaffold-vault.sh` | `scaffold-vault.sh`, `Architecture.md` (vault structure) | `Sync.md`, `Security.md` |
| Add or change a script in `scripts/` | The script itself, `User Setup.md` (Shell Commands section) | `Sync.md`, `Security.md` |
| Update documentation | The specific doc file, `Architecture.md` (repo structure) | `Sync.md`, `Security.md` |
| Add a vault MOC or seed file | `scaffold-vault.sh`, `Architecture.md` (vault structure) | Everything else |
| Understand the plugin stack or frontmatter chain | `Architecture.md` | `Sync.md`, `Security.md` |
| Understand sync or machine boundary | `Sync.md`, `Security.md` | Everything else |
| Understand why something is designed a certain way | `Design Decision.md` | Everything else |

`docs/work-scaffold.md` is a project planning note. It is almost never needed for code changes.

---

## Non-Obvious Constraints

**Two `scripts` directories — do not confuse them:**
- `scripts/` — source scripts in the project repo
- `.scripts/` — scripts as deployed inside the vault
- `scaffold-vault.sh` copies from `scripts/` → `.scripts/` at setup time using `copy_if_new`

**Vault documentation:**
- `src/documentation/` in the project is the source of truth
- `Process/Meridian Documentation/` in the vault is a copy, injected with frontmatter via `copy_doc_with_frontmatter`
- Fresh scaffold skips existing doc files (`copy_if_new` semantics)
- Upgrade runs always overwrite vault docs with the latest from the repo (`_refresh_vault_docs` in `upgrade-runner.sh`)

**`_templates/` must be excluded in Linter and Filename Heading Sync:**
- Without this exclusion, both plugins corrupt template files on save
- This is not optional — templates break silently if excluded is missing

**The frontmatter chain is timing-dependent, not event-driven:**
- Front Matter Timestamps fires after 100ms → triggers save → Linter populates `title` → Filename Heading Sync syncs filename
- The 100ms delay is a workaround for a race condition
- If `title` stops populating after plugin changes, increase delay in 50ms increments

**Tasks ≠ Dataview query syntax:**
- Tasks plugin: `sort by filename reverse`
- Dataview: `sort by file.name ASC`
- These are not interchangeable; mixing them causes silent query failures

**`new-company.sh` and `new-project.sh` are interactive:**
- Both use `read -rp` for prompts — they require a terminal
- Shell Commands palette entries work only if the plugin is configured for terminal mode
- Otherwise they must be run from a system terminal

**Work profile omits exactly three folders:**
- `Northstar/`, `Life/`, and `References/` are never created under `--profile work`
- Everything else — including `Process/Meridian Documentation/` — is identical between profiles

---

## Conventions

**scaffold-vault.sh helpers:**
- `write_if_new <path> <content>` — writes a text file; skips if it already exists (idempotent)
- `copy_if_new <src> <dest>` — copies a file (binary-safe); skips if dest exists; warns if src missing
- `copy_doc_with_frontmatter <src> <dest> <title> <date>` — prepends `title/created/modified` frontmatter, then copies; skips if dest exists
- `SCRIPT_DIR` is set at startup via `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` — use it for all relative path resolution

**Documentation files have no frontmatter in the project:**
- Frontmatter is injected only when copying to the vault
- Do not add frontmatter to files in `src/documentation/` — it would be doubled on copy

**Design decisions:**
- Numbered DD-01, DD-02... sequentially; never renumber
- If a decision changes, add a new entry that supersedes — do not edit the old one

**Vault structure is the source of truth in `Architecture.md`:**
- Both the project repo layout and the generated vault layout are documented there
- Keep both diagrams current when adding files or folders
