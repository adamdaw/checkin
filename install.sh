#!/usr/bin/env bash
#
# install.sh — wire up the checkin tool.
#   ./install.sh         symlink bin + systemd units, enable the timer
#   ./install.sh copy    copy instead of symlink
#
set -euo pipefail

mode="${1:-link}"
repo="$(cd "$(dirname "$0")" && pwd)"

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

[ -f "$cfgdir/config.env" ] || cp "$repo/config.env.example" "$cfgdir/config.env"

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
