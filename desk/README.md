# Decision desk

The page where the owner picks options for questions agents prepare (merl's grooming and
proposals). One decision on screen at a time, the queue on the left, keys `A`–`D` to pick, `R`
for the recommendation, `L` to park, `N` for a note, `J` / `K` to move.

- `server.py`: Python stdlib, on `127.0.0.1:8741`; `run.sh` also publishes it to the tailnet at
  `/desk/` of the Mac's tailnet address, beside Batcave, so the phone opens it too.
- Data lives outside the repo, in `~/.local/share/desk/` (`$DESK_DATA`):
  - `cards/<id>.json`: written by agents; the fields are in merl's
    `.claude/skills/groom/desk.md`. `"status": "archived"` hides a card. A card the page cannot
    read shows up as a red line under the queue instead of breaking the page.
    `"project"` puts the card in a project's queue (`merl` when left out); with more than one
    project on the desk, a switch at the top of the queue (or `P`) shows one project at a time.
    Prefix the ids of other projects (`pc44`), since an id is a file name. A card needs no
    pictures: without `img` or `video` an option is text only.
  - `answers/<id>.json`: written by the page: `pick`, `status` (`answered` or `later`), `note`, `at`.
  - `media/`: stills and MP4s; a card refers to one as `media/<file>`.
- The page polls `api/state` every 2 s, so a card an agent writes appears without a reload; a note
  being typed is never replaced.
