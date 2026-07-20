#!/usr/bin/env bash
# Withdraw a pane's pending Claude Code attention notification when that pane
# gains focus in tmux — so navigating to the pane dismisses the notice, not only
# clicking the notification itself. Wired to the pane-focus-in hook in
# tmux.conf.local, which passes the focused pane's #{pane_id} as $1.
#
# Hands the pane id to Hammerspoon's claude-clear handler (see
# ~/.hammerspoon/init.lua), URL-encoded with jq's @uri exactly as notify.sh
# encodes it, so the decoded key matches the one notify.sh registered. If there
# is no pending notice for the pane, Hammerspoon no-ops. Best-effort and
# side-effect-free: a missing jq or Hammerspoon just means nothing happens, and
# it always exits 0 so a focus change is never disrupted.

pane="${1:-}"
[ -n "$pane" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

enc() { jq -rn --arg s "$1" '$s|@uri'; }

# -g: fire the handler without stealing focus. Failure (Hammerspoon not
# installed, nothing handling the URL) is ignored — there's nothing to clear.
open -g "hammerspoon://claude-clear?pane=$(enc "$pane")" 2>/dev/null

exit 0
