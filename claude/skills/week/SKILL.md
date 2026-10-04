---
name: week
description: Plan the owner's week, or turn a brain dump into calendar blocks with briefs. Use on weekly planning ("планируем неделю"), a dump of plans, errands or ideas to put somewhere, or starting a calendar block ("запусти блок").
---

# Week

The owner dumps; you file. After a planning pass nothing lives in their head: every item has one home, and each block can be started cold.

Homes:

- **Compass** (`~/open-source/batcave/config/compass.md`): goals, the week's outcomes, "not now", what agents pick up alone. The *why*.
- **Personal Google calendar** (primary, writable): anything with a time or a day. The work calendar (Tetrika) and holidays are read-only context.
- **Batcave backlog** (`GET/POST http://127.0.0.1:8740/api/backlog`, body `{title, minutes, due, where, notes}`): errands with no fixed time; Batcave's planner slots them. Lists and reminders belong to Alfred in Batcave.
- **Dropped**: said out loud, so it stops nagging.

## Planning a week or a dump

1. Read the compass, the week's events in all three calendars, the rhythm in `~/open-source/batcave/config/profile.md` (its keep-free blocks, like the gym, never go on the calendar and are never planned over), and the open backlog.
2. Take the dump as given; dictation slips are normal, read for intent. Sort each item into a home. Collect everything you cannot place (missing day, unclear outcome, conflicting priority) into one batch of questions with ready options, and ask once.
3. Draft the week: blocks tied to the events they serve (prep before the meeting it is for), sized realistically, in the owner's own time only where the compass says that time goes. Agent blocks start early enough that the result is ready when the owner next has hands free: research launched at 11:00 is waiting after the gym.
4. Show the draft as one compact day-by-day overview and get the owner's ok. Then write it.
5. Update the compass: the week's outcomes, any new goal or "not now".

Done when every dumped item has a home or was dropped aloud, the calendar matches the approved draft, and the compass reflects the week.

## A block's brief

The event description is written for the moment the block starts, read by someone with no memory of this chat:

- the outcome and why it matters (the compass goal it serves);
- what done looks like;
- everything needed to start: links, tickets, paths, people, the first step.

Title: `<project>: <action>`. An **agent block** is titled `🤖 <project>: <action>` and its description is a self-contained task prompt naming the project directory, what the agent decides alone and what it brings back to the owner. Reminder: a popup at the start. A block that only structures the owner's own time is marked free (transparent), so it never reads as busy to anyone; a real appointment stays busy.

## Starting a block

Find the event that is on now (or the one named), read its description, and do it as the task. An agent block runs in its project directory; when it needs the owner, ask with ready options and keep working on everything else.
