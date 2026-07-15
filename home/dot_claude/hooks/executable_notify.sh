#!/usr/bin/env bash
# Claude Code Notification hook → Hammerspoon.
#
# Hands the attention event to Hammerspoon via its URL scheme. Hammerspoon (see
# ~/.hammerspoon/init.lua) shows a native notification whose subtitle is the tmux
# session name, and whose click callback switches tmux to the pane that fired and
# raises Ghostty — all native arm64, no deprecated dependencies.
#
# The tmux session/pane and the message are passed as URL query params, URL-encoded
# with jq's @uri. If jq is missing, or Hammerspoon isn't installed (so nothing
# handles the URL), we fall back to a plain osascript notification with no click
# action. A notification hiccup must never disrupt the session — always exits 0.

message=""
if command -v jq >/dev/null 2>&1; then
  message=$(cat 2>/dev/null | jq -r '.message // empty' 2>/dev/null)
fi
[ -n "$message" ] || message="needs your attention"

pane="${TMUX_PANE:-}"
session=""
[ -n "$pane" ] && session=$(tmux display-message -p -t "$pane" '#S' 2>/dev/null)
[ -n "$session" ] || session="tmux"

plain() { osascript -e "display notification \"$message\" with title \"Claude Code\"" 2>/dev/null; }

# No jq → can't safely URL-encode; degrade to a plain native notice.
if ! command -v jq >/dev/null 2>&1; then
  plain
  exit 0
fi

enc() { jq -rn --arg s "$1" '$s|@uri'; }
url="hammerspoon://claude-notify?session=$(enc "$session")&pane=$(enc "$pane")&message=$(enc "$message")"

# -g: fire the handler without stealing focus. If no app handles hammerspoon://
# (Hammerspoon not installed), open fails → fall back to a plain notification.
open -g "$url" 2>/dev/null || plain

exit 0
