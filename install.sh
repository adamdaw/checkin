#!/usr/bin/env bash
#
# install.sh — wire up the checkin tool.
#   ./install.sh         symlink bin + systemd units, enable the timer
#   ./install.sh copy    copy instead of symlink
#
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"

# Piped in via `curl … | bash`: the repo files aren't here. Clone it, then
# re-run install.sh from the clone.
if [ ! -f "$repo/bin/checkin" ]; then
    command -v git >/dev/null || { echo "git is required to install." >&2; exit 1; }
    dest="${CHECKIN_SRC:-$HOME/.local/share/checkin}"
    if [ -d "$dest/.git" ]; then git -C "$dest" pull --ff-only --quiet
    else git clone --quiet --depth 1 https://github.com/adamdaw/checkin "$dest"; fi
    exec bash "$dest/install.sh" "$@"
fi

mode="${1:-link}"
bindir="$HOME/bin"
unitdir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
cfgdir="${XDG_CONFIG_HOME:-$HOME/.config}/checkin"
skilldir="$HOME/.claude/skills"
mkdir -p "$bindir" "$unitdir" "$cfgdir" "$skilldir"

place() { # src dest — handles files and directories
    rm -rf "$2"
    if [ "$mode" = copy ]; then cp -r "$1" "$2"; else ln -s "$1" "$2"; fi
}

place "$repo/bin/checkin"             "$bindir/checkin"
place "$repo/systemd/checkin.service" "$unitdir/checkin.service"
place "$repo/systemd/checkin.timer"   "$unitdir/checkin.timer"
place "$repo/skills/start-day"        "$skilldir/start-day"
place "$repo/skills/end-day"          "$skilldir/end-day"
chmod +x "$repo/bin/checkin"

if [ ! -f "$cfgdir/config.env" ]; then
    notes_dir="$HOME/notes"
    # Ask where their notes live. Open /dev/tty directly so the prompt works
    # even under `curl | bash` (stdin is the piped script). If the terminal
    # can't be opened — no controlling tty — skip the prompt and use the default.
    if { exec 3<>/dev/tty; } 2>/dev/null; then
        printf 'Where do your daily notes live? [%s]: ' "$notes_dir" >&3
        read -r reply <&3 || reply=""
        exec 3>&-
        [ -n "$reply" ] && notes_dir="${reply/#\~/$HOME}"
    fi
    sed "s|^NOTES_DIR=.*|NOTES_DIR=\"$notes_dir\"|" \
        "$repo/config.env.example" > "$cfgdir/config.env"
    echo "Notes folder set to: $notes_dir"
fi

case "$(uname -s)" in
    Darwin)
        agentdir="$HOME/Library/LaunchAgents"; mkdir -p "$agentdir"
        plist="$agentdir/com.checkin.poll.plist"
        sed "s|__CHECKIN_BIN__|$bindir/checkin|g" \
            "$repo/launchd/com.checkin.poll.plist.template" > "$plist"
        launchctl unload "$plist" 2>/dev/null || true
        launchctl load "$plist"
        echo "Installed. Loaded launchd agent: $plist (fires hourly)."
        ;;
    *)
        if command -v systemctl >/dev/null 2>&1; then
            systemctl --user daemon-reload
            systemctl --user enable --now checkin.timer
            echo "Installed. Timer status:"
            systemctl --user --no-pager status checkin.timer | head -4 || true
        else
            echo "Installed bin + skills + config."
            echo "No systemd found: schedule 'checkin poll' hourly via cron."
        fi
        ;;
esac
echo
echo "Next: run '/start-day' (or 'checkin arm') to begin a day of check-ins."
