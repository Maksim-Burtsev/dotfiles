# vdirsyncer: Yandex 360 <-> Google Calendar

Two-way sync of the work calendar (Yandex 360, CalDAV) into a dedicated Google
calendar, every 5 minutes via launchd. Google is then the single source for
the Claude Google Calendar connector and Wispr Flow Notetaker.

Why not Google's "add calendar from URL": it is read-only, refreshes every
12-24 h, and shows Yandex events (all `CLASS:PRIVATE`) as "busy" with no titles.

## Secrets (Keychain, never in the repo)

```bash
security add-generic-password -a yandex -s yandex-caldav  -w '<yandex app password, type Calendar>' -U
security add-generic-password -a google -s google-calsync -w '<google oauth client secret>' -U
```

Google OAuth client: Google Cloud console -> APIs & Services -> Credentials ->
OAuth client ID, type Desktop app, with the Google Calendar API enabled and
the account added as a test user. `client_id` lives in `config`.

## First run

```bash
vdirsyncer discover work   # opens the browser for Google OAuth once
vdirsyncer sync
launchctl load ~/Library/LaunchAgents/dev.mburtsev.vdirsyncer.plist
```

Log: `~/.local/share/vdirsyncer/sync.log`.
