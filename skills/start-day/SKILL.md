---
name: start-day
description: Start your day. Arms the hourly habit check-in, surfaces anything carried over from last night's end-of-day note, asks for today's intention, and writes a short start-of-day note to your daily-log folder. Trigger when the user signals the start of their day — "start my day", "good morning", "I'm up", "begin the day". If the user also runs a separate work-day start routine, this is the overall-day one; ask if it's ambiguous which they mean.
---

# Start of Day

Begins the day: turns on the hourly habit check-in, surfaces last night's
carry-over, captures today's intention. Keep it light — one conversational
exchange, not a form.

The daily-log folder is the path the `checkin` tool writes to (see
`~/.config/checkin/config.env`, `NOTES_DIR`; default `~/notes`).
Below, `<notes>` means that path and `<today>` / `<yesterday>` mean dates
in `YYYY-MM-DD`.

## Steps

### 1. Arm the habit check-in

Run: `checkin arm`

This marks today active (hourly check-in popups begin, 06:00–23:00) and
seeds today's habit log. If the command isn't found, tell the user the
`checkin` tool isn't installed and continue with the rest.

### 2. Surface last night's carry-over

Look for `<notes>/10-Daily/<yesterday>/<yesterday>-end.md`. If found, read
its **For tomorrow** section and note those items. If not found, there's
nothing carried over — don't invent anything.

### 3. Ask about today

One conversational message, referencing carry-over if any:
> "Carrying over: X. What's your intention for today?"

If nothing carried over, just ask for today's intention. Keep it to a
single line of focus — a compass, not a task list.

### 4. Write the start-of-day note

Ensure `<notes>/10-Daily/<today>/` exists, then write
`<notes>/10-Daily/<today>/<today>-start.md`:

```markdown
---
type: day-start
date: <YYYY-MM-DD>
---
# <YYYY-MM-DD> — Start of Day

## Carried over
<items from last night's end note, or "None">

## Intention
<the user's one-line focus for today>

## Notes
<anything else mentioned — omit the section if empty>
```

Confirm the file path after writing. Don't commit unless asked.
