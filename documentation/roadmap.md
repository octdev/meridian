# Roadmap

## NAS sync hub (v2)

**Current:** Syncthing syncs directly between work laptop and personal machine. Personal machine must be on for the full chain to stay current.

**Future:** TrueNAS NAS acts as the always-on Syncthing hub. Work laptop syncs to NAS immediately. Personal machine and phone sync from NAS via Nextcloud. Personal machine power state does not affect sync latency.

**Notes:** Requires NAS rebuild to complete. TrueNAS SCALE supports Syncthing via TrueCharts community app catalog. Nextcloud replaces iCloud for personal-to-phone sync. Migration is additive — add NAS as a new Syncthing peer, reconfigure folder targets, decommission direct laptop-to-laptop sync.

---

## Syncthing config verification script

**Current:** Syncthing folder sync modes (Send Only, Receive Only, Send & Receive) are configured manually and verified by inspection.

**Future:** A `verify-sync.sh` script queries the Syncthing REST API and confirms that each folder is configured with the correct mode per the sync matrix in [sync.md](sync.md). Outputs pass/fail per folder with remediation hints.

**Notes:** Syncthing exposes a REST API at http://127.0.0.1:8384/rest. Requires the Syncthing API key from the config file.

---

## Automated config verification on vault open

**Current:** Plugin settings, appearance settings, and hotkeys are configured manually and verified by a checklist in the user guide.

**Future:** A Shell Commands entry on vault open runs a lightweight check script that verifies critical settings are in place (Properties in document = Source, Linter rules enabled, Front Matter Timestamps delay, excluded folders). Outputs a notification if anything is misconfigured.

**Notes:** Obsidian does not expose plugin settings via a public API. This would require reading `.obsidian/plugins/` config JSON files directly and comparing against expected values.

---

## Mobile capture improvements

**Current:** Phone syncs via iCloud. Obsidian on iOS provides full vault access including daily notes and MOCs.

**Future:** Investigate a lightweight mobile capture shortcut (iOS Shortcut or Drafts integration) that appends a timestamped bullet to today's daily note without opening Obsidian. Reduces friction for quick captures during commutes or away from desk.

**Notes:** Requires Obsidian's iCloud vault path to be stable and accessible from Shortcuts. The append-to-file approach avoids sync conflicts with desktop edits.
