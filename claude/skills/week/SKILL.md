---
name: week
description: Plan the owner's week, or turn a brain dump into calendar blocks with briefs. Use on weekly planning ("планируем неделю"), a dump of plans, errands or ideas to put somewhere, or starting a calendar block ("запусти блок").
---

# Week

The owner dumps; you file. After a planning pass nothing lives in their head: every item has one home, and each block can be started cold.

Homes:

- **Compass** (`~/open-source/batcave/config/compass.md`): goals, the week's outcomes, "not now", what agents pick up alone. The *why*.
- **Personal Google calendar** (primary, writable): anything with a time or a day. The work calendar (Tetrika) and holidays are read-only context.
- **Day map** (Batcave's page at `/day/`; contract in `~/open-source/batcave/docs/daymap-api.md`): the week's processes as lines (an epic, a bot going to QA, a release), each with its steps and goal; things without a line go outside the lines. The calendar stays the source of truth for time: every timed step is a calendar block linked to it by `event_id`.
- **Batcave backlog** (`GET/POST http://127.0.0.1:8740/api/backlog`, body `{title, minutes, due, where, notes}`): errands with no fixed time; Batcave's planner slots them. Lists and reminders belong to Alfred in Batcave.
- **Dropped**: said out loud, so it stops nagging.

## Planning a week or a dump

1. Read the compass, the week's events in all three calendars, the rhythm in `~/open-source/batcave/config/profile.md` (its keep-free blocks, like the gym, never go on the calendar and are never planned over), and the open backlog.
2. Take the dump as given; dictation slips are normal, read for intent. Sort each item into a home. Collect everything you cannot place (missing day, unclear outcome, conflicting priority) into one batch of questions with ready options, and ask once.
3. Draft the week: blocks tied to the events they serve (prep before the meeting it is for), sized realistically, in the owner's own time only where the compass says that time goes. Agent blocks start early enough that the result is ready when the owner next has hands free: research launched at 11:00 is waiting after the gym.
4. Show the draft as one compact day-by-day overview and get the owner's ok. Then write it.
5. Fill the day map from the approved draft (below).
6. Update the compass: the week's outcomes, any new goal or "not now".

## The day map

Read it with `curl -s 'http://127.0.0.1:8740/api/daymap/week?start=YYYY-MM-DD'` (and `/api/daymap/day?date=…&links=1`). Write with `curl -s -H 'X-Batcave: 1' -H 'Content-Type: application/json' -X POST http://127.0.0.1:8740/api/daymap/<route> -d '<json>'`:

- `lines` `{name, goal, goal_at: "YYYY-MM-DD HH:MM"}`: one per process with a goal this week; at most three get a colour, a fourth waits under "More lines". Finish one with `{id, state: "done"}`.
- `steps` `{line_id, title, kind, day, start: "HH:MM", end: "HH:MM", brief, done_when, checklist: [...], agent: {from, to, label}, event_id}`: each block of the draft that moves a line forward. `kind` is `launch` for an agent block (its `agent` run is the hours the agent works alone, labelled "agent, about 2 h"), `deep` for deep work, `meeting` for a meeting step, `goal` for the line's goal (an instant step, no `end`). Without `line_id` it is outside the lines, with `group` `today`, `no_epic` or `bug`.
- An edit sends `id` and only what changes; `steps/<id>/move` `{day, start, end}` re-plans a slipped step (the old one stays as "moved").

Step titles are short and in the owner's language; the brief and the checklist come from the block's calendar description.

Done when every dumped item has a home or was dropped aloud, the calendar matches the approved draft, and the compass reflects the week.

## A block's brief

The event description is written for the moment the block starts, read by someone with no memory of this chat:

- the outcome and why it matters (the compass goal it serves);
- what done looks like;
- everything needed to start: links, tickets, paths, people, the first step.

Title: `<project>: <action>`. An **agent block** is titled `🤖 <project>: <action>` and its description is a self-contained task prompt naming the project directory, what the agent decides alone and what it brings back to the owner. Reminder: a popup at the start. An all-day event (a trip, a vacation) takes midnight UTC (`2026-10-10T00:00:00Z`, end exclusive): the Google Calendar connector reads a local midnight like `+04:00` as the previous day. A block that only structures the owner's own time is marked free (transparent), so it never reads as busy to anyone; a real appointment stays busy.

## Starting a block

Find the event that is on now (or the one named), read its description, and do it as the task. An agent block runs in its project directory; when it needs the owner, ask with ready options and keep working on everything else.
