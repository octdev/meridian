#!/usr/bin/env python3
"""
weekly-snapshot.py — Generates a static weekly completed-task report.

Scans Process/Daily/ for the previous Monday-Sunday period, extracts all
completed tasks (- [x]) that carry a marker (! !! ~ >>), groups them by
day and category, and writes a Markdown file to Process/Weekly/.

Output filename: YYYY-MM-DD–DD Weekly Outtake.md

Designed to run via Obsidian Shell Commands plugin:
  - Event: Obsidian starts
  - Event: Every n seconds (14400)
  - Command: python3 {{vault_path}}/.scripts/weekly-snapshot.py {{vault_path}}

Safe to re-run: exits immediately if the output file already exists.

Usage:
    python3 weekly-snapshot.py <vault>              # previous Mon-Sun
    python3 weekly-snapshot.py <vault> --date DATE  # week containing DATE (YYYY-MM-DD)
    python3 weekly-snapshot.py <vault> --force      # overwrite existing
    python3 weekly-snapshot.py <vault> --dry-run    # preview without writing
"""

import argparse
import re
import sys
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

CHECKED_TASK = re.compile(r"^\s*- \[x\]\s+(.+)$", re.IGNORECASE)

CATEGORIES = [
    ("Action Items \u2014 Urgent",    lambda t: "!!" in t),
    ("Action Items \u2014 Standard",  lambda t: "!" in t and "!!" not in t),
    ("Open Loops Closed",             lambda t: "~" in t),
    ("Review Items Processed",        lambda t: ">>" in t),
]

DONE_DATE = re.compile(r"\u2705\s*(\d{4}-\d{2}-\d{2})")


def get_week_bounds(ref):
    mon = ref - timedelta(days=ref.weekday())
    mon = mon.replace(hour=0, minute=0, second=0, microsecond=0)
    sun = mon + timedelta(days=6, hours=23, minutes=59, seconds=59)
    return mon, sun


def get_previous_week_bounds(today):
    this_mon = today - timedelta(days=today.weekday())
    return get_week_bounds(this_mon - timedelta(days=7))


def build_output_path(weekly_dir, mon, sun):
    if mon.month == sun.month:
        fname = f"{mon.strftime('%Y-%m')}-{mon.strftime('%d')}\u2013{sun.strftime('%d')} Weekly Outtake.md"
    else:
        fname = f"{mon.strftime('%Y-%m-%d')}\u2013{sun.strftime('%m-%d')} Weekly Outtake.md"
    return weekly_dir / fname, fname.replace(".md", "")


def extract_tasks(daily_dir, mon, sun):
    by_day = defaultdict(list)
    seen = set()

    def add(date_str, cat, raw):
        txt = re.sub(r"\s*\u2705\s*\d{4}-\d{2}-\d{2}", "", raw)
        txt = re.sub(r"\s*[\u2795\U0001f4c5\u23f3\U0001f6eb]\s*\d{4}-\d{2}-\d{2}", "", txt)
        txt = re.sub(r"\s*\U0001f501\s*.+$", "", txt).strip()
        k = (date_str, cat, txt)
        if k not in seen:
            seen.add(k)
            by_day[date_str].append((cat, txt))

    cur = mon
    while cur <= sun:
        ds = cur.strftime("%Y-%m-%d")
        f = daily_dir / f"{ds}.md"
        if f.exists():
            for line in f.read_text(encoding="utf-8").splitlines():
                m = CHECKED_TASK.match(line)
                if not m:
                    continue
                txt = m.group(1).strip()
                dm = DONE_DATE.search(txt)
                attr = ds
                if dm:
                    ddt = datetime.strptime(dm.group(1), "%Y-%m-%d")
                    if not (mon <= ddt <= sun):
                        cur += timedelta(days=1)
                        continue
                    attr = dm.group(1)
                for cname, ctest in CATEGORIES:
                    if ctest(txt):
                        add(attr, cname, txt)
                        break
        cur += timedelta(days=1)

    for f in sorted(daily_dir.glob("*.md")):
        try:
            fd = datetime.strptime(f.stem, "%Y-%m-%d")
            if mon <= fd <= sun:
                continue
        except ValueError:
            pass
        for line in f.read_text(encoding="utf-8").splitlines():
            m = CHECKED_TASK.match(line)
            if not m:
                continue
            txt = m.group(1).strip()
            dm = DONE_DATE.search(txt)
            if not dm:
                continue
            ddt = datetime.strptime(dm.group(1), "%Y-%m-%d")
            if not (mon <= ddt <= sun):
                continue
            for cname, ctest in CATEGORIES:
                if ctest(txt):
                    add(dm.group(1), cname, txt)
                    break

    return dict(by_day)


