#!/bin/sh
# Close a tmux pane, letting Claude Code quit itself first.
#
# Usage: pane-close.sh <pane_id>
#
# Bound to prefix + x (Ghostty cmd+w). For an ordinary pane this is plain
# kill-pane. When Claude Code occupies the pane, killing it outright yanks the
# process away mid-flight — no interrupt of an in-progress turn, no SessionEnd
# hooks, no transcript flush. So we press its own quit chord instead: Ctrl-C
# twice (the first interrupts / clears, the second exits), wait for the process
# to actually go away, and only then kill the pane.
#
# The wait is capped: if claude is wedged, or the first Ctrl-C was swallowed
# interrupting a tool call and the second only cleared the composer, the pane
# still closes — just a beat later. Killing the pane is the promise; the graceful
# exit is best-effort.
#
# Run from the binding with `run-shell -b` so the sleeps never block the tmux
# server.

pane="${1:-}"
[ -n "$pane" ] || exit 0

tty=$(tmux display-message -p -t "$pane" '#{pane_tty}' 2>/dev/null)

# Is Claude Code the foreground job in the pane? Its process *title* is the bare
# version number (which is why #{pane_current_command} reads e.g. "2.1.222" for
# a claude pane and can't be matched on), but comm stays "claude". So look at the
# pane's tty and keep only processes in the foreground process group — the "+"
# in stat — otherwise a claude subprocess left running in the background, or the
# MCP servers it spawned, would count.
is_claude() {
	[ -n "$tty" ] || return 1
	ps -t "${tty#/dev/}" -o stat=,comm= 2>/dev/null |
		awk '$1 ~ /\+/ && $2 ~ /(^|\/)claude$/ { found = 1 } END { exit !found }'
}

if is_claude; then
	tmux send-keys -t "$pane" C-c 2>/dev/null
	sleep 0.2
	tmux send-keys -t "$pane" C-c 2>/dev/null

	# Give claude up to ~2s to tear down (interrupt, SessionEnd hooks, transcript
	# flush) before the pane goes.
	i=0
	while [ "$i" -lt 20 ] && is_claude; do
		sleep 0.1
		i=$((i + 1))
	done
fi

tmux kill-pane -t "$pane" 2>/dev/null
