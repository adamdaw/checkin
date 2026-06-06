---
name: end-day
description: End your day. Disarms the hourly habit check-in, summarizes the day's habit log, asks for a one-line reflection and anything for tomorrow, and writes a short end-of-day note to your daily-log folder. Trigger when the user signals the day is over — "end my day", "good night", "calling it a day", "I'm done", "wrap up the day". If the user also runs a separate work-day end routine, this is the overall-day one; ask if it's ambiguous which they mean.
---

# End of Day

Closes the day: stops the hourly check-in, reflects on the habit log,
captures anything for tomorrow. Keep it light.

The daily-log folder is the path the `checkin` tool writes to (see
`~/.config/checkin/config.env`, `NOTES_DIR`; default `~/notes`).
`<notes>` and `<today>` below follow that path and `YYYY-MM-DD`.

## Steps

### 1. Disarm the habit check-in

Run `checkin disarm` (stops popups for the night), then `checkin summary`
to retrieve today's habit log. If `checkin` isn't found, note it and
continue.

### 2. Reflect on the day's habit log

Read the summary. Mention briefly what the day looked like from the log —
especially any free pockets (gaps, breaks, quiet stretches) that could
anchor a new routine. Don't over-read a single day; note patterns as they
accumulate across days.

### 3. Ask for reflection + tomorrow

One conversational message:
> "How did today go in a line — and anything to carry into tomorrow?"

### 4. Write the end-of-day note

Write `<notes>/10-Daily/<today>/<today>-end.md`:

```markdown
---
type: day-end
date: <YYYY-MM-DD>
---
# <YYYY-MM-DD> — End of Day

## Reflection
<the user's one-line reflection>

## For tomorrow
<items to carry over, or "None">

## Habit log
<one line on where the log lives and any pattern observed>
```

Confirm the file path after writing. Don't commit unless asked.