def generate_markdown(by_day, mon, sun, title):
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    total = sum(len(v) for v in by_day.values())
    lines = [
        "---",
        f"title: {title}",
        f"created: {now}",
        f"modified: {now}",
        f"week-start: {mon.strftime('%Y-%m-%d')}",
        f"week-end: {sun.strftime('%Y-%m-%d')}",
        "---", "",
        f"# {title}", "",
        f"**{total} tasks completed** \u2014 {mon.strftime('%Y-%m-%d')} through {sun.strftime('%Y-%m-%d')}",
        "",
    ]
    day_names = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    cur, idx = mon, 0
    while cur <= sun:
        ds = cur.strftime("%Y-%m-%d")
        lines.append(f"## {day_names[idx]} \u2014 {ds}")
        lines.append("")
        day = by_day.get(ds, [])
        if not day:
            lines += ["*No completed tasks.*", ""]
        else:
            by_cat = defaultdict(list)
            for cat, txt in day:
                by_cat[cat].append(txt)
            for cname, _ in CATEGORIES:
                if cname in by_cat:
                    lines.append(f"**{cname}**")
                    lines += [f"- {t}" for t in by_cat[cname]]
                    lines.append("")
        cur += timedelta(days=1)
        idx += 1
    return "\n".join(lines) + "\n"


def find_daily_dirs(vault: Path) -> list:
    """Discover all Daily/ directories across domain folders."""
    candidates = [
        vault / "Life" / "Daily",
        vault / "Process" / "Daily",        # legacy support
    ]
    work_dir = vault / "Work"
    if work_dir.exists():
        for child in sorted(work_dir.iterdir()):
            if child.is_dir():
                d = child / "Daily"
                if d.exists():
                    candidates.append(d)
    return [d for d in candidates if d.exists()]


def main():
    p = argparse.ArgumentParser(description="Generate a static weekly completed-task snapshot.")
    p.add_argument("vault", type=Path)
    p.add_argument("--date",    default=None)
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--force",   action="store_true")
    args = p.parse_args()

    vault      = args.vault.expanduser().resolve()
    weekly_dir = vault / "Process" / "Weekly"

    daily_dirs = find_daily_dirs(vault)
    if not daily_dirs:
        sys.exit(0)

    if args.date:
        mon, sun = get_week_bounds(datetime.strptime(args.date, "%Y-%m-%d"))
    else:
        mon, sun = get_previous_week_bounds(datetime.now())

    out, title = build_output_path(weekly_dir, mon, sun)

    if out.exists() and not args.force:
        sys.exit(0)

    by_day: dict = {}
    for dd in daily_dirs:
        partial = extract_tasks(dd, mon, sun)
        for day, tasks in partial.items():
            by_day.setdefault(day, []).extend(tasks)
    content = generate_markdown(by_day, mon, sun, title)

    if args.dry_run:
        total = sum(len(v) for v in by_day.values())
        print(f"DRY RUN: {mon.strftime('%Y-%m-%d')} to {sun.strftime('%Y-%m-%d')}")
        print(f"Output:  {out}")
        print(f"Tasks:   {total}")
        print()
        print(content)
        return

    weekly_dir.mkdir(parents=True, exist_ok=True)
    out.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
