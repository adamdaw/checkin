# checkin

A small tool for building and improving daily habits and self-awareness.

While your day is *active*, a systemd user timer pops a one-line check-in
each hour — "what happened this past hour?", plus a stand-up / hydrate
nudge — and appends your answer to a dated markdown log in your daily-log
folder (an Obsidian vault, a plain notes directory — any folder works).
Over time that log becomes an honest record of how your days actually go:
useful for noticing patterns, finding the free pockets in a day, and
anchoring new routines to moments that already exist.

It's deliberately small and legible — a dumb hourly heartbeat plus a plain
markdown log you own. It also serves as the heartbeat for a wider
daily-rhythm loop via the bundled `start-day` / `end-day` skills.

> **Dependency:** the hourly prompt is a [`zenity`](https://help.gnome.org/users/zenity/)
> dialog, so `zenity` must be installed (see [Requirements](#requirements)).
> Everything else is bash, coreutils, and a systemd user instance.

## How it works

- **The timer is a dumb heartbeat.** `checkin.timer` fires on the hour
  between 06:00 and 23:00. That window is only a safety rail.
- **You set the real boundaries.** `start-day` (or `checkin arm`) marks
  the day active; `end-day` (or `checkin disarm`) ends it. When the day
  isn't armed, `checkin poll` exits silently — no popup.
- **One dialog at a time.** A lockfile means being away from the keyboard
  can't stack a queue of popups.
- **Output** is `VAULT/10-Daily/<today>/habit-log.md`, a markdown table
  (`| Time | Past hour |`), one row per check-in. Dismissed/empty
  check-ins log `(no response)` so gaps stay visible.

## Commands

| Command | Purpose |
|---|---|
| `checkin arm` | mark today active; seed today's habit log |
| `checkin disarm` | end today; check-ins stop |
| `checkin status` | armed? how many entries so far |
| `checkin log TEXT` | append a row (used by `poll`; directly testable) |
| `checkin summary` | print today's habit-log table |
| `checkin poll` | armed? → pop the dialog and log the answer (timer entry) |

## Install

```bash
./install.sh          # symlink bin, systemd units, and skills; enable timer
./install.sh copy     # copy instead of symlink
```

This symlinks `bin/checkin` into `~/bin` and the bundled Claude Code
skills (`skills/start-day`, `skills/end-day`) into `~/.claude/skills`,
then sets up the hourly scheduler for your platform — a **systemd user
timer** on Linux, a **launchd agent** on macOS (auto-detected via
`uname`).

Config (optional) lives at `~/.config/checkin/config.env` — `NOTES_DIR`
(the base daily-log folder), `DAILY_SUBDIR`, and `LOG_FILENAME` (the per-day
log file; its `type:` and heading derive from the name). Defaults: `~/notes`,
`10-Daily`, and `habit-log.md`. (`VAULT` is still accepted in place of
`NOTES_DIR` for older configs.)

### macOS (launchd)

`install.sh` renders `launchd/com.checkin.poll.plist.template` to
`~/Library/LaunchAgents/com.checkin.poll.plist` (substituting the real
`checkin` path) and `launchctl load`s it. It fires `checkin poll` at the
top of every hour. Unlike the Linux timer it isn't hour-bounded, so the
armed-gate does the work — run `end-day` to stop evening popups (or edit
the plist to a per-hour `StartCalendarInterval` array). To remove it:
`launchctl unload ~/Library/LaunchAgents/com.checkin.poll.plist`.

On macOS the popup is GTK's native quartz window — **no XQuartz needed.**
launchd runs a job with a minimal `PATH` and an empty locale, so `checkin`
adds Homebrew to `PATH` (to find `zenity`) and sets a UTF-8 locale (so the
prompt renders) when it runs on macOS. If the popup never appears, confirm
`zenity` is installed: `brew install zenity`.

## Bundled skills

The `skills/` directory holds two [Claude Code](https://docs.claude.com/en/docs/claude-code)
skills that drive the day's boundaries conversationally:

- **`start-day`** — arms check-ins, surfaces last night's carry-over, asks
  your intention, writes a start-of-day note.
- **`end-day`** — disarms, summarizes the day's habit log, asks for a
  reflection and anything for tomorrow, writes an end-of-day note.

They're plain markdown instructions; adapt them freely to your vault.

## Requirements

- **`zenity`** — renders the hourly check-in dialog. Without it the popup
  can't appear, so this is required for normal use. Install it:
  - Debian/Ubuntu/Pop!_OS: `sudo apt install zenity`
  - Fedora: `sudo dnf install zenity`
  - Arch: `sudo pacman -S zenity`
  - macOS: `brew install zenity`
- **`bash` + coreutils** — the script itself.
- **A scheduler** — the bundled timer is a **systemd user unit** (Linux;
  standard on most desktops — check with `systemctl --user status`).

The `checkin` script and the skills are cross-platform; `install.sh` sets
up the right scheduler per OS (systemd on Linux, launchd on macOS — see
[macOS](#macos-launchd)). The non-GUI subcommands (`arm`, `disarm`,
`log`, `status`, `summary`) work without `zenity`; only the interactive
`poll` needs it.

## Test

```bash
bash test/test-checkin.sh
```

Covers arm/disarm/log/status/summary and the armed-gate. The zenity popup
itself is not exercised; `poll` reduces to `log` for the testable core.

## Design notes

- **State-gated, not clock-gated.** The day's boundaries are explicit
  actions, so the tool never nags outside a real day and the same timer
  can sit idle for weeks between uses without harm.
- **GUI from a background scheduler.** On Linux `poll` falls back to
  `DISPLAY=:0` and the session bus at `/run/user/<uid>/bus` if the systemd
  unit environment didn't carry them through. On macOS it instead adds
  Homebrew to `PATH` and a UTF-8 locale — launchd provides neither — and
  lets zenity find the GUI session natively; setting `DISPLAY` there would
  wrongly force an X11 backend.
- **Table-safe input.** Pipe characters are rewritten and newlines
  collapsed so a stray `|` can't corrupt the markdown table.

## License

MIT. See [LICENSE](LICENSE).
