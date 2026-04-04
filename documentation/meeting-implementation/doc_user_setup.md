# user-setup.md — addition

Add to the Shell Commands plugin configuration section, alongside the existing new-company and new-project entries.

---

## Shell Commands — New Meeting Series

Add a third palette command mirroring the existing two:

| Field | Value |
|---|---|
| Command name | New Meeting Series |
| Shell command | `bash "{{vault_path}}/.scripts/new-meeting-series.sh" --vault "{{vault_path}}"` |
| Working directory | `{{vault_path}}` |
| Execute in | Background (same as other commands) |

After adding: open the command palette (`Cmd+P`) and confirm **New Meeting Series** appears. Run it once against your vault to verify the series and instance folders are created correctly before relying on it in a live meeting prep flow.
