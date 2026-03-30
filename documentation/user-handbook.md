# User Handbook

This document explains how to think about and use Meridian day-to-day. For installation and plugin configuration, see [user-setup.md](user-setup.md).

## Table of Contents

1. [[#The Mental Model]]
2. [[#The Northstar]]
3. [[#The Three Domains]]
4. [[#The Daily Note as Capture Surface]]
5. [[#Work: Structured and Ephemeral]]
6. [[#Life: Everything Else That Matters]]
7. [[#Knowledge: What Transcends Context]]
8. [[#People Notes: When to Move Them]]
9. [[#Capture Mindset: Fast In, Filed Later]]
10. [[#The Weekly Rhythm]]
11. [[#Building a Connected Graph Over Time]]

---

## The Mental Model

Meridian is built on one observation: most productivity systems fail because they demand a filing decision at the moment of capture. You're in a meeting, someone says something important, and the system asks: *where does this go?* The friction causes deferral, and deferred items become lost items.

Meridian separates capture from filing. The daily note is a frictionless inbox — everything that happens to you lands there. Filing happens during review, when you have context and calm. The system stays useful because the MOCs surface what matters without requiring you to browse the inbox manually.

This only works if you actually capture everything. Half-capture breaks the loop. The sections below explain how to build that habit and where things eventually land.

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

### Setting It Up

These files ship empty with placeholder prompts. Fill them in before you start using the rest of the vault. A few sentences per file is enough to start — the point is to make the implicit explicit, not to write a manifesto.

Work outward from the most stable to the most concrete:

1. **Purpose** first. This changes rarely if ever. It is the underlying reason behind your work and your life — not your job title, not your current role. Something like "to build things that make other people's work easier" or "to be someone my family can rely on."

2. **Values** next. These are what you actually optimize for when you make trade-offs. If you claim to value family time but consistently override it for work, one of those is a real value and one is an aspiration. Be honest here — the notes are private.

3. **Vision** and **Mission** together. Vision is the destination; Mission is the current leg of the journey. Vision might be "leading a product organization at a company I believe in." Mission right now might be "becoming a principal engineer in the next two years."

4. **Principles** are your operating rules — the things you'd tell a past version of yourself. Short, direct statements work better than paragraphs.

5. **Goals** last, because they should flow from the above. If a goal doesn't connect to purpose or mission, it's a task masquerading as a goal. The template provides 12-month and 3-year buckets. Use both.

6. **Career** is an ongoing reference. Keep it current as your trajectory evolves.

### Using the Northstar Daily

You don't open these files every morning. They anchor two things you do touch every day:

- **Top 3 Goals** in the daily note. These should connect to your 12-month goals or current mission. If you consistently fill in goals that have nothing to do with your Northstar, either the daily goals are noise or the Northstar is out of date.
- **Current Priorities MOC** in `Process/`. This is a manually maintained note where you write what you're focused on this week or month. Keep it honest — it should reflect your actual priorities, not your aspirational ones.

Review the Northstar once a quarter. Update Mission and Goals if things have shifted. Purpose and Values rarely change.

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
```

A note belongs in Work if it is specific to your current employer. If you leave this company, does the note still matter? If no, it belongs in Work. If yes, it belongs in Knowledge.

**When you leave a company:** Run `new-company.sh` to scaffold the new one. The old company's folder stays in place — it's a record, not a live system. Move any notes from `Work/People/` for colleagues you'll stay in touch with over to `Life/People/`. Backlinks update automatically.

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

## Knowledge: What Transcends Context

Knowledge is the most important folder in the vault, and the most commonly underused one.

Knowledge is not where you dump reference material. It is where you put things you've actually learned — insights, mental models, technical understanding, leadership observations — that you want to carry with you across jobs, across roles, across years.

The four subfolders are:

```
Technical/    Engineering, architecture, tooling, systems design
Leadership/   Management, org dynamics, communication, team health
Industry/     Market knowledge, domain expertise, trends
General/      Everything else worth knowing
```

### The Test

Before filing a note, ask: *would I want this if I started at a new company tomorrow?*

- Notes about your current company's architecture → `Work/Reference/`
- Notes about architectural patterns you've developed opinions on → `Knowledge/Technical/`
- Notes about how your current manager gives feedback → `Work/People/`
- Notes about what you've learned about giving good feedback → `Knowledge/Leadership/`
- Notes about your current product's market position → `Work/Reference/`
- Notes about how to think about market positioning → `Knowledge/Industry/`

The distinction is *specific context* (Work) versus *transferable understanding* (Knowledge). When in doubt, leave the note in the daily note with a `>>` marker and decide at weekly review.

### Promoting Insights

The `&` marker is the mechanism for Knowledge promotion. When you have a realization mid-day — in a meeting, during a problem-solving session, in a conversation — mark it with `&`:

```
& The velocity drop happens consistently when PR review time exceeds 3 days
& Users don't want more features — they want fewer failure modes
```

These are searchable in the daily notes. During the weekly review, scan for `&` items and decide which ones are worth promoting to a standing Knowledge note. Not every insight needs its own note — sometimes a few bullets under a broader topic note is enough.

---

## People Notes: When to Move Them

People notes deserve special attention because they span both Work and Life, and they outlast the context in which you first created them.

Start a person note the moment you have a meaningful interaction that you'll want to remember. A colleague's communication style, the context they gave you in a 1:1, a commitment they made, a pattern you've noticed — these are ephemeral in memory and durable in notes.

**Where they live:**

- Active colleagues at your current company → `Work/People/`
- Everyone else — personal contacts, former colleagues you're still in touch with, professional connections outside current employment → `Life/People/`

**When to move them:**

When a colleague leaves the company (or when you leave), move their note from `Work/People/` to `Life/People/`. The relationship outlasts the professional context. Obsidian updates backlinks automatically.

The move preserves the history: your notes about working with someone at one company become the foundation of understanding them as a person, not just as a colleague.

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

If you're sitting down to write a project design document, don't start in the daily note — start directly in `Work/[Company]/Projects/[Project]/`. If a conversation triggers an important technical insight you want to capture as a standing note, write it directly in `Knowledge/Technical/`. The daily note is for reactive capture; intentional creation goes to its destination immediately.

---

## The Weekly Rhythm

The system's long-term health depends on a weekly review. Without it, `>>` items accumulate, action items go stale, and the vault becomes a write-only archive.

The weekly review has five parts, in order:

### 1. Scan the Weekly Outtake (~5 min)

The Weekly Outtake MOC shows everything you completed in the last 7 days. Open it and read through. Note patterns: were most things urgent (`!!`)? Were there items you marked done but didn't actually finish? Did anything ship that you haven't acknowledged?

The static weekly snapshot (`Process/Weekly/`) is the historical archive — one file per week, written Monday morning. The Outtake MOC is the live rolling view.

### 2. Process the Review Queue (~5 min)

Open `Process/Review Queue.md`. Every `>>` item you marked during the week is here. For each one:

- **Promote to Knowledge** if it's a transferable insight or useful reference
- **File to Work or Life** if it belongs somewhere specific
- **Create a task** (`- [ ] !`) if it needs follow-up
- **Check it off** if it was situational and no longer relevant

The goal is to reach an empty queue by end of review.

### 3. Sweep Action Items (~5 min)

Open `Process/Action Items.md`. Look at everything in Urgent and Standard. Anything overdue? Either do it, re-date it with a realistic deadline, or accept that it's not happening and close it. Stale action items are worse than no action items — they create noise that buries real work.

### 4. Check Open Loops (~2 min)

Open `Process/Open Loops.md`. These are the `~` items — things waiting on someone else. Did any of them resolve? Were any forgotten? Follow up on anything that's been sitting more than a week.

### 5. Update Current Priorities (~3 min)

Open `Process/Current Priorities.md` and update it to reflect what actually matters this coming week. Compare it to your Northstar goals. If you're consistently busy but your priorities don't connect to your goals, something needs to change — either the goals aren't real or you're not working on the right things.

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
