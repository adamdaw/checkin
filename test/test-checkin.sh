#!/usr/bin/env bash
#
# test-checkin.sh — covers the non-GUI logic (arm/disarm/log/status/summary
# and the armed-gate). The zenity popup itself isn't exercised here; the
# `poll` path is reduced to its testable core via `log`.
#
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
checkin="$here/../bin/checkin"

# Isolate all state and output under a throwaway dir.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export XDG_STATE_HOME="$tmp/state"
export NOTES_DIR="$tmp/notes"
export DAILY_SUBDIR="10-Daily"
export CHECKIN_CONFIG="/nonexistent-on-purpose"

today="$(date +%F)"
logf="$NOTES_DIR/10-Daily/$today/habit-log.md"

pass=0 fail=0
check() { # description  expected  actual
    if [ "$2" = "$3" ]; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
    else fail=$((fail+1)); printf '  FAIL %s\n       expected: %s\n       actual:   %s\n' "$1" "$2" "$3"; fi
}
contains() { # description  needle  file
    if grep -qF "$2" "$3" 2>/dev/null; then pass=$((pass+1)); printf '  ok   %s\n' "$1"
    else fail=$((fail+1)); printf '  FAIL %s (missing: %s)\n' "$1" "$2"; fi
}

echo "checkin tests"

# Fresh state: not armed.
check "status before arm" "not armed" "$(bash "$checkin" status)"

# Disarmed poll is a silent no-op and writes nothing.
bash "$checkin" poll
check "poll while disarmed writes no log" "absent" "$([ -f "$logf" ] && echo present || echo absent)"

# Arm: seeds the log and reports armed.
bash "$checkin" arm >/dev/null
check "armed after arm" "armed for $today — 0 entries logged" "$(bash "$checkin" status)"
contains "log seeded with header" "| Time | Past hour |" "$logf"
contains "log frontmatter has date" "date: $today" "$logf"

# Log a normal entry.
bash "$checkin" log "wrote code, drank water" >/dev/null
contains "normal entry appended" "wrote code, drank water" "$logf"
check "entry count = 1" "armed for $today — 1 entries logged" "$(bash "$checkin" status)"

# Pipe characters must be sanitised so the table can't break.
bash "$checkin" log "a | b | c" >/dev/null
contains "pipes sanitised to slashes" "a / b / c" "$logf"

# Empty entry becomes the no-response marker.
bash "$checkin" log "" >/dev/null
contains "empty entry -> (no response)" "(no response)" "$logf"

# Summary prints the table.
contains "summary shows header" "Habit log — $today" <(bash "$checkin" summary)

# Disarm: stops the day, poll goes quiet again.
bash "$checkin" disarm >/dev/null
check "status after disarm" "not armed" "$(bash "$checkin" status)"

echo
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
